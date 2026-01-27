import AVFoundation
import Vision
import SwiftUI
import Observation

@Observable
@MainActor
class MotionManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // Observable UI Properties
    var averageAngle: Double = 0.0
    var motionIntensity: Float = 0.0
    
    // Circular Smoothing State
    private var smoothedSin: Double = 0.0
    private var smoothedCos: Double = 1.0 // Start facing "Right" (0°)
    
    // Settings
    private let angleSmoothing: Double = 0.15 // Lower is smoother/slower (0.0 to 1.0)
    private let intensityDecay: Float = 0.80
    private let sensitivityMultiplier: Float = 12.0

    let session = AVCaptureSession()
    private let opticalFlowRequest = TrackOpticalFlowRequest()
    private var isProcessing = false

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "visionQueue", qos: .userInteractive))
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        
        Task(priority: .userInitiated) { session.startRunning() }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isProcessing else { return }
        isProcessing = true
        
        Task {
            do {
                if let observation = try await opticalFlowRequest.perform(on: sampleBuffer) {
                    processWholeFrame(observation)
                }
            } catch { }
            isProcessing = false
        }
    }

    private func processWholeFrame(_ observation: OpticalFlowObservation) {
        observation.withUnsafePointer { pointer in
            let rawData = pointer.assumingMemoryBound(to: Float32.self)
            let width = Int(observation.size.width)
            let height = Int(observation.size.height)
            
            var frameDx: Double = 0
            var frameDy: Double = 0
            var frameMagnitude: Float = 0
            var samples: Double = 0
            
            for y in stride(from: 0, to: height, by: 12) {
                for x in stride(from: 0, to: width, by: 12) {
                    let index = (y * width + x) * 2
                    let dx = Double(rawData[index])
                    let dy = Double(rawData[index + 1])
                    
                    frameMagnitude += Float(sqrt(dx*dx + dy*dy))
                    
                    // FRONT CAMERA PORTRAIT FIX:
                    // 1. Swap dx/dy for portrait vs landscape buffers.
                    // 2. Negate both to un-mirror horizontal and flip vertical axes.
                    frameDx += -dy
                    frameDy += -dx
                    
                    samples += 1
                }
            }
            
            let currentFrameAngleRad = atan2(frameDy, frameDx)
            let rawIntensity = (frameMagnitude / Float(samples)) * sensitivityMultiplier

            Task { @MainActor in
                self.motionIntensity = (self.motionIntensity * intensityDecay) + (rawIntensity * (1.0 - intensityDecay))
                
                // Circular smoothing prevents jerky jumps
                self.smoothedSin = (self.smoothedSin * (1.0 - angleSmoothing)) + (sin(currentFrameAngleRad) * angleSmoothing)
                self.smoothedCos = (self.smoothedCos * (1.0 - angleSmoothing)) + (cos(currentFrameAngleRad) * angleSmoothing)
                
                self.averageAngle = atan2(self.smoothedSin, self.smoothedCos) * (180 / .pi)
            }
        }
    }


}



struct OpticalFlowView: View {
    // Replaces @StateObject for observable classes
    @State private var manager = MotionManager()

    var body: some View {
        ZStack {
            FlowCameraPreview(session: manager.session)
                .ignoresSafeArea()
            ArrowShape()
                                    .fill(Color.cyan)
                                    .frame(width: 60, height: 80)
                                    // Rotate based on the smooth angle from Vision
                                    // Note: We add 90 degrees if the arrow points 'up' by default
                                    .rotationEffect(.degrees(manager.averageAngle + 180))
                                    // Scale the arrow slightly based on intensity
                                    .scaleEffect(CGFloat(manager.motionIntensity / 50.0))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: manager.averageAngle)
            VStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GLOBAL VIDEO AVERAGE")
                    Text("Angle: \(manager.averageAngle)")
                    Text("Intensity: \(manager.motionIntensity)")
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.top, 50)
                Spacer()
            }
        }
    }
}

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width / 2, y: 0))           // Tip
        path.addLine(to: CGPoint(x: width, y: height * 0.7)) // Right shoulder
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.7)) // Right notch
        path.addLine(to: CGPoint(x: width * 0.7, y: height)) // Right base
        path.addLine(to: CGPoint(x: width * 0.3, y: height)) // Left base
        path.addLine(to: CGPoint(x: width * 0.3, y: height * 0.7)) // Left notch
        path.addLine(to: CGPoint(x: 0, y: height * 0.7))    // Left shoulder
        path.closeSubpath()
        
        return path
    }
}


struct FlowCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = view.layer.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

