
import SwiftUI
import Vision

struct PointsOverlay: Shape {
  let joints: [MyJoint]
  
  init(with joints: [MyJoint]) {
    self.joints = joints
  }

  func path(in rect: CGRect) -> Path {
	let pointsPath = UIBezierPath()
    for joint in joints {
		if let ip = joint.imagePoint{
			pointsPath.move(to: ip)
			pointsPath.addArc(withCenter: ip, radius: 15, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
		}
    }
    return Path(pointsPath.cgPath)
  }
}

struct MyJoint{
	var imagePoint: CGPoint?
	let visionPoint: VNRecognizedPoint
	
}

