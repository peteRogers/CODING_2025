//
//  ContentView.swift
//  mapExp
//
//  Created by Peter Rogers on 11/11/2025.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State var serial = SerialModel()
    @State var zoom = 100.0
    @State private var cam = MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 51.4613, longitude: -0.0106),
        distance: 800,
        heading: 0,
        pitch: 80
    )
    @State private var cameraPositionA: MapCameraPosition = .automatic
    var body: some View {
        VStack {
            Map(position: $cameraPositionA) {
                
                // You can add content here, e.g. UserAnnotation(), Marker, etc.
                
            }
            .onAppear {
                serial.startSerial()
                cameraPositionA = .camera(cam)
            }
            .mapStyle(.imagery(elevation: .realistic))
            .onChange(of: serial.pixel) { _, newValue in
                cam.heading = Double(newValue)
                cameraPositionA = .camera(cam)
            }
            
            Slider(value: $zoom, in: 0...360)
                .padding(.horizontal, 200)
        }
    }
}

#Preview {
    ContentView()
}
