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
        VStack {
            
            Text("\(serialModel.val0)")
           
        }
        
        
        .onAppear {
            serialModel.startSerial()
        }
    }
}

#Preview {
    ContentView()
}
