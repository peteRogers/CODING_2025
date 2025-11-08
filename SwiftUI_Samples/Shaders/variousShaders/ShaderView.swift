import SwiftUI
struct ShaderView: View {
    @State private var strength: CGFloat = 0
    
    var body: some View {
      
            Image(uiImage: UIImage(named: "tester")!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .distortionEffect(
                    
                    ShaderLibrary.pixellate(
                        .float(strength)
                    ),
                    maxSampleOffset: .zero
                )
            
                Slider(value: $strength, in: 1...200)
            .padding(50)
            
        
    }
}

#Preview {
    ShaderView()
}
