## Here is the code for 2025 Coding

### Arduino code to send value to computer
```arduino
void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);

}

void loop() {
  int sensor = analogRead(A0);
  Serial.print("0>");
  Serial.print(sensor);
  Serial.println(">");
  delay(10);
}

```
### Pixellate shader code snippet
```swift
            Image("stainWindow")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .distortionEffect(
                    ShaderLibrary.pixellate(
                        .float(serialModel.pixel * 100)
                    ),
                    maxSampleOffset: .zero
                )
```
### Wave shader code snippet
```swift
            TimelineView(.animation) { timeline in
                // Drive time from the system's animation timeline
                let time = start.distance(to: timeline.date)
                Image("stainWindow")
                    .resizable()
                    .scaledToFit()
                    .padding(25)
                    .background(.white)
                    .drawingGroup()
                    .distortionEffect(ShaderLibrary.water(
                        .float2(1+serialModel.pixel*100, 1+serialModel.pixel*100),
                        .float(time),
                        .float(100),
                        .float(10),
                        .float(2)
                        
                    ),maxSampleOffset: .zero
                    )
            }
```
### Color channel shader
```swift
            Image("stainWindow")
                .resizable()
                .scaledToFit()
                .padding(20)
                .layerEffect(ShaderLibrary.colorPlanes(
                    .float2(serialModel.pixel * 100, serialModel.pixel*100)
                    
                    
                ),maxSampleOffset: .zero
                )
```
---
### AudioKit reversing sound
```swift
//
//  SimpleAudioControl.swift
//  AudioKit_Sampler
//
//  Created by Peter Rogers on 21/10/2025.
//

import AudioKit
import AudioKitEX
import AVFoundation
import SoundpipeAudioKit
import DunneAudioKit
import Observation

@Observable class SimpleAudioControl {
    private var serial: SerialManager?
    private let engine = AudioEngine()
    private let mixer = Mixer()
    private let player = AudioPlayer()
    private var reverser:Reverser?
   
    var playerVolume: Float = 1.0 {
        didSet {
            reverser!.setRate(rate:playerVolume)
        }
    }

    func setup() {
        do {
            reverser = Reverser(fileName: "tropBird.wav")
            mixer.addInput(reverser!.getMixer())
            engine.output = mixer
            try engine.start()
            print("🎧 Engine started.")
            freopen("/dev/null", "w", stderr)
        } catch {
            print("❌ Failed to start engine: \(error)")
        }
        serial = SerialManager()
        observeSerial()
    }
    
    
    //MARK: Arduino function

    func receiveArduinoValues(values: [Int:Float]){
        if let v0 = values[0] {
            print("index 0 ->", v0)
            playerVolume = v0.mapped(from: 0.0, 1023.0, to: -1.0, 1.0)
        }
    }

    //MARK: controlling functions
    
    func play() {
        print("trying to play")
        reverser!.stop()
        reverser!.play()
    }

    func stop() {
       print("trying to stop")
       reverser!.stop()
    }
    
    deinit{
        reverser!.stop()
        //reverser!.detach()
        engine.stop()
        print("🛑 Engine stopped.")
    }
    
    func stopEngine() {
        engine.stop()
        print("🛑 Engine stopped.")
    }
}


extension SimpleAudioControl{
    func observeSerial() {
        guard let serial else { return }
        Task { @MainActor in
            for await values in serial.updates {
                self.receiveArduinoValues(values: values)
            }
        }
    }
}
```
