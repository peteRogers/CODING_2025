//
//  Flame_SerialApp.swift
//  Flame_Serial
//
//  Created by Peter Rogers on 17/10/2025.
//

import SwiftUI

@main
struct Flame_SerialApp: App {
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
