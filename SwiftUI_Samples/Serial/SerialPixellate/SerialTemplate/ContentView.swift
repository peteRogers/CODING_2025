//
//  ContentView.swift
//  SerialTemplate
//
//  Created by Peter Rogers on 05/11/2025.
//

import SwiftUI


struct ContentView: View {
    @State private var serialModel = SerialModel()
    @State private var lastUpdate = Date()
    let pixelRate: CGFloat  = 0.8
    
    var body: some View {
        ZStack {
            Slider(value: $serialModel.pixel, in: 0...1)
                .padding(.horizontal, 200)
                Image("stainWindow")
                    .resizable()
                    .scaledToFit()
                    .padding(25)
                    .background(.white)
                    .drawingGroup()
                    .aspectRatio(contentMode: .fit)
                    .distortionEffect(
                        
                        ShaderLibrary.pixellate(
                            .float(serialModel.pixel * 100)
                        ),
                        maxSampleOffset: .zero
                    )
        }
        .onAppear {
            serialModel.startSerial()
        }
    }
}





#Preview {
    ContentView()
}


