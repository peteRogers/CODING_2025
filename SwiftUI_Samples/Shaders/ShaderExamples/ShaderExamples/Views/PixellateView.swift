//
//  PixellateView.swift
//  ShaderExamples
//
//  Created by Peter Rogers on 07/11/2025.
//
import SwiftUI

struct PixellateImageView: View {
    @State private var start = Date.now
    var fileName: String? = "stainWindow"
    var body: some View {
        TimelineView(.animation) { timeline in
            // Drive time from the system's animation timeline
            let time = start.distance(to: timeline.date)
            let strength = abs(sin(time)) // smooth pulse from 0→1→0
            // Build the shader (SwiftUI auto-injects position & size)
            Image(fileName!)
                .resizable()
                .scaledToFit()
                .padding(25)
                .background(.white)
                .drawingGroup()
                .aspectRatio(contentMode: .fit)
                .distortionEffect(
                    
                    ShaderLibrary.pixellate(
                        .float(strength*10)
                    ),
                    maxSampleOffset: .zero
                )
        }
    }
}
