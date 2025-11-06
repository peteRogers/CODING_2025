# Animation with TimelineView
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

# 🌀 DistortedTextColumn

**`DistortedTextColumn`** is a SwiftUI view that renders multiline text in a fixed-width column using **Core Text** and **Canvas**, then applies a smooth **sine-wave distortion** to create a living, rippling text effect.

It combines the precision of Core Text layout with the power of GPU-accelerated SwiftUI drawing.

---

## ✨ Features
- Automatic text wrapping within a fixed column width  
- Animated sine-wave distortion driven by time  
- Fully configurable parameters for amplitude, frequency, speed, font size, and color  
- Uses Core Text + SwiftUI `Canvas` for efficient rendering  
- Looks great in posters, generative art, and motion UI

---

## ⚙️ Parameters

| Parameter | Type | Description |
|------------|------|-------------|
| **`text`** | `String` | The text to display. Can be multiline — automatically wraps to fit the column width. |
| **`amplitude`** | `CGFloat` | Vertical displacement of the sine wave (in points). Larger values produce a stronger wobble. |
| **`frequency`** | `CGFloat` | Controls how many waves appear across the text horizontally. Higher = tighter waves. |
| **`speed`** | `CGFloat` | Speed of wave motion. Increasing makes the wave animate faster. |
| **`columnWidth`** | `CGFloat` | Fixed width (in points) of the column; text wraps automatically at this width. |
| **`fontSize`** | `CGFloat` | Size of the rendered text. |
| **`fillColor`** | `Color` | Color used to fill the text shapes. |

---

## 🧩 Example Usage

```swift
DistortedTextColumn(
    text: """
    This is a sample multiline text that wraps inside a fixed column width.
    It ripples and moves using a sine-wave animation.
    """ ,
    amplitude: 40,
    frequency: 0.03,
    speed: 2,
    columnWidth: 300,
    fontSize: 60,
    fillColor: .black
)
.frame(maxWidth: .infinity, maxHeight: .infinity)
.background(Color.white)
```

---

## 🪄 How It Works
`DistortedTextColumn`:
1. Uses **Core Text** to generate properly wrapped glyph paths.  
2. Applies a **time-based sine offset** to every path element via a `distortPath` function.  
3. Draws the result in a SwiftUI **Canvas** for smooth GPU rendering.  
4. Animates continuously using a `TimelineView(.animation)`.

---

## 💡 Tips
- For subtle motion, use low amplitude (10–30) and low frequency (0.01–0.03).  
- For liquid or surreal effects, increase amplitude and lower frequency.  
- Combine with gradient fills or masks for more experimental visuals.

---

## 🎥 LoopingVideoView

`LoopingVideoView` is a lightweight SwiftUI wrapper around **AVPlayer** that lets you play looping video content inside your app — ideal for backgrounds, previews, or ambient motion elements in your UI.

It automatically:
- Loads and plays a local or remote video file.
- Loops the video seamlessly by restarting playback when it finishes.
- Supports corner radius, aspect fill, and layering options.

### ⚙️ Parameters

| Parameter | Type | Description |
|------------|------|-------------|
| **`player`** | `AVPlayer` | The AVPlayer instance to play. Use a shared or preloaded player to avoid restarts. |
| **`cornerRadius`** | `CGFloat` | Optional radius for rounding the video’s corners. |
| **`videoGravity`** | `AVLayerVideoGravity` | Controls how the video scales within its layer (`.resizeAspectFill`, `.resizeAspect`, etc.). Default is `.resizeAspectFill`. |

### 🧩 Example Usage

```swift
import AVKit

struct ExampleView: View {
    private let player = AVPlayer(url: Bundle.main.url(forResource: "sample", withExtension: "mp4")!)

    var body: some View {
         LoopingVideoView(url: demoVideoURL!, cornerRadius: 1)
                        .aspectRatio(1, contentMode: .fit)
    }
}
```
---
## 🗺️ Mapping 

```swift
    @State private var cameraPositionB: MapCameraPosition = .camera(
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
