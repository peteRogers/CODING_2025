//
//  MyMapView.swift
//  exp
//
//  Created by Peter Rogers on 15/01/2026.
//

import SwiftUI
import MapKit

struct MyMapView: View {
    @State private var cameraPositionA: MapCameraPosition = .camera(
            MapCamera(
                centerCoordinate: CLLocationCoordinate2D(latitude: 51.4613, longitude: -0.0106), // Lewisham
                distance: 200,
                heading: 0,
                pitch: 80
            )
        )
    var body: some View {
        VStack{
            Map(position: $cameraPositionA) {
                // You can add content here, e.g. UserAnnotation(), Marker, etc.
                
            }.mapStyle(.imagery(elevation: .realistic))
        }
    }
}

#Preview {
    MyMapView()
}

