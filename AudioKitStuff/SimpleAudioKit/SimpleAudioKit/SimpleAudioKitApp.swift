//
//  SimpleAudioKitApp.swift
//  SimpleAudioKit
//
//  Created by Peter Rogers on 22/10/2025.
//

import SwiftUI

@main
struct SimpleAudioKitApp: App {
//    @Environment(\.scenePhase) private var scenePhase
//    @State private var serial = SerialManager()
//    
//    var body: some Scene {
//        WindowGroup {
//            SimpleContentView(serial: serial)
//        }
//        .onChange(of: scenePhase) { _, newPhase in
//            if newPhase == .background || newPhase == .inactive {
//                print("🛑 App moving to background — closing serial.")
//                serial.disconnect()
//            }
//        }
//    }
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                print("🛑 App moving to background — closing serial.")
                
            }
        }
    }
}
