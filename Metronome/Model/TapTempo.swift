//
//  TapTempo.swift
//  Metronome
//
//  Created by Anthony Castiglia on 11/16/26.
//

import Foundation

struct TapTempo {
    
    let minTaps = 4
    
    var taps: [Double] = []
    var tapIndex = 0
    
    var preivousTap: Date? = .none
    
    mutating func tap() -> Int? {
        let now = Date.now
        if let lastTap = preivousTap {
            let elapsed = now.timeIntervalSince(lastTap)
            if (taps.count) < minTaps {
                taps.append(elapsed)
            } else {
                taps[tapIndex] = elapsed
                tapIndex = (tapIndex + 1) % minTaps
            }
        }
        
        preivousTap = now
        return computeTempo()
    }
    
    private func computeTempo() -> Int? {
        if (taps.count < minTaps) {
            return .none
        }
        
        let secondsPerBeat: Double = taps.reduce(0, +) / Double(taps.count)
        let bpm = (60.0 / secondsPerBeat)
        return Int(bpm.rounded())
    }
}
