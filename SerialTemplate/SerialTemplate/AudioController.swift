//
//  SimpleAudioControl.swift
//  AudioKit_Sampler
//
//  Created by Peter Rogers on 21/10/2025.
//

import AudioKit
import AVFoundation
import Observation

@Observable class AudioController {
    private let engine = AudioEngine()
    private let mixer = Mixer()
    private let player = AudioPlayer()
   
    var playerVolume: Float = 1.0 {
        didSet {
            player.volume = playerVolume
        }
    }
 
    func setup() {
        do {
            try player.load(url: Bundle.main.url(forResource: "tropBird", withExtension: "wav")!, buffered: true)
            player.isLooping = true
            mixer.addInput(player)
            engine.output = mixer
            try engine.start()
            print("🎧 Engine started.")
            freopen("/dev/null", "w", stderr)
        } catch {
            print("❌ Failed to start engine: \(error)")
        }
    }
    
    
    //MARK: Arduino function

    func receiveArduinoValues(values: [Int:Float]){
        if let v0 = values[1] {
            print("index 0 ->", v0)
            playerVolume = v0.mapped(from: 0.0, 1023.0, to: 0.0, 1.0)
        }
    }

    //MARK: controlling functions
    
    func play() {
        print("trying to play")
        player.stop()
        player.play()
    }

    func stop() {
       print("trying to stop")
       player.stop()
    }
    
    deinit{
        player.stop()
        player.detach()
        engine.stop()
        print("🛑 Engine stopped.")
    }
    
    func stopEngine() {
        engine.stop()
        print("🛑 Engine stopped.")
    }
}


