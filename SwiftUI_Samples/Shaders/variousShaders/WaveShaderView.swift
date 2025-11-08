//
//  PixellateView.swift
//  NewScroll
//
//  Created by Astemir Eleev on 21.06.2023.


import SwiftUI

struct WaveShaderView: View {
    @State private var mouseX: CGFloat = 0
    private var date = Date()
    var body: some View {
        ZStack{
            VStack{
                GeometryReader { geo in
                    TimelineView(.animation) { context in
                        let time = context.date.timeIntervalSince1970 - date.timeIntervalSince1970
                        let normalized = max(0, min(1, mouseX / geo.size.width))
                        let strength = normalized * 20 // adjust range
                        
                        Image(uiImage: UIImage(named: "tester")!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .distortionEffect(
                                ShaderLibrary.waveParamed(
                                    .float(time*4),
                                    .float(2),
                                    .float(10),
                                    .float(strength*2),
                                    .float(1)
                                ),
                                maxSampleOffset: .zero
                            )
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        mouseX = value.location.x
                                    }
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                }
            }
        }
    }
}

#Preview {
    WaveShaderView()
}
