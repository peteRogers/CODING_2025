import SwiftUI
import Observation
import AVFoundation
import Vision
import QuartzCore   // CACurrentMediaTime

// MARK: - Demo SwiftUI view: live camera preview + face box overlay

struct FaceCameraOverlayView: View {

    let model: FaceCameraOverlayModel
    var showPreview: Bool = true

    var body: some View {
        ZStack {
            if showPreview {
                CameraPreview(session: model.session)
                    .ignoresSafeArea()
            } else {
                // No preview: show a neutral background so overlays are still visible.
                Color.black.ignoresSafeArea()
            }

            GeometryReader { geo in
                if let bb = model.faceBoundingBox {
                    // Vision boundingBox is normalized (0...1) with origin at bottom-left.
                    // Convert to SwiftUI (top-left) coordinates.
                    let w = bb.width * geo.size.width
                    let h = bb.height * geo.size.height
                    let x = bb.minX * geo.size.width
                    let yTopLeft = (1.0 - bb.maxY) * geo.size.height

                    RoundedRectangle(cornerRadius: 10)
                        .stroke(lineWidth: 3)
                        .frame(width: w, height: h)
                        .position(x: x + w * 0.5, y: yTopLeft + h * 0.5)
                        .animation(.smooth(duration: 0.08), value: bb)
                }

                // Landmark points (already in full-image normalized coords 0...1).
                // Convert to SwiftUI coords (top-left origin).
                if !model.landmarkPoints.isEmpty {
                    Canvas { context, size in
                        for p in model.landmarkPoints {
                            let pt = CGPoint(
                                x: p.x * size.width,
                                y: (1.0 - p.y) * size.height
                            )
                            let r: CGFloat = 2.0
                            let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
                            context.fill(Path(ellipseIn: rect), with: .color(.white))
                        }
                    }
                    .allowsHitTesting(false)
                }
            }

            VStack {
                HStack {
                    Circle()
                        .fill(model.isRunning ? .green : .red)
                        .frame(width: 10, height: 10)
                    Text(model.statusText)
                        .font(.footnote)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding()

                Spacer()
            }
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

// MARK: - Model: session + Vision face detection

@MainActor
@Observable
final class FaceCameraOverlayModel: NSObject {
   
    // Public (observed)
    var faceBoundingBox: CGRect? = nil
    var isRunning: Bool = false
    var statusText: String = "Starting…"

    /// All landmark points in full-image normalized coordinates (0...1, origin bottom-left).
    /// This keeps the view mapping simple.
    var landmarkPoints: [CGPoint] = []

    // Public (not observed)
    @ObservationIgnored
    let session = AVCaptureSession()

    // Private (not observed)
    @ObservationIgnored
    private let output = AVCaptureVideoDataOutput()

    @ObservationIgnored
    private let queue = DispatchQueue(label: "FaceCameraOverlay.VideoQueue")

    @ObservationIgnored
    private let sequenceHandler = VNSequenceRequestHandler()

    @ObservationIgnored
    private var isConfigured = false

    @ObservationIgnored
    private var lastProcessTime: CFTimeInterval = 0

    @ObservationIgnored
    private var minInterval: CFTimeInterval = 0.01 // ~12.5 fps (landmarks are heavier)

    func start() {
        Task {
            let granted = await Self.requestCameraAccessIfNeeded()
            guard granted else {
                statusText = "Camera permission not granted"
                isRunning = false
                return
            }

            do {
                try configureIfNeeded()
                session.startRunning()
                isRunning = true
                statusText = "Running"
            } catch {
                statusText = "Failed: \(error.localizedDescription)"
                isRunning = false
            }
        }
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
        isRunning = false
        statusText = "Stopped"

        queue.async { [weak self] in
            self?.lastProcessTime = 0
        }
    }
    // MARK: - Derived UI-friendly values

    /// Face Y in SwiftUI-style normalized coordinates (0 = top, 1 = bottom).
    var faceYTopDown: CGFloat? {
        guard let bb = faceBoundingBox else { return nil }
        return 1.0 - bb.midY
    }

    var faceOpacity: Double {
        guard let y = faceYTopDown else { return 0.15 }
        let clamped = min(max(y, 0), 1)
        return Double(clamped)
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }
        isConfigured = true

        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        guard let camera = Self.preferredCameraDevice() else {
            session.commitConfiguration()
            throw NSError(
                domain: "FaceCameraOverlay",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No video capture device available (external webcam not found and no fallback camera available)"]
            )
        }
        


        let input = try AVCaptureDeviceInput(device: camera)
        if session.canAddInput(input) { session.addInput(input) }

        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }

        // Configure orientation + mirroring.
        // External webcams generally should NOT be mirrored.
        if let conn = output.connection(with: .video) {
            conn.videoOrientation = .portrait
            conn.isVideoMirrored = (camera.position == .front)
        }

        session.commitConfiguration()
    }

    /// Prefer an external USB webcam on Mac (Catalyst), otherwise fall back to any available camera.
    private static func preferredCameraDevice() -> AVCaptureDevice? {
        // On macOS/Catalyst, USB webcams typically show up as `.externalUnknown`.
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external, .builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )

        // Prefer external first.
        if let external = discovery.devices.first(where: { $0.deviceType == .external }) {
            return external
        }

        // Fall back to any other video device.
        return discovery.devices.first
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

    private func processFace(on pixelBuffer: CVPixelBuffer) {
        // Throttle Vision (runs on queue).
        let now = CACurrentMediaTime()
        if now - lastProcessTime < minInterval { return }
        lastProcessTime = now

        let request = VNDetectFaceLandmarksRequest { [weak self] request, _ in
            guard let self else { return }
            guard let faces = request.results as? [VNFaceObservation], !faces.isEmpty else {
                Task { @MainActor in
                    self.faceBoundingBox = nil
                    self.landmarkPoints = []
                }
                return
            }

            // Pick the largest face.
            let best = faces.max(by: {
                ($0.boundingBox.width * $0.boundingBox.height) <
                ($1.boundingBox.width * $1.boundingBox.height)
            })

            guard let best else {
                Task { @MainActor in
                    self.faceBoundingBox = nil
                    self.landmarkPoints = []
                }
                return
            }

            let bb = best.boundingBox

            // Extract landmark points and convert them into full-image normalized coordinates.
            // VNFaceLandmarkRegion2D normalizedPoints are in the face's bounding-box space.
            var points: [CGPoint] = []
            if let lm = best.landmarks {
                func append(_ region: VNFaceLandmarkRegion2D?) {
                    guard let region else { return }
                    for p in region.normalizedPoints {
                        // Convert from face-local (0..1) to full-image normalized.
                        let gx = bb.minX + CGFloat(p.x) * bb.width
                        let gy = bb.minY + CGFloat(p.y) * bb.height
                        points.append(CGPoint(x: gx, y: gy))
                    }
                }

                // Add the most useful landmark regions.
                append(lm.leftEye)
                append(lm.rightEye)
                append(lm.leftEyebrow)
                append(lm.rightEyebrow)
                append(lm.nose)
                append(lm.noseCrest)
                append(lm.outerLips)
                append(lm.innerLips)
                append(lm.faceContour)
            }

            Task { @MainActor in
                self.faceBoundingBox = bb
                self.landmarkPoints = points
            }
        }

        do {
            // Orientation is often fine as `.up` for normalized boxes, especially if preview looks correct.
            try sequenceHandler.perform([request], on: pixelBuffer, orientation: .up)
        } catch {
            // ignore transient Vision errors
        }
    }
}

extension FaceCameraOverlayModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processFace(on: pixelBuffer)
    }
}

// MARK: - SwiftUI camera preview (Catalyst / iOS)

struct CameraPreview: View {
    let session: AVCaptureSession

    var body: some View {
        PreviewRepresentable(session: session)
    }
}

#if canImport(UIKit)
import UIKit

struct PreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

#elseif canImport(AppKit)
import AppKit

struct PreviewRepresentable: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> PreviewNSView {
        let v = PreviewNSView()
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateNSView(_ nsView: PreviewNSView, context: Context) {
        nsView.videoPreviewLayer.session = session
    }
}

final class PreviewNSView: NSView {
    let videoPreviewLayer = AVCaptureVideoPreviewLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.addSublayer(videoPreviewLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        videoPreviewLayer.frame = bounds
    }
}
#endif
