
import UIKit
import AVFoundation

final class CameraPreview: UIView {
  var previewLayer: AVCaptureVideoPreviewLayer {
    // swiftlint:disable:next force_cast
    layer as! AVCaptureVideoPreviewLayer
	
  }

  override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
  }
}
