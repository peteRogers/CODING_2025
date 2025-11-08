//
//  ContentView.swift
//  Flame_Serial
//
//  Created by Peter Rogers on 17/10/2025.
//

import SwiftUI

struct FlameControlPanel: View {
   @Binding var serialModel: SerialModel
   
    
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("v1: \(serialModel.v1, specifier: "%.2f")")
                    .foregroundStyle(.white).padding(10)
                Slider(value: $serialModel.v1, in: 0.0...0.3)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
            .background(
                Color.white.opacity(0.6)
                    .cornerRadius(10)
            )
            
            VStack(alignment: .leading) {
                Text("v2: \(serialModel.v2, specifier: "%.2f")")
                    .foregroundStyle(.white).padding(10)
                Slider(value: $serialModel.v2, in: 0.0...0.6)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
            .background(
                Color.white.opacity(0.6)
                    .cornerRadius(10)
            )
            VStack(alignment: .leading) {
                Text("v3: \(serialModel.v3, specifier: "%.2f")")
                    .foregroundStyle(.white).padding(10)
                Slider(value: $serialModel.v3, in: 0.0...0.3)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
            .background(
                Color.white.opacity(0.6)
                    .cornerRadius(10)
            )
            VStack(alignment: .leading) {
                Text("v4: \(serialModel.v4, specifier: "%.2f")")
                    .foregroundStyle(.white).padding(10)
                Slider(value: $serialModel.v4, in: 0.0...1.5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
            .background(
                Color.white.opacity(0.6)
                    .cornerRadius(10)
            )
            

        }
        .frame(width: 400)
    }
}

struct ContentView: View {
   
    @State var serialModel = SerialModel()

    private let date = Date()
    @State var showPanel:Bool = true
    var body: some View {
        ZStack{
            
            Color.black.ignoresSafeArea()
            
            TimelineView(.animation) { timeline in
                let time = date.timeIntervalSince1970 - timeline.date.timeIntervalSince1970
                
                Rectangle()
                    .colorEffect(
                        ShaderLibrary.candleFlame(
                            .boundingRect,
                            .float(time),
                            .float(0.02),//bloom
                            .float2(0.07, 0.1),//hoz and vert flutter
                            .float3(serialModel.v1, serialModel.v2, serialModel.v3),
                            .float(serialModel.v4)
                            
                        )
                    )
                    .ignoresSafeArea()
                    .aspectRatio(contentMode: .fill)
                // .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
            if(showPanel){
                HStack {
                    FlameControlPanel(serialModel: $serialModel)
                    Spacer()
                }
                .padding(50)
            }
        }.onAppear(){
            //serialModel.startSerial()
        }
    }
}

#Preview {
    ContentView()
}
