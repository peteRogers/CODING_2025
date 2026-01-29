//
//  ContentView.swift
//  SerialTemplate
//
//  Created by Peter Rogers on 05/11/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var serialModel = SerialModel()
    //@State private var audio = AudioController()
    
    var body: some View {
        VStack {
            Text("\(serialModel.val0)")
                
            Circle()
                .fill(.blue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(CGFloat(serialModel.val0/1024.0))
        }
        
        .onChange(of: serialModel.val0) { oldValue, newValue in
            //this is where you can read new arduino values
            //audio.pitchAmount = newValue
            
        }
        .onAppear {
            serialModel.startSerial()
            //audio.setup()
            //audio.play()
        }
    }
}

//#Preview {
//    ContentView()
//}
