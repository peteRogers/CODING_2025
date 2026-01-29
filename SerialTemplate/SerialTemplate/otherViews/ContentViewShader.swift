//
//  ContentView.swift
//  SerialTemplate
//
//  Created by Peter Rogers on 05/11/2025.
//

import SwiftUI

struct ContentViewShader: View {
    @State private var serialModel = SerialModel()
    var body: some View {
        VStack {
            
            Text("\(serialModel.val0)")
            GeometryReader { geo in
                Image("stainWindow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .distortionEffect(
                        ShaderLibrary.kaleidoscope(
                            .float2(geo.size.width, geo.size.height),
                            .float2(0, 0),
                            .float(10), //how many segments
                            .float((serialModel.val0/64.0) / .pi), //rotation
                            .float((serialModel.val0/256.0)+1)//scale
                        ),
                        maxSampleOffset: CGSize(
                            width: geo.size.width/2,
                            height: geo.size.height/2
                        )
                    )
            }
           
        }
        
        
        .onAppear {
            serialModel.startSerial()
        }
    }
}

#Preview {
    ContentViewShader()
}
