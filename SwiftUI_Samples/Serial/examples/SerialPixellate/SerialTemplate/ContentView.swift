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
        ZStack{
            Rectangle()
                .fill(.white)
            VStack {
                Image("stainWindow")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .distortionEffect(
                        ShaderLibrary.pixellate(
                            .float(serialModel.pixel * 100)
                        ),
                        maxSampleOffset:.zero)
                
                Slider(value: $serialModel.pixel, in: 0...1)
                    .padding(.horizontal, 200)
                    .padding(.bottom, 100)
                
            }
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


