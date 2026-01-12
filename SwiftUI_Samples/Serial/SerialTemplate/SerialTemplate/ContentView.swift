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
            Slider(value: $serialModel.val0, in: 0...1024)
                .padding(.horizontal, 200)
            Text("\(serialModel.serial?.latestValuesFromArduino[1] ?? 0)")
        }
        .onAppear {
            serialModel.startSerial()
        }
    }
}

#Preview {
    ContentView()
}
