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

