//
//  TapTempo.swift
//  Metronome
//
//  Created by Anthony Castiglia on 11/16/26.
//

import Foundation

/// Computes a tempo in BPM from a rolling average of tap intervals.
///
/// Each call to ``tap()`` records the time elapsed since the previous tap and averages it over
/// the last ``minTaps`` taps, so the result tracks the most recent tapping speed rather than an
/// all-time average. ``tap()`` returns `nil` until at least ``minTaps`` taps have been recorded.
struct TapTempo {
    private static let minTaps = 4
    
    private var taps: [Double] = []
    private var tapIndex = 0
    private var previousTap: Date? = nil
    
    /// Records a tap and returns the current tempo estimate.
    ///
    /// - Returns: The estimated tempo in BPM, or `nil` until at least ``minTaps`` taps have been
    ///   recorded.
    mutating func tap() -> Int? {
        let now = Date.now
        if let lastTap = previousTap {
            let elapsed = now.timeIntervalSince(lastTap)
            if taps.count < Self.minTaps {
                taps.append(elapsed)
            } else {
                taps[tapIndex] = elapsed
                tapIndex = (tapIndex + 1) % Self.minTaps
            }
        }
        
        previousTap = now
        return computeTempo()
    }
    
    private func computeTempo() -> Int? {
        if taps.count < Self.minTaps {
            return nil
        }
        
        let secondsPerBeat: Double = taps.reduce(0, +) / Double(taps.count)
        let bpm = (60.0 / secondsPerBeat)
        return Int(bpm.rounded())
    }
}
