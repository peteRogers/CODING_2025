//
//  Kaleidescope.swift
//  ShaderExamples
//
//  Created by Peter Rogers on 07/11/2025.
//
import SwiftUI

struct KaleidescopeImageView: View {
    @State private var radius: CGFloat = 0.1
    @State private var touchPoint = CGPoint(x: 150, y: 150)
    @State private var imageSize: CGSize = .zero
    @State private var start = Date.now
    var fileName: String? = "stainWindow"

    var body: some View {
        TimelineView(.animation) { timeline in
            // Drive time from the system's animation timeline
            let time = start.distance(to: timeline.date)
            let rotation = fmod(time, 1.0)
            let pulsate = abs(sin(time))
            Image(fileName!)
                .resizable()
                .scaledToFit()
            // capture size + pointer/drag on top of the image
                .overlay {
                    GeometryReader { geo in
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in touchPoint = value.location }
                            )
                            .onAppear { imageSize = geo.size }
                            .onChange(of: geo.size) { _, new in imageSize = new }
                    }
                }
            // apply the shader to the image itself
                .distortionEffect(
                    ShaderLibrary.kaleidoscope(
                        .float2(Float(imageSize.width),  Float(imageSize.height)),
                        .float2(0.0, 0.0),
                        .float(10),
                        .float(pulsate),
                        .float((pulsate*6)+0.1)
                    ),
                    maxSampleOffset: CGSize(width: radius, height: radius)
                )
        }
    }
}
