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
