//
//  SerialModel.swift
//  SerialTemplate
//
//  Created by Peter Rogers on 05/11/2025.
//

import Observation

@Observable class SerialModel {
    private var serial: SerialManager?
    var v1:Float = 0.26
    var v2:Float = 0.60
    var v3:Float = 0.3
    var v4:Float = 1.5
    
    
    func startSerial(){
        serial = SerialManager()
        observeSerial()
    }
    
    //MARK: Arduino function
    
    func receiveArduinoValues(values: [Int:Float]){
        if let value1 = values[1] {
           // print(value1)
            v3 = value1.mapped(from: 0, 1000, to: 0.3, 0.0)
            v4 = value1.mapped(from: 0, 1000, to: 1.5, 0.0)
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
