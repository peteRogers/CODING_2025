//
//  SImpleContentView.swift
//  AudioKit_Sampler
//
//  Created by Peter Rogers on 21/10/2025.
//

import SwiftUI

struct ContentView: View{
    @State private var simpleAudio = SimpleAudioControl()
    //@State private var simpleAudio = GuitarAudioControl()
    
    var body: some View {
        VStack(spacing: 50){
            Text("simple audio player")
                .font(.title)
            Button("Stop") {
                simpleAudio.stop()
            }.font(Font.largeTitle)
            
            Button("Play") {
                simpleAudio.play()
            }.font(Font.largeTitle)
            
            Slider(value: $simpleAudio.playerVolume, in: 0...1)
               .padding(.horizontal, 200)
        }
        .onAppear {
            simpleAudio.setup()
        }
    }
}

#Preview {
    ContentView()
}

