//
//  Reverser.swift
//  SimpleAudioKit
//
//  Created by Peter Rogers on 05/11/2025.
//

import AudioKit
import AudioKitEX
import AVFoundation
import SoundpipeAudioKit
import DunneAudioKit


class Reverser{
    private var mixer:Mixer!
    private var forwardPlayer:AudioPlayer!
    private var reversePlayer:AudioPlayer!
    private var rateForward: VariSpeed?
    private var rateReverse: VariSpeed?
    private var isForewardPlaying: Bool = true
    
    init(fileName: String){
        
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            fatalError("File not found: \(fileName)")
        }
        forwardPlayer = AudioPlayer(url: fileURL)
        reversePlayer = AudioPlayer(url: fileURL)
        forwardPlayer.isBuffered = true
        reversePlayer.isBuffered = true
        reversePlayer.isReversed = true
        forwardPlayer.isLooping = true
        reversePlayer.isLooping = true
        rateForward = VariSpeed(forwardPlayer)
        rateReverse = VariSpeed(reversePlayer)
        mixer = Mixer(rateForward!, rateReverse!)
    }
    
    func getMixer() -> Mixer{
        return mixer
    }
    
    func play(){
        reversePlayer.stop()
        forwardPlayer.stop()
        reversePlayer.play()
        forwardPlayer.play()
    }
    
    func stop(){
        reversePlayer.stop()
        forwardPlayer.stop()
    }
    
    func setRate(rate:Float){
        if(rate < 0){
            forwardPlayer.volume = 0.0
            reversePlayer.volume = 1.0
        }else{
            isForewardPlaying = true
            forwardPlayer.volume = 1.0
            reversePlayer.volume = 0.0
        }
        rateForward?.rate = abs(rate)
        rateReverse?.rate = abs(rate)
       //print("\(forwardPlayer.currentTime) : \(reversePlayer.currentTime)")
    }
}
