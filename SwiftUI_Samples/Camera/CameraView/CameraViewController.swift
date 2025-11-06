//
//  CameraViewController.swift
//  vision_swiftUI
//
//  Created by Peter Rogers on 07/12/2022.
//


import UIKit
import AVFoundation
import Vision

final class CameraViewController: UIViewController {
    
    private var cameraView: CameraPreview { view as! CameraPreview }
	
    private let videoDataOutputQueue = DispatchQueue(
        label: "CameraFeedOutput",
        qos: .userInteractive
    )
    private var cameraFeedSession: AVCaptureSession?
//    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
//        let request = VNDetectHumanHandPoseRequest()
//        request.maximumHandCount = 2
//        return request
//    }()
    
    private let bodyPoseRequest: VNDetectHumanBodyPoseRequest = {
        let request = VNDetectHumanBodyPoseRequest()
        
        return request
    }()
    
    private let facePoseRequest: VNDetectFaceLandmarksRequest = {
        let request = VNDetectFaceLandmarksRequest()
        
        return request
    }()
    
    var pointsProcessorHandler: (([MyJoint]) -> Void)?
    
    override func loadView() {
        
        view = CameraPreview()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            if cameraFeedSession == nil {
                try setupAVSession()
               // cameraView.previewLayer.connection?.videoOrientation = .portrait
                cameraView.previewLayer.session = cameraFeedSession
				if #available(iOS 17.0, *) {
					cameraView.previewLayer.connection?.videoRotationAngle = 0
				} else {
					// Fallback on earlier versions
				}
                //cameraView.previewLayer.videoGravity = .resizeAspect
                
            }
            DispatchQueue.global(qos: .userInitiated).async{
                self.cameraFeedSession?.startRunning()
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    
    func setupAVSession() throws {
        
        // Select a front facing camera, make an input.
        guard let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
			position: .front)
		    
        else {
            throw AppError.captureSessionSetup(
                reason: "Could not find a front facing camera."
            )
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(
            device: videoDevice
        ) else {
            throw AppError.captureSessionSetup(
                reason: "Could not create video device input."
            )
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
		
        
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else {
            throw AppError.captureSessionSetup(
                reason: "Could not add video device input to the session"
            )
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            // Add a video data output.
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            throw AppError.captureSessionSetup(
                reason: "Could not add video data output to the session"
            )
        }
        session.commitConfiguration()
        cameraFeedSession = session
    }
    
    func processPoints(_ points: [MyJoint]) {
        // Convert points from AVFoundation coordinates to UIKit coordinates.
        
        let convertedPoints = points.map {
			MyJoint(imagePoint: cameraView.previewLayer.layerPointConverted(fromCaptureDevicePoint:
																				$0.imagePoint ?? CGPoint(x: 0, y: 0)),
					visionPoint: $0.visionPoint )
			
			
        }
        pointsProcessorHandler?(convertedPoints)
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
   
    
    func processBodyLandmarks(handler: VNImageRequestHandler){
		var bodyPoints: [MyJoint] = []
		defer {
			DispatchQueue.main.sync {
				self.processPoints(bodyPoints)
			}
		}
		do{
			try handler.perform([bodyPoseRequest])
			guard
				let results = bodyPoseRequest.results?.prefix(1),
				!results.isEmpty
			else {
				return
			}
			
			if let body = results.first  {
//				let affineTransform = CGAffineTransform(translationX: body.boundingBox.origin.x, y: body.boundingBox.origin.y)
//					.scaledBy(x: body.boundingBox.size.width, y: body.boundingBox.size.height)
				//print(results.debugDescription)
				
				var recognizedPoints: [MyJoint] = []
				
				if(body.availableJointNames.contains(.neck)){
					recognizedPoints.append(MyJoint(visionPoint: try body.recognizedPoint(.neck)))
				}
				if let j = try? body.recognizedPoint(.nose){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				if let j = try? body.recognizedPoint(.leftShoulder){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				if let j = try? body.recognizedPoint(.rightShoulder){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				if let j = try? body.recognizedPoint(.leftElbow){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				if let j = try? body.recognizedPoint(.rightElbow){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				if let j = try? body.recognizedPoint(.leftWrist){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				if let j = try? body.recognizedPoint(.rightWrist){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				if let j = try? body.recognizedPoint(.root){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				if let j = try? body.recognizedPoint(.leftKnee){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				if let j = try? body.recognizedPoint(.rightKnee){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				if let j = try? body.recognizedPoint(.leftAnkle){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				if let j = try? body.recognizedPoint(.rightAnkle){
					recognizedPoints.append(MyJoint(visionPoint: j))
				}
				
				
				
				bodyPoints = recognizedPoints
				
				.map {
					// Convert points from Vision coordinates to AVFoundation coordinates.
					//stops it all being upside down
				
					MyJoint(imagePoint: CGPoint(x: $0.visionPoint.location.x, y: 1 - $0.visionPoint.location.y), visionPoint: $0.visionPoint)
					
					
				}
				//print(bodyPoints.debugDescription)
			
				}
			
		}catch{
			print(error)
		}
		
        
    }
    
    
//    func processFaceLandmarks(handler: VNImageRequestHandler){
//        var bodyPoints: [CGPoint] = []
//        
//        defer {
//            DispatchQueue.main.sync {
//                self.processPoints(bodyPoints)
//            }
//        }
//        do {
//            // Perform VNDetectHumanHandPoseRequest
//            try handler.perform([facePoseRequest])
//            
//            // Continue only when at least a hand was detected in the frame. We're interested in maximum of two hands.
//            guard
//                let results = facePoseRequest.results?.prefix(1),
//                !results.isEmpty
//            else {
//                return
//            }
//            
////            guard let faceDetectionRequest = request as? VNDetectFaceLandmarksRequest,
////                            let results = faceDetectionRequest.results as? [VNFaceObservation] else {
////                                return
////                        }
//            if let face = results.first  {
//                let affineTransform = CGAffineTransform(translationX: face.boundingBox.origin.x, y: face.boundingBox.origin.y)
//                    .scaledBy(x: face.boundingBox.size.width, y: face.boundingBox.size.height)
//                var recognizedPoints: [CGPoint] = []
//                if let leftEye = face.landmarks?.leftEye{
//                    let p = leftEye.normalizedPoints[0].applying(affineTransform)
//                    recognizedPoints.append(p)
//                }
//				if let rightEye = face.landmarks?.rightEye{
//					let p = rightEye.normalizedPoints[0].applying(affineTransform)
//					recognizedPoints.append(p)
//				}
//                bodyPoints = recognizedPoints
//                .map {
//                    // Convert points from Vision coordinates to AVFoundation coordinates.
//                    //stops it all being upside down
//                    CGPoint(x: $0.x, y: 1 - $0.y)
//                }
//            }
//        } catch {
//            cameraFeedSession?.stopRunning()
//            print(error.localizedDescription)
//        }
//    }
  
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
			orientation: .up,
            options: [:]
        )
		
        //processFaceLandmarks(handler: handler)
	
		processBodyLandmarks(handler: handler)
    }
}
