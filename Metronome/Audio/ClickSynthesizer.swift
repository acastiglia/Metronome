import AVFoundation

/// Generates metronome audio in code, so the app ships no audio assets.
///
/// Each measure buffer is a sequence of short sine-burst clicks, one per beat, each followed by
/// silence for the remainder of that beat. The first beat of the measure is accented with a
/// higher-pitched click so the downbeat is audible.
struct ClickSynthesizer {
    static let accentFrequency = 1_800.0
    static let regularFrequency = 1_200.0
    static let clickDuration: TimeInterval = 0.020
    static let peakAmplitude: Float = 0.8
    static let finalAmplitudeRatio = 0.001

    let format: AVAudioFormat

    /// Creates a synthesizer producing mono, 32-bit float buffers at `sampleRate`.
    ///
    /// Returns `nil` when `sampleRate` cannot describe a valid audio format, for example when
    /// there is no output device and the engine reports a sample rate of zero.
    init?(sampleRate: Double) {
        guard sampleRate > 0,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return nil
        }
        self.format = format
    }

    var sampleRate: Double {
        format.sampleRate
    }

    /// The number of frames occupied by the audible click at the start of each beat.
    var clickFrameCount: Int {
        Int((sampleRate * Self.clickDuration).rounded())
    }

    /// Returns a buffer exactly one measure long for `tempo` and `timeSignature`: an accented
    /// click at frame zero, followed by a regular click at the start of every other beat.
    func measureBuffer(for tempo: Tempo, timeSignature: TimeSignature) -> AVAudioPCMBuffer {
        let framesPerBeat = tempo.framesPerBeat(sampleRate: sampleRate)
        let frameCount = framesPerBeat * timeSignature.beats
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)),
              let channel = buffer.floatChannelData?[0] else {
            preconditionFailure("A mono float format with a non-zero frame count always yields a buffer")
        }
        buffer.frameLength = AVAudioFrameCount(frameCount)

        let samples = UnsafeMutableBufferPointer(start: channel, count: frameCount)
        let audibleFrameCount = min(clickFrameCount, framesPerBeat)
        for beat in 0..<timeSignature.beats {
            let beatStart = beat * framesPerBeat
            let frequency = beat == 0 ? Self.accentFrequency : Self.regularFrequency
            for frame in 0..<framesPerBeat {
                samples[beatStart + frame] = frame < audibleFrameCount
                    ? clickSample(atFrame: frame, frequency: frequency)
                    : 0
            }
        }
        return buffer
    }

    private func clickSample(atFrame frame: Int, frequency: Double) -> Float {
        let time = Double(frame) / sampleRate
        let envelope = pow(Self.finalAmplitudeRatio, time / Self.clickDuration)
        let wave = sin(2 * .pi * frequency * time)
        return Self.peakAmplitude * Float(envelope * wave)
    }
}
