//
//  ContentView.swift
//  ShaderExamples
//
//  Created by Peter Rogers on 05/11/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack{
            HStack {
                WaterImageView()
                BubbleImageView()
                RelativeWaveImageView()
            }
            HStack {
                PixellateImageView()
                ColorGlitchImageView()
                KaleidescopeImageView()
                    .cornerRadius(250)
            }
            
        }.background(.white)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}

import SwiftUI

struct BubbleImageView: View {
    @State private var radius: CGFloat = 0.1
    @State private var touchPoint = CGPoint(x: 150, y: 150)
    @State private var imageSize: CGSize = .zero

    var body: some View {
        Image("stainWindow")
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

struct KaleidescopeImageView: View {
    @State private var radius: CGFloat = 0.1
    @State private var touchPoint = CGPoint(x: 150, y: 150)
    @State private var imageSize: CGSize = .zero
    @State private var start = Date.now

    var body: some View {
        TimelineView(.animation) { timeline in
            // Drive time from the system's animation timeline
            let time = start.distance(to: timeline.date)
            let rotation = fmod(time, 1.0)
            let pulsate = abs(sin(time))
            Image("stainWindow")
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
import SwiftUI

struct FittingTextCanvas: View {
    var text: String = "SHADERS"

    var body: some View {
        Canvas { context, size in
            // 1) Build and resolve text at a large base size
            let baseText = Text(text)
                .font(.system(size: 100, weight: .bold))

            let resolved = context.resolve(baseText)

            // 2) Measure natural (unconstrained) size
            let natural = resolved.measure(
                in: size).width + 50
            

            //guard natural.width > 0 else { return }

            // 3) Compute scale so natural width -> canvas width
            let scale = size.width / natural

            // 4) Center, then scale, then draw centered
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.scaleBy(x: scale, y: scale)
            context.draw(resolved, at: .zero, anchor: .center)
        }
    }
}

#Preview {
    FittingTextCanvas(text: "Fitting Text Example")
        .frame(width: 300, height: 100)
        .background(Color.black)
}



#Preview {
    BubbleImageView()
}





struct WaterImageView: View {
    @State private var start = Date.now
    var body: some View {
        TimelineView(.animation) { timeline in
            // Drive time from the system's animation timeline
            let time = start.distance(to: timeline.date)

            // Build the shader (SwiftUI auto-injects position & size)
            Image("stainWindow")
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

struct ColorGlitchImageView: View {
    @State private var start = Date.now
    var body: some View {
        TimelineView(.animation) { timeline in
            // Drive time from the system's animation timeline
            let time = start.distance(to: timeline.date)
            let pulsate = abs(sin(time*10)) // smooth
            let noise = Double.random(in: -20...20) // random each frame (less smooth)
            // Build the shader (SwiftUI auto-injects position & size)
            Image("stainWindow")
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

struct RelativeWaveImageView: View {
    @State private var start = Date.now
    var body: some View {
        TimelineView(.animation) { timeline in
            // Drive time from the system's animation timeline
            let time = start.distance(to: timeline.date)

            // Build the shader (SwiftUI auto-injects position & size)
            Image("stainWindow")
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

struct PixellateImageView: View {
    @State private var start = Date.now
    var body: some View {
        TimelineView(.animation) { timeline in
            // Drive time from the system's animation timeline
            let time = start.distance(to: timeline.date)
            let strength = abs(sin(time)) // smooth pulse from 0→1→0
            // Build the shader (SwiftUI auto-injects position & size)
            Image("stainWindow")
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



#Preview {
    WaterImageView()
}
