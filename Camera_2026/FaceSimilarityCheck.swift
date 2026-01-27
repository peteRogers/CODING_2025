//
//  FaceSimilarityCheck.swift
//  cameraTest
//
//  Created by Peter Rogers on 27/01/2026.
//

import SwiftUI
import Observation
import AVFoundation
import Vision
import QuartzCore   // CACurrentMediaTime

// MARK: - Demo SwiftUI view: live camera preview + face box overlay

struct FaceCameraSimilarityView: View {

    let model: FaceSimilarityModel
    var showPreview: Bool = true

    var body: some View {
        ZStack {
            if showPreview {
                CameraPreview(session: model.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            GeometryReader { geo in
                ForEach(model.trackedFaces) { tf in
                    let bb = tf.boundingBox
                    let w = bb.width * geo.size.width
                    let h = bb.height * geo.size.height
                    let x = bb.minX * geo.size.width
                    let yTopLeft = (1.0 - bb.maxY) * geo.size.height

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(lineWidth: 3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("ID \(tf.personID)")
                                .font(.caption)
                                .bold()

                            if let d = tf.lastDistance {
                                Text(String(format: "dist: %.3f  conf: %.2f", d, tf.confidence))
                                    .font(.caption2)
                            } else {
                                Text(String(format: "dist: —  conf: %.2f", tf.confidence))
                                    .font(.caption2)
                            }
                        }
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(6)
                    }
                    .frame(width: w, height: h)
                    .position(x: x + w * 0.5, y: yTopLeft + h * 0.5)
                    .animation(.smooth(duration: 0.08), value: tf.boundingBox)
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

// MARK: - Model: session + Vision face detection + robust multi-person ID

@MainActor
@Observable
final class FaceSimilarityModel: NSObject {

    struct TrackedFace: Identifiable, Equatable {
        let id: Int
        let personID: Int
        var boundingBox: CGRect
        var lastDistance: Double?
        var confidence: Double
        var lastSeen: CFTimeInterval
    }

    private struct Track {
        var id: Int
        var bbox: CGRect
        var lastSeen: CFTimeInterval
        var prints: [VNFeaturePrintObservation]
        var lastDistance: Double?
        var confidence: Double
        var trackingObservation: VNDetectedObjectObservation?
    }

    // Public (observed)
    var trackedFaces: [TrackedFace] = []
    var isRunning: Bool = false
    var statusText: String = "Starting…"

    // Public (not observed)
    @ObservationIgnored
    let session = AVCaptureSession()

    // Private (not observed)
    @ObservationIgnored private let output = AVCaptureVideoDataOutput()
    @ObservationIgnored private let queue = DispatchQueue(label: "FaceCameraOverlay.VideoQueue")
    @ObservationIgnored private let sessionQueue = DispatchQueue(label: "FaceCameraOverlay.SessionQueue")
    @ObservationIgnored private let sequenceHandler = VNSequenceRequestHandler()
    @ObservationIgnored private let ciContext = CIContext()

    // Tracks
    @ObservationIgnored private var nextPersonID: Int = 1
    @ObservationIgnored private var tracks: [Int: Track] = [:]

    // Robustness-first tuning
    @ObservationIgnored private let forgetAfterSeconds: CFTimeInterval = 30.0
    @ObservationIgnored private let matchThreshold: Float = 0.45     // strict threshold
    @ObservationIgnored private let relaxedThreshold: Float = 0.85   // allowed when IOU is high
    @ObservationIgnored private let minIOUForRelaxed: Float = 0.20
    @ObservationIgnored private let strongOverlapNoNewID: Float = 0.30
    @ObservationIgnored private let maxPrintHistory: Int = 8

    @ObservationIgnored private var isConfigured = false
    @ObservationIgnored private var lastDetectionTime: CFTimeInterval = 0
    @ObservationIgnored private var detectionInterval: CFTimeInterval = 0.08 // identity refresh (~12.5 fps)

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

                sessionQueue.async { [weak self] in
                    guard let self else { return }
                    self.session.startRunning()
                    Task { @MainActor in
                        self.isRunning = true
                        self.statusText = "Running"
                    }
                }
            } catch {
                statusText = "Failed: \(error.localizedDescription)"
                isRunning = false
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
        isRunning = false
        statusText = "Stopped"

        queue.async { [weak self] in
            self?.lastDetectionTime = 0
        }
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }
        isConfigured = true

        session.beginConfiguration()
        session.sessionPreset = .high

        guard let camera = Self.preferredCameraDevice() else {
            session.commitConfiguration()
            throw NSError(
                domain: "FaceCameraOverlay",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No video capture device available"]
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
            if #available(iOS 17.0, macCatalyst 17.0, *) {
                conn.isVideoMirrored = (camera.position == .front) && (camera.deviceType != .external)
            } else {
                conn.isVideoMirrored = (camera.position == .front)
            }
        }

        session.commitConfiguration()
    }

    /// Prefer an external USB webcam on Mac Catalyst when available.
    private static func preferredCameraDevice() -> AVCaptureDevice? {
        var types: [AVCaptureDevice.DeviceType] = []

        if #available(iOS 17.0, macCatalyst 17.0, *) {
            types.append(.external)
            types.append(.continuityCamera)
        }

        types.append(.builtInWideAngleCamera)

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: types,
            mediaType: .video,
            position: .unspecified
        )

        if #available(iOS 17.0, macCatalyst 17.0, *) {
            if let ext = discovery.devices.first(where: { $0.deviceType == .external }) { return ext }
            if let cont = discovery.devices.first(where: { $0.deviceType == .continuityCamera }) { return cont }
        }

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

    // MARK: - Matching helpers

    private func iou(_ a: CGRect, _ b: CGRect) -> Float {
        let inter = a.intersection(b)
        if inter.isNull || inter.width <= 0 || inter.height <= 0 { return 0 }
        let interArea = Float(inter.width * inter.height)
        let unionArea = Float(a.width * a.height + b.width * b.height) - interArea
        if unionArea <= 0 { return 0 }
        return interArea / unionArea
    }

    private func minDistance(to track: Track, from fp: VNFeaturePrintObservation) -> Float {
        var best: Float = .greatestFiniteMagnitude
        for stored in track.prints {
            var d: Float = 0
            do { try fp.computeDistance(&d, to: stored) } catch { continue }
            if d < best { best = d }
        }
        return best
    }

    // MARK: - Main pipeline

    private func processFace(on pixelBuffer: CVPixelBuffer) {
        let now = CACurrentMediaTime()

        // 0) Tracking every frame
        trackExistingObjects(on: pixelBuffer, now: now)

        // Identity refresh (face detection + feature prints) periodically
        if now - lastDetectionTime < detectionInterval {
            publishTracks(now: now)
            return
        }
        lastDetectionTime = now

        // 1) Detect faces
        let detect = VNDetectFaceRectanglesRequest()
        do {
            try sequenceHandler.perform([detect], on: pixelBuffer, orientation: .up)
        } catch {
            return
        }

        let faces = (detect.results as? [VNFaceObservation]) ?? []

        // If no faces: do NOT clear IDs, keep them alive
        if faces.isEmpty {
            publishTracks(now: now)
            return
        }

        // 2) Build detections as (bbox, featurePrint) only when print succeeds
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let width = ciImage.extent.width
        let height = ciImage.extent.height

        struct Detection {
            let bbox: CGRect
            let fp: VNFeaturePrintObservation
        }

        var detections: [Detection] = []
        detections.reserveCapacity(faces.count)

        for face in faces {
            let bb = face.boundingBox

            let rect = CGRect(
                x: bb.minX * width,
                y: bb.minY * height,
                width: bb.width * width,
                height: bb.height * height
            ).intersection(ciImage.extent)

            guard rect.width >= 16, rect.height >= 16 else { continue }

            let cropped = ciImage.cropped(to: rect)
            guard let cg = ciContext.createCGImage(cropped, from: cropped.extent) else { continue }

            let req = VNGenerateImageFeaturePrintRequest()
            let handler = VNImageRequestHandler(cgImage: cg, orientation: .up, options: [:])
            do { try handler.perform([req]) } catch { continue }

            guard let fp = req.results?.first as? VNFeaturePrintObservation else { continue }
            detections.append(Detection(bbox: bb, fp: fp))
        }

        if detections.isEmpty {
            // No prints; keep existing IDs
            publishTracks(now: now)
            return
        }

        // 3) If no tracks, create tracks from detections
        if tracks.isEmpty {
            for det in detections {
                let id = nextPersonID
                nextPersonID += 1

                tracks[id] = Track(
                    id: id,
                    bbox: det.bbox,
                    lastSeen: now,
                    prints: [det.fp],
                    lastDistance: nil,
                    confidence: 1.0,
                    trackingObservation: VNDetectedObjectObservation(boundingBox: det.bbox)
                )
                print("[FaceSimilarity] NEW person \(id)")
            }
            publishTracks(now: now)
            return
        }

        // 4) Build cost matrix (greedy assignment) using min distance across history + IOU blend
        let trackIDs = tracks.keys.sorted()

        var costMatrix: [[Float]] = []
        costMatrix.reserveCapacity(trackIDs.count)

        for tid in trackIDs {
            guard let tr = tracks[tid], !tr.prints.isEmpty else {
                costMatrix.append(Array(repeating: Float.greatestFiniteMagnitude, count: detections.count))
                continue
            }

            var row: [Float] = []
            row.reserveCapacity(detections.count)

            for det in detections {
                let dist = minDistance(to: tr, from: det.fp)
                let overlap = iou(tr.bbox, det.bbox)

                let allow: Bool
                if overlap >= minIOUForRelaxed {
                    allow = (dist <= relaxedThreshold)
                } else {
                    allow = (dist <= matchThreshold)
                }

                if allow {
                    let cost = (0.80 * dist) + (0.20 * (1.0 - overlap))
                    row.append(cost)
                } else {
                    row.append(Float.greatestFiniteMagnitude)
                }
            }

            costMatrix.append(row)
        }

        func assignGreedy(_ costMatrix: [[Float]]) -> [(Int, Int)] {
            var assignments: [(Int, Int)] = []
            var usedRows: Set<Int> = []
            var usedCols: Set<Int> = []

            let rowCount = costMatrix.count
            let colCount = costMatrix.first?.count ?? 0

            while true {
                var best: Float = Float.greatestFiniteMagnitude
                var bestR: Int? = nil
                var bestC: Int? = nil

                for r in 0..<rowCount where !usedRows.contains(r) {
                    for c in 0..<colCount where !usedCols.contains(c) {
                        let v = costMatrix[r][c]
                        if v < best {
                            best = v
                            bestR = r
                            bestC = c
                        }
                    }
                }

                if let r = bestR, let c = bestC, best < Float.greatestFiniteMagnitude {
                    assignments.append((r, c))
                    usedRows.insert(r)
                    usedCols.insert(c)
                } else {
                    break
                }
            }

            return assignments
        }

        let assignments = assignGreedy(costMatrix)

        var matchedDetections = Set<Int>()
        var matchedTracks = Set<Int>()

        // 5) Apply matches
        for (trackIndex, detectionIndex) in assignments {
            let tid = trackIDs[trackIndex]
            let det = detections[detectionIndex]

            guard var tr = tracks[tid] else { continue }

            matchedTracks.insert(tid)
            matchedDetections.insert(detectionIndex)

            tr.bbox = det.bbox
            tr.trackingObservation = VNDetectedObjectObservation(boundingBox: det.bbox)
            tr.lastSeen = now

            let appearanceDist = minDistance(to: tr, from: det.fp)
            tr.lastDistance = Double(appearanceDist)

            tr.confidence = min(1.0, tr.confidence + 0.12)

            tr.prints.append(det.fp)
            if tr.prints.count > maxPrintHistory {
                tr.prints.removeFirst(tr.prints.count - maxPrintHistory)
            }

            tracks[tid] = tr
            print("[FaceSimilarity] person \(tid) dist=\(String(format: "%.3f", appearanceDist))")
        }

        // 6) Unmatched tracks: reduce confidence but keep alive (TTL handles long occlusion)
        for tid in trackIDs where !matchedTracks.contains(tid) {
            guard var tr = tracks[tid] else { continue }
            tr.confidence = max(0.0, tr.confidence - 0.08)
            // Only drop tracking when very low confidence.
            if tr.confidence < 0.10 { tr.trackingObservation = nil }
            tracks[tid] = tr
        }

        // 7) Unmatched detections: only create new IDs if they DO NOT overlap an existing track strongly
        for (idx, det) in detections.enumerated() where !matchedDetections.contains(idx) {

            var overlapsExisting = false
            for tid in trackIDs {
                if let tr = tracks[tid], iou(tr.bbox, det.bbox) >= strongOverlapNoNewID {
                    overlapsExisting = true
                    break
                }
            }
            if overlapsExisting { continue }

            let id = nextPersonID
            nextPersonID += 1

            tracks[id] = Track(
                id: id,
                bbox: det.bbox,
                lastSeen: now,
                prints: [det.fp],
                lastDistance: nil,
                confidence: 1.0,
                trackingObservation: VNDetectedObjectObservation(boundingBox: det.bbox)
            )
            print("[FaceSimilarity] NEW person \(id)")
        }

        publishTracks(now: now)
    }

    private func publishTracks(now: CFTimeInterval) {
        let cutoff = now - forgetAfterSeconds
        tracks = tracks.filter { $0.value.lastSeen >= cutoff }

        let ui = tracks.values
            .sorted(by: { $0.id < $1.id })
            .map { t in
                TrackedFace(
                    id: t.id,
                    personID: t.id,
                    boundingBox: t.bbox,
                    lastDistance: t.lastDistance,
                    confidence: t.confidence,
                    lastSeen: t.lastSeen
                )
            }

        Task { @MainActor in
            self.trackedFaces = ui
        }
    }

    private func trackExistingObjects(on pixelBuffer: CVPixelBuffer, now: CFTimeInterval) {
        guard !tracks.isEmpty else { return }

        var requests: [VNTrackObjectRequest] = []
        requests.reserveCapacity(tracks.count)

        let ids = tracks.keys.sorted()
        for tid in ids {
            guard let obs = tracks[tid]?.trackingObservation else { continue }
            let req = VNTrackObjectRequest(detectedObjectObservation: obs)
            req.trackingLevel = .fast
            requests.append(req)
        }
        guard !requests.isEmpty else { return }

        do {
            try sequenceHandler.perform(requests, on: pixelBuffer, orientation: .up)
        } catch {
            return
        }

        var reqIndex = 0
        for tid in ids {
            guard var tr = tracks[tid], tr.trackingObservation != nil else { continue }

            let req = requests[reqIndex]
            reqIndex += 1

            guard let newObs = req.results?.first as? VNDetectedObjectObservation else {
                tr.trackingObservation = nil
                tr.confidence = max(0.0, tr.confidence - 0.20)
                tracks[tid] = tr
                continue
            }

            if newObs.confidence < 0.2 {
                tr.trackingObservation = nil
                tr.confidence = max(0.0, tr.confidence - 0.20)
                tracks[tid] = tr
                continue
            }

            tr.trackingObservation = newObs
            tr.bbox = newObs.boundingBox
            tr.lastSeen = now
            tr.confidence = min(1.0, max(tr.confidence * 0.8, Double(newObs.confidence)))
            tracks[tid] = tr
        }
    }
}

extension FaceSimilarityModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processFace(on: pixelBuffer)
    }
}
