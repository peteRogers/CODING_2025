//
//  BubbleView.swift
//  ShaderExamples
//
//  Created by Peter Rogers on 07/11/2025.
//


import SwiftUI

struct BubbleImageView: View {
    @State private var radius: CGFloat = 0.1
    @State private var touchPoint = CGPoint(x: 150, y: 150)
    @State private var imageSize: CGSize = .zero
    var fileName: String? = "stainWindow"

    var body: some View {
        Image(fileName!)
            .resizable()
            .scaledToFit()
            .padding(25)
            .background(.white)
            .drawingGroup()
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
            .layerEffect(
                ShaderLibrary.warpingLoupe(
                    .float2(Float(imageSize.width),  Float(imageSize.height)),
                    .float2(Float(touchPoint.x),     Float(touchPoint.y)),
                    .float(Float(radius)),
                    .float(2.0)
                ),
                maxSampleOffset: CGSize(width: radius, height: radius)
            )
    }
}
