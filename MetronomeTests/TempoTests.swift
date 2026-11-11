import Testing
@testable import Metronome

struct TempoTests {
    @Test func keepsValueInsideRange() {
        #expect(Tempo(bpm: 96).bpm == 96)
    }

    @Test func clampsBelowRange() {
        #expect(Tempo(bpm: 1).bpm == Tempo.range.lowerBound)
    }

    @Test func clampsAboveRange() {
        #expect(Tempo(bpm: 1_000).bpm == Tempo.range.upperBound)
    }

    @Test func beatDurationAt120IsHalfSecond() {
        #expect(Tempo(bpm: 120).beatDuration == 0.5)
    }

    @Test(arguments: zip([44_100.0, 48_000.0, 96_000.0], [22_050, 24_000, 48_000]))
    func framesPerBeatAt120(sampleRate: Double, expectedFrames: Int) {
        #expect(Tempo(bpm: 120).framesPerBeat(sampleRate: sampleRate) == expectedFrames)
    }

    @Test func steppingUpAndDown() {
        #expect(Tempo(bpm: 100).stepped(by: 10).bpm == 110)
        #expect(Tempo(bpm: 100).stepped(by: -1).bpm == 99)
    }

    @Test func steppingClampsAtBounds() {
        #expect(Tempo(bpm: 295).stepped(by: 10).bpm == Tempo.range.upperBound)
        #expect(Tempo(bpm: 35).stepped(by: -10).bpm == Tempo.range.lowerBound)
    }
}
