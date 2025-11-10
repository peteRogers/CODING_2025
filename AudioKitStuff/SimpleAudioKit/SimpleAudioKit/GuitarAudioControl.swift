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

@Observable class GuitarAudioControl {
    private var serial: SerialManager?
    var mixer:Mixer = Mixer()
    private let engine = AudioEngine()
    var pluckedStrings:[PluckedString] = []
    private var prevVals:[Int: Float] = [:]
    
    var playerVolume: Float = 1.0 {didSet {
            mixer.volume = playerVolume
        }
    }
    
    func setup() {
        let scale = [60, 62, 63, 65, 67, 68, 71]
        for key in scale{
            let p = PluckedString()
            p.frequency = key.midiNoteToFrequency()
            pluckedStrings.append(p)
            mixer.addInput(p)
        }
        engine.output = mixer
        freopen("/dev/null", "w", stderr)
        do {
            try engine.start()
        }catch let err {
            Log(err)
        }
        
                serial = SerialManager()
                observeSerial()
    }
    
    
    //MARK: Arduino function
    
    func receiveArduinoValues(values: [Int:Float]){
        let differences = compare(old: prevVals, new: values)
        prevVals = values
        for (key, diff) in differences {
            if(diff.new == 1){
                print(key)
               
                if pluckedStrings.indices.contains(key) {
                    pluckedStrings[key].trigger()
                } else {
                    print("⚠️ Out-of-range key: \(key)")
                }
               
            }
        }
    }
    
    func play(){
        
    }
    
    func stop(){
        
    }
    
    func compare(old: [Int: Float], new: [Int: Float]) -> [Int: (old: Float?, new: Float?)] {
        var changed: [Int: (old: Float?, new: Float?)] = [:]
        
        // Combine all unique keys from both dictionaries
        let allKeys = Set(old.keys).union(new.keys)
        
        for key in allKeys {
            let oldVal = old[key]
            let newVal = new[key]
            
            // Detect additions, removals, or value changes
            if oldVal == nil && newVal != nil {
                changed[key] = (old: nil, new: newVal)       // Added
            } else if newVal == nil && oldVal != nil {
                changed[key] = (old: oldVal, new: nil)       // Removed
            } else if oldVal != newVal {
                changed[key] = (old: oldVal, new: newVal)    // Updated
            }
        }
        
        return changed
    }
    
    //MARK: controlling functions
    
    deinit{
        engine.stop()
        print("🛑 Engine stopped.")
    }
    
    func stopEngine() {
        engine.stop()
        print("🛑 Engine stopped.")
    }
    
    func observeSerial() {
        guard let serial else { return }
        Task { @MainActor in
            for await values in serial.updates {
                self.receiveArduinoValues(values: values)
            }
        }
    }
}


