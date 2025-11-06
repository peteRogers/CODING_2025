## Camera to detect body landmarks
```swift
import SwiftUI

struct ContentView: View {
   
	@ObservedObject var pointsModel = PointsModel()
    var body: some View {
        ZStack{
            CameraView{
				pointsModel.visionPoints = $0
            }.overlay(
				PointsOverlay(with: pointsModel.currentPoints)
                    .foregroundColor(.red)
              )
              .edgesIgnoringSafeArea(.all)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

```
---
