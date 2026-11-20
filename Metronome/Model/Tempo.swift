import Foundation

/// A metronome tempo in beats per minute, always clamped to ``Tempo/range``.
struct Tempo: Equatable, Hashable, Sendable {
    static let range: ClosedRange<Int> = 30...300
    static let defaultTempo = Tempo(bpm: 120)

    let bpm: Int

    init(bpm: Int) {
        self.bpm = min(max(bpm, Self.range.lowerBound), Self.range.upperBound)
    }

    /// The time between consecutive beats, in seconds.
    var beatDuration: TimeInterval {
        60.0 / Double(bpm)
    }

    /// The number of audio frames in one beat at the given sample rate, rounded to the nearest frame.
    func framesPerBeat(sampleRate: Double) -> Int {
        Int((sampleRate * beatDuration).rounded())
    }

    /// Returns a new tempo offset by `delta` BPM, clamped to ``Tempo/range``.
    func stepped(by delta: Int) -> Tempo {
        Tempo(bpm: bpm + delta)
    }
}
