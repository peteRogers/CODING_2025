//
//  SimpleAudioControl.swift
//  AudioKit_Sampler
//
//  Created by Peter Rogers on 21/10/2025.
//

import AudioKit
import AVFoundation
import Observation
import SoundpipeAudioKit

@Observable class AudioController {
    private let engine = AudioEngine()
    private let mixer = Mixer()
    private let player = AudioPlayer()
    private var pitch:PitchShifter!
   
    var playerVolume: Float = 1.0 {
        didSet {
            player.volume = playerVolume
        }
    }
    
    var pitchAmount: Float = 1.0 {
        didSet {
            let shift = pitchAmount.mapRange(inMin: 0.0, inMax: 1023.0, outMin: -10.0, outMax: 10.0)
            pitch.shift = shift
        }
    }
 
    func setup() {
        do {
            try player.load(url: Bundle.main.url(forResource: "tropBird", withExtension: "wav")!, buffered: true)
            player.isLooping = true
            pitch = PitchShifter(player)
            mixer.addInput(pitch)
            engine.output = mixer
            try engine.start()
            print("🎧 Engine started.")
            freopen("/dev/null", "w", stderr)
        } catch {
            print("❌ Failed to start engine: \(error)")
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


extension Float {
    /// Maps `self` from an input range to an output range (clamped to input range).
    func mapRange(inMin: Float, inMax: Float, outMin: Float, outMax: Float) -> Float {
        // Avoid divide-by-zero if inMin == inMax
        let inRange = inMax - inMin
        guard inRange != 0 else { return outMin }

        let clampedValue = min(max(self, inMin), inMax)
        let outRange = outMax - outMin
        let scaled = (clampedValue - inMin) / inRange
        return outMin + (scaled * outRange)
    }
}
