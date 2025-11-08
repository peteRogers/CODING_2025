//
//  WaterView.swift
//  ShaderExamples
//
//  Created by Peter Rogers on 07/11/2025.
//
import SwiftUI

struct WaterImageView: View {
    @State private var start = Date.now
    var fileName: String? = "stainWindow"
    var body: some View {
        TimelineView(.animation) { timeline in
            // Drive time from the system's animation timeline
            let time = start.distance(to: timeline.date)

            // Build the shader (SwiftUI auto-injects position & size)
            Image(fileName!)
                .resizable()
                .scaledToFit()
                .padding(25)
                .background(.white)
                .drawingGroup()
                .distortionEffect(ShaderLibrary.water(
                    .float2(50, 50),
                    .float(time),
                    .float(100),
                    .float(10),
                    .float(2)
                    
                ),maxSampleOffset: .zero
                )

        }
    }
}
