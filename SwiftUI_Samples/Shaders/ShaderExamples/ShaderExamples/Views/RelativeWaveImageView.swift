//
//  RelativeWaveImageView.swift
//  ShaderExamples
//
//  Created by Peter Rogers on 07/11/2025.
//
import SwiftUI

struct RelativeWaveImageView: View {
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
                .padding(.vertical, 20)
                .background(.white)
                .drawingGroup()
                .distortionEffect(ShaderLibrary.relativeWave(
                    .float2(200, 100),
                    .float(time),
                    .float(10),
                    .float(50),
                    .float(10)
                ),maxSampleOffset: .zero
                )
        }
    }
}
