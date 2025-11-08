//
//  ContentView.swift
//  ShaderExamples
//
//  Created by Peter Rogers on 05/11/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack{
            Rectangle()
                .fill(Color.white)
            
            VStack{
                HStack {
                    WaterImageView()
                    BubbleImageView(fileName: "tester")
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
}

#Preview {
    ContentView()
}
