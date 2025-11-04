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

@Observable
final class SimpleAudioControl {
    private var serial: SerialManager?
    private let engine = AudioEngine()
    private let mixer = Mixer()
    private let player = AudioPlayer()
    //shared variables
    var playerVolume: Float = 0.0 {didSet { player.volume = playerVolume } }

    func setup() {
        print("starting audio engine")
        //serial = SerialManager()
        //observeSerial()
        do {
            //loading player
            try player.load(url: Bundle.main.url(forResource: "tropBird", withExtension: "wav")!, buffered: true)
            player.isLooping = true
            //putting into the mixer
            mixer.addInput(player)
            engine.output = mixer
            //starting the audio engine
            try engine.start()
            print("🎧 Engine started.")
            //freopen("/dev/null", "w", stderr)
        } catch {
            print("❌ Failed to start engine: \(error)")
        }
    }

    func receiveArduinoValues(values: [Int:Float]){
        if let v0 = values[1] {
            print("index 0 ->", v0)
            playerVolume = v0.mapped(from: 0.0, 1023.0, to: 0.0, 1.0)
        }
    }

    func play() {
        print("trying to play")
        player.stop()
        player.play()
    }

    func stop() {
       print("trying to stop")
       player.stop()
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
