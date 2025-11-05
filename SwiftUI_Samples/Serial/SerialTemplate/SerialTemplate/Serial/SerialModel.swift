//
//  SerialModel.swift
//  SerialTemplate
//
//  Created by Peter Rogers on 05/11/2025.
//

import Observation

@Observable class SerialModel {
    private var serial: SerialManager?
    var pixel:Float = 0.0
    
    
    func startSerial(){
        serial = SerialManager()
        observeSerial()
    }
    
    //MARK: Arduino function
    
    func receiveArduinoValues(values: [Int:Float]){
        if let v0 = values[1] {
           print("index 0 ->", v0)
           pixel = v0.mapped(from: 0.0, 1023.0, to: 0.0, 1.0)
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
