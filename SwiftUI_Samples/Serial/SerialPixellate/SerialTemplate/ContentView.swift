//
//  ContentView.swift
//  SerialTemplate
//
//  Created by Peter Rogers on 05/11/2025.
//

import SwiftUI


struct ContentView: View {
    @State private var serialModel = SerialModel()
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white)
//            Slider(value: $serialModel.pixel, in: 0...1)
//                .padding(.horizontal, 200)
//                Image("stainWindow")
//                    .resizable()
//                    .scaledToFit()
//                    .padding(25)
//                    .background(.white)
//                    .drawingGroup()
//                    .aspectRatio(contentMode: .fit)
//                    .distortionEffect(
//                        
//                        ShaderLibrary.pixellate(
//                            .float(serialModel.pixel * 100)
//                        ),
//                        maxSampleOffset: .zero
//                    )
            Image("stainWindow")
                .resizable()
                .scaledToFit()
                .padding(25)
                .background(.white)
                .drawingGroup()
                .distortionEffect(ShaderLibrary.water(
                    .float2(serialModel.pixel * 400, serialModel.pixel * 400),
                    .float(serialModel.pixel * 10),
                    .float(100),
                    .float(10),
                    .float(2)
                    
                ),maxSampleOffset: .zero
                )
        }.edgesIgnoringSafeArea(.all)
        .background(.white)
        .onAppear {
            serialModel.startSerial()
        }
    }
}





#Preview {
    ContentView()
}


