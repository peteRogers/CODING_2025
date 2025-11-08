//
//  ColorGlitch.swift
//  ShaderExamples
//
//  Created by Peter Rogers on 07/11/2025.
//
import SwiftUI

struct ColorGlitchImageView: View {
    @State private var start = Date.now
    var fileName: String? = "stainWindow"
    
    var body: some View {
        TimelineView(.animation) { timeline in
            // Drive time from the system's animation timeline
            let time = start.distance(to: timeline.date)
            let pulsate = abs(sin(time*10)) // smooth
            let noise = Double.random(in: -20...20) // random each frame (less smooth)
            // Build the shader (SwiftUI auto-injects position & size)
            Image(fileName!)
                .resizable()
                .scaledToFit()
                .padding(20)
                .layerEffect(ShaderLibrary.colorPlanes(
                    .float2((pulsate - 0.5) * 60.0, noise)
                    
                    
                ),maxSampleOffset: .zero
                )

        }
    }
}
