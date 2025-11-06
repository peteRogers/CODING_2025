//
//  Flame.swift
//  NewScroll
//
//  Created by Astemir Eleev on 07.07.2023.
//

import SwiftUI

struct Flame: View {
    @State private var bloom: CGFloat = 0.1
    @State private var verticalMotion: CGFloat = 0.01
    @State private var horizontalMotion: CGFloat = 0.035
    @State private var hoz: CGFloat = 0.0
    @State private var r: CGFloat = 0.0
    @State private var g: CGFloat = 0.0
    @State private var b: CGFloat = 0.0
    private let date = Date()
    
    var body: some View {
        VStack{
            TimelineView(.animation) {
                let time = date.timeIntervalSince1970 -  $0.date.timeIntervalSince1970
                
                Rectangle()
                //.aspectRatio(1, contentMode: .fit)
                    .colorEffect(ShaderLibrary.candleFlame(
                        .boundingRect,
                        .float(time),
                        .float(0.2),
                        .float2(0.1, 0.1),
                        .float3(0.1, 0.1, 0.1),
                        .float(hoz) // ← your horizontal push value
                    ))
                    .frame(width: .infinity, height: .infinity)
            }
        }
            
          
        
    }
}

#Preview("Flame") {
    Flame()
}
