//
//  ContentView.swift
//  SerialTemplate
//
//  Created by Peter Rogers on 05/11/2025.
//

import SwiftUI

struct ContentViewExtended: View {
    @State private var serialModel = SerialModel()
    @State private var audio = AudioController()
    @State private var value = 0.5
    var body: some View {
        VStack {
            
           
            Text("\(serialModel.val0)")
                .onChange(of: serialModel.val0) { oldValue, newValue in
                    audio.playerVolume = newValue/1024.0
                }
            Circle()
                .fill(.blue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(CGFloat(serialModel.val0/1024.0))
            Slider(value: $value, in: 0...4096)
                .onChange(of: value) { oldValue, newValue in
                   serialModel.sendArduinoValue(val: Float(newValue))
                   
                }
                .padding()
            Spacer()
            
        }
        
        
        .onAppear {
            serialModel.startSerial()
            //audio.setup()
           // audio.play()
        }
    }
}

//#Preview {
//    ContentView()
//}
