//
//  SerialModel.swift
//  SerialTemplate
//
//  Created by Peter Rogers on 05/11/2025.
//

import Observation
import Foundation

@Observable class SerialModel {
    private var serial: SerialManager?
    var pixel:Float = 0.0001
    var timer:Timer?

    func startSerial(){
        serial = SerialManager()
        observeSerial()
    }
    
    //MARK: Arduino function
    
    func receiveArduinoValues(values: [Int:Float]){
        if let v0 = values[0]{
           print("index 0 ->", v0)
            let p = v0.mapped(from: 0.0, 50000, to: 0.0, 1.0)
            if(p > pixel){
                pixel = v0.mapped(from: 0.0, 50000, to: 0.0, 1.0)
                startRundownTimer()
            }
        }
    }
    
    func startRundownTimer(){
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0,  repeats: true){[weak self] _ in
            if(self!.pixel > 0.001){
                self!.pixel -= self!.pixel / 300.0
            }else{
                self!.pixel = 0.001
                self?.timer?.invalidate()
            }
        }
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
