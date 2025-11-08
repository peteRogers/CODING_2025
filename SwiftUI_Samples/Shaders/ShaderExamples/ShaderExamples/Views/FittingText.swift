//
//  FittingText.swift
//  ShaderExamples
//
//  Created by Peter Rogers on 07/11/2025.
//

import SwiftUI

struct FittingTextCanvas: View {
    var text: String = "SHADERS"

    var body: some View {
        Canvas { context, size in
            // 1) Build and resolve text at a large base size
            let baseText = Text(text)
                .font(.system(size: 100, weight: .bold))

            let resolved = context.resolve(baseText)

            // 2) Measure natural (unconstrained) size
            let natural = resolved.measure(
                in: size).width + 50
            

            //guard natural.width > 0 else { return }

            // 3) Compute scale so natural width -> canvas width
            let scale = size.width / natural

            // 4) Center, then scale, then draw centered
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.scaleBy(x: scale, y: scale)
            context.draw(resolved, at: .zero, anchor: .center)
        }
    }
}

#Preview {
    FittingTextCanvas(text: "Fitting Text Example")
        .frame(width: 300, height: 100)
        .background(Color.black)
}
