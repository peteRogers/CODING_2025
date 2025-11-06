//
//  AudioController.swift
//  Vision_swiftUI_Boiler
//
//  Created by Peter Rogers on 30/01/2024.
//

import Foundation
import AudioKit
import SoundpipeAudioKit
import AudioToolbox
import Vision
import DunneAudioKit
import AudioKitEX


@MainActor class PointsModel: ObservableObject {
	

	@Published var currentPoints:[MyJoint] = []
	
	var visionPoints:[MyJoint]?{
		didSet{
			if let  v = visionPoints{
				currentPoints = v
                callToArms()
			}
			else{
				print("nothing detected")
			}
		}
	}
    
    func callToArms(){
        //do something
    }
	
	
	func angleBetweenPoints(point1: CGPoint, point2: CGPoint) -> CGFloat {
		let deltaX = point2.x - point1.x
		let deltaY = point2.y - point1.y
		return atan2(deltaY, deltaX)
	}
	
	func map(value: CGFloat, fromSourceRange sourceRange: (min: CGFloat, max: CGFloat), toDestinationRange destinationRange: (min: CGFloat, max: CGFloat)) -> CGFloat {
		// First, normalize the value to a 0 to 1 range (relative to the source range)
		let normalized = (value - sourceRange.min) / (sourceRange.max - sourceRange.min)
		// Then, map the normalized value to the destination range
		return normalized * (destinationRange.max - destinationRange.min) + destinationRange.min
	}
	
	func constrain(value: CGFloat, floor: CGFloat, ceiling: CGFloat) -> CGFloat{
		var out = value
		if out > ceiling {
			out = ceiling
		}
		if(out < floor){
			out = floor
		}
		return out
	}
}
