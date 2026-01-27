#if os(iOS)

import Foundation
import AVFoundation
import Vision
import Observation
import QuartzCore   // CACurrentMediaTime
import CoreGraphics // CGPoint

/// Runs the front camera and uses Vision to detect faces.
/// No preview layer is created.
///
/// Output: normalized face center in Vision coordinates (0...1, 0...1) with origin at bottom-left.
@Observable
final class FaceTracker: NSObject {

    // MARK: - Public output

    /// Callback hook (NOT observed). Called on the main actor with normalized face center (0...1, 0...1).
    @ObservationIgnored
    var onFaceCenter: (@MainActor @Sendable (CGPoint) -> Void)?

    /// Latest normalized face center (observed). Updated on the main actor.
    var faceCenter: CGPoint?

    // MARK: - Smoothing

    /// Exponential smoothing factor in 0...1. Higher = snappier, lower = smoother.
    /// Accessed only on `queue`.
    private var smoothingAlpha: CGFloat = 0.25

    /// Smoothed center state. Accessed only on `queue`.
    private var smoothedCenter: CGPoint?

    // MARK: - Private capture state

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "FaceTracker.VideoQueue")
    private let sequenceHandler = VNSequenceRequestHandler()

    private var isConfigured = false

    /// Accessed only on `queue`.
    private var lastProcessTime: CFTimeInterval = 0

    /// Minimum seconds between Vision runs. Accessed only on `queue`.
    private var minInterval: CFTimeInterval = 0.01 // ~12.5fps

    // MARK: - Lifecycle

    /// Starts the camera + face detection. Safe to call multiple times.
    @MainActor
    func start() {
        if session.isRunning { return }

        Task {
            let granted = await Self.requestCameraAccessIfNeeded()
            guard granted else {
                print("FaceTracker: camera permission not granted")
                return
            }

            do {
                try configureIfNeeded()
                session.startRunning()
            } catch {
                print("FaceTracker: failed to start - \(error)")
            }
        }
    }

    /// Stops camera capture.
    @MainActor
    func stop() {
        if session.isRunning { session.stopRunning() }
        // Reset smoothing state so next start doesn't jump from an old value.
        queue.async { [weak self] in
            self?.smoothedCenter = nil
            self?.lastProcessTime = 0
        }
    }

    /// Optional: change processing rate (seconds between Vision calls).
    /// This is applied on the capture queue.
    @MainActor
    func setProcessingInterval(seconds: Double) {
        let s = max(0.0, seconds)
        queue.async { [weak self] in
            self?.minInterval = s
        }
    }

    /// Optional: change smoothing strength.
    /// - Parameter alpha: 0...1. 0 = frozen, 1 = no smoothing (raw).
    /// This is applied on the capture queue.
    @MainActor
    func setSmoothingAlpha(_ alpha: Double) {
        let a = max(0.0, min(1.0, alpha))
        queue.async { [weak self] in
            self?.smoothingAlpha = CGFloat(a)
        }
    }

    // MARK: - Setup

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }
        isConfigured = true

        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            session.commitConfiguration()
            throw NSError(domain: "FaceTracker", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No front camera available"])
        }

        let input = try AVCaptureDeviceInput(device: camera)
        if session.canAddInput(input) { session.addInput(input) }

        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }

        // Portrait + mirrored so movement feels natural.
        if let conn = output.connection(with: .video) {
            conn.videoOrientation = .portrait
            conn.isVideoMirrored = true
        }

        session.commitConfiguration()
    }

    private static func requestCameraAccessIfNeeded() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    cont.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }
}

// MARK: - AVCapture delegate

extension FaceTracker: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        // Throttle Vision work (runs on `queue`).
        let now = CACurrentMediaTime()
        if now - lastProcessTime < minInterval { return }
        lastProcessTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest { [weak self] request, _ in
            guard let self else { return }
            guard let faces = request.results as? [VNFaceObservation], !faces.isEmpty else { return }

            // Largest face = "one face" selection.
            let best = faces.max(by: {
                ($0.boundingBox.width * $0.boundingBox.height) <
                ($1.boundingBox.width * $1.boundingBox.height)
            })

            guard let bb = best?.boundingBox else { return }
            let center = CGPoint(x: bb.midX, y: bb.midY)

            // Smooth on the capture queue.
            let alpha = self.smoothingAlpha
            let outCenter: CGPoint
            if let prev = self.smoothedCenter {
                outCenter = CGPoint(
                    x: prev.x + (center.x - prev.x) * alpha,
                    y: prev.y + (center.y - prev.y) * alpha
                )
            } else {
                outCenter = center
            }
            self.smoothedCenter = outCenter

            // Deliver/update on main.
            Task { @MainActor in
                self.faceCenter = outCenter
                self.onFaceCenter?(outCenter)
            }
        }

        do {
            // .up is OK for the normalized rectangles in this setup.
            try sequenceHandler.perform([request], on: pixelBuffer, orientation: .up)
        } catch {
            // ignore transient Vision errors
        }
    }
}

#endif
