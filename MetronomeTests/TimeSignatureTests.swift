import Testing
@testable import Metronome

struct TimeSignatureTests {
    @Test func keepsValueInsideRange() {
        #expect(TimeSignature(beats: 3, noteValue: .quarter).beats == 3)
    }

    @Test func clampsBelowRange() {
        #expect(TimeSignature(beats: 0, noteValue: .quarter).beats == TimeSignature.range.lowerBound)
    }

    @Test func clampsAboveRange() {
        #expect(TimeSignature(beats: 1_000, noteValue: .quarter).beats == TimeSignature.range.upperBound)
    }

    @Test func defaultIsFourFour() {
        #expect(TimeSignature.defaultTimeSignature.beats == 4)
        #expect(TimeSignature.defaultTimeSignature.noteValue == .quarter)
    }

    @Test(arguments: [
        TimeSignature.NoteValue.whole,
        .half,
        .quarter,
        .eighth,
    ])
    func preservesNoteValue(_ noteValue: TimeSignature.NoteValue) {
        #expect(TimeSignature(beats: 4, noteValue: noteValue).noteValue == noteValue)
    }
}
