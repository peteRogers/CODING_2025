## Animation with TimelineView
```swift
        ZStack {
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let pulsate = abs(sin(time))
                let angle = pulsate * 360.0
                ZStack{
                    Rectangle()
                        .fill(Color(hue: pulsate, saturation: 1, brightness: 1))
                        .cornerRadius(pulsate*400)
                    Text("Hello, world!")
                        .fontWidth(.expanded)
                        .fontWeight(.bold)
                        .font(.system(size: pulsate*100))
                        .rotationEffect(.degrees(angle*10))
                        .foregroundStyle(Color(hue: 1-pulsate, saturation: 0.5, brightness: 1))
                }
            }
        }
        .padding()
        .ignoresSafeArea(edges: .all)
```
---
## 🗺️ Mapping 

```swift
    @State private var cameraPositionA: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 51.4613, longitude: -0.0106), // Lewisham
            distance: 100,
            heading: 0,
            pitch: 80
        )
    )
```

```swift
            Map(position: $cameraPositionA) {
                // You can add content here, e.g. UserAnnotation(), Marker, etc.
                
            }.mapStyle(.imagery(elevation: .realistic))
```
## Mapping with Animation
```swift
        TimelineView(.animation) { timeline in
            // Compute a smooth, looping time value
            let time = timeline.date.timeIntervalSinceReferenceDate
            let spinDeg = (time * 12).truncatingRemainder(dividingBy: 360)
            // Make the camera glide in a tiny circle around Lewisham
            let radius = 0.0008
            let dx = radius * cos(time * 0.008)
            let dy = radius * sin(time * 0.008)
            let center = CLLocationCoordinate2D(latitude: 51.4613 + dy, longitude: -0.0106 + dx)
            let camera = MapCamera(
                centerCoordinate: center,
                distance: 1000,   // zoom level (meters). Increase to zoom out
                heading: spinDeg,
                pitch: 80)
            ZStack {
                Map(position: .constant(.camera(camera))) {
                    // You can add content here, e.g. Marker(), UserAnnotation(), etc.
                }
                .mapStyle(.imagery(elevation: .realistic))
                .allowsHitTesting(false)
                .disabled(true)
            }
        }.ignoresSafeArea(edges: .all)
```
---
## RealityView
```swift
 RealityView { content in
            // Add a simple 3D object (a white sphere)
            let material = SimpleMaterial(color: .orange, isMetallic: true)
                        
            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.5))
            sphere.model?.materials = [material]
            content.add(sphere)
        }.realityViewCameraControls(.orbit)
```
---
```swift
         RealityView { content in
                    let mesh = MeshResource.generateSphere(radius: 50)
                    var mat = UnlitMaterial()
                    if let tex = try? await TextureResource(named: "sky.exr") {
                        mat.color = .init(texture: .init(tex))
                    }
                    mat.faceCulling = .front
                    let dome = ModelEntity(mesh: mesh, materials: [mat])
                    content.add(dome)
                }
                .realityViewCameraControls(.orbit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            }
```

---
```swift
//
//  RKTemplateView.swift
//  RealityView
//
//  Created by Peter Rogers on 21/10/2025.
//

import SwiftUI
import RealityKit

struct ObjectView: View {
    @State var posY:Float = 2.0
    @State private var cameraEntity: PerspectiveCamera?
    @State private var modelEntity: ModelEntity?
    @State private var rotationAngle: Float = 0.0
    @State private var rotSpeed: Float = 0.0
    
    var body: some View {
        ZStack{
            RealityView { content in
                let anchor = AnchorEntity(world: .init(1))
                content.add(anchor)
                let camera = PerspectiveCamera()
                camera.position = [0, posY, 3]
                camera.look(at: [0, 0, 0], from: camera.position, relativeTo: nil)
                anchor.addChild(camera)
                cameraEntity = camera
                if let model = try? await ModelEntity(named: "shell-full") {
                    model.scale = [50, 50, 50]
                    model.position = [0, 0, 0]
                    anchor.addChild(model)
                    modelEntity = model   // ✅ store the reference
                    DispatchQueue.main.async {
                        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
                            rotationAngle += rotSpeed
                            if let model = modelEntity {
                                model.orientation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
                            }
                        }
                    }
                }
            } update: { content in
                if let camera = cameraEntity {
                    camera.position = [0, posY, 3]
                    camera.look(at: [0, 0, 0], from: camera.position, relativeTo: nil)
                }
            }
            .background(Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack{
                Spacer()
                Slider(value: $posY, in: -4...4)
                    .padding(.horizontal, 100)
                    .padding(.bottom, 20)
                Slider(value: $rotSpeed, in: -0.1...0.1)
                    .padding(.horizontal, 100)
                    .padding(.bottom, 50)
                
            }
        }.ignoresSafeArea()
    }
}

#Preview { ObjectView() }

```
---
## AudioKit flanger
```swift
flanger = Flanger(chorus!)
            flanger?.depth = 1
            flanger?.dryWetMix = 1
            mixer.addInput(flanger!)
```
func to set params

```swift
func setFlanger(value: Float) {
        guard let flanger = flanger else { return } // <-- prevent invalid parameter call
        print(value)
        flanger.feedback = value
        flanger.frequency = value * 10.0
    }
```
attached to contentView to be able to send the arduino value
```swift
.onChange(of: serial.latestValuesFromArduino[0]) { _, newValue in
            if let val = newValue{
                simpleAudio.setFlanger(value: val.mapped(from: 0, 1200, to: 1.0, 0.0))
            }
        }
```
