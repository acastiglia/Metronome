//
//  TimeSignature.swift
//  Metronome
//
//  Created by Anthony Castiglia on 10/30/26.
//

import Foundation

struct TimeSignature: Equatable, Hashable, Sendable {
    
    static let defaultTimeSignature = TimeSignature(beats: 4, noteValue: .quarter)
    static let range: ClosedRange<Int> = 1...32

    let beats: Int
    let noteValue: NoteValue

    enum NoteValue: Int {
        case whole   = 1
        case half    = 2
        case quarter = 4
        case eighth  = 8
    }

    init(beats: Int, noteValue: NoteValue) {
        self.beats = min(max(beats, Self.range.lowerBound), Self.range.upperBound)
        self.noteValue = noteValue
    }
}
