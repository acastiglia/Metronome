import AVFoundation
import Testing
@testable import Metronome

struct ClickSynthesizerTests {
    @Test func rejectsZeroSampleRate() {
        #expect(ClickSynthesizer(sampleRate: 0) == nil)
    }

    @Test func producesMonoFloatFormat() throws {
        let synthesizer = try #require(ClickSynthesizer(sampleRate: 48_000))
        #expect(synthesizer.format.channelCount == 1)
        #expect(synthesizer.format.commonFormat == .pcmFormatFloat32)
        #expect(synthesizer.format.sampleRate == 48_000)
    }

    @Test(arguments: [44_100.0, 48_000.0, 96_000.0], [30, 120, 300])
    func bufferIsExactlyOneMeasureLong(sampleRate: Double, bpm: Int) throws {
        let synthesizer = try #require(ClickSynthesizer(sampleRate: sampleRate))
        let tempo = Tempo(bpm: bpm)
        let timeSignature = TimeSignature(beats: 3, noteValue: .quarter)
        let buffer = synthesizer.measureBuffer(for: tempo, timeSignature: timeSignature)
        #expect(Int(buffer.frameLength) == tempo.framesPerBeat(sampleRate: sampleRate) * timeSignature.beats)
    }

    @Test func accentClickIsAudibleAtStartOfMeasure() throws {
        let synthesizer = try #require(ClickSynthesizer(sampleRate: 48_000))
        let samples = Self.samples(
            of: synthesizer.measureBuffer(for: Tempo(bpm: 120), timeSignature: .defaultTimeSignature)
        )
        let firstMillisecond = samples.prefix(48)
        let peak = firstMillisecond.map(abs).max() ?? 0
        #expect(peak > 0.5)
        #expect(peak <= ClickSynthesizer.peakAmplitude)
    }

    @Test func regularClicksAreAudibleAtStartOfEachSubsequentBeat() throws {
        let synthesizer = try #require(ClickSynthesizer(sampleRate: 48_000))
        let tempo = Tempo(bpm: 120)
        let timeSignature = TimeSignature.defaultTimeSignature
        let framesPerBeat = tempo.framesPerBeat(sampleRate: 48_000)
        let samples = Self.samples(of: synthesizer.measureBuffer(for: tempo, timeSignature: timeSignature))

        for beat in 1..<timeSignature.beats {
            let beatStart = beat * framesPerBeat
            let firstMillisecond = samples[beatStart..<(beatStart + 48)]
            let peak = firstMillisecond.map(abs).max() ?? 0
            #expect(peak > 0.5)
        }
    }

    @Test func accentClickDiffersFromRegularClick() throws {
        let synthesizer = try #require(ClickSynthesizer(sampleRate: 48_000))
        let tempo = Tempo(bpm: 120)
        let timeSignature = TimeSignature.defaultTimeSignature
        let framesPerBeat = tempo.framesPerBeat(sampleRate: 48_000)
        let samples = Self.samples(of: synthesizer.measureBuffer(for: tempo, timeSignature: timeSignature))

        let accentClick = Array(samples[0..<synthesizer.clickFrameCount])
        let regularClick = Array(samples[framesPerBeat..<(framesPerBeat + synthesizer.clickFrameCount)])
        #expect(accentClick != regularClick)
    }

    @Test func clickDecaysBeforeBeatEnds() throws {
        let synthesizer = try #require(ClickSynthesizer(sampleRate: 48_000))
        let samples = Self.samples(
            of: synthesizer.measureBuffer(for: Tempo(bpm: 120), timeSignature: .defaultTimeSignature)
        )
        let lastMillisecondOfClick = samples[(synthesizer.clickFrameCount - 48)..<synthesizer.clickFrameCount]
        #expect(lastMillisecondOfClick.allSatisfy { abs($0) < 0.01 })
    }

    @Test func remainderOfEachBeatIsSilent() throws {
        let synthesizer = try #require(ClickSynthesizer(sampleRate: 48_000))
        let tempo = Tempo(bpm: 120)
        let timeSignature = TimeSignature.defaultTimeSignature
        let framesPerBeat = tempo.framesPerBeat(sampleRate: 48_000)
        let samples = Self.samples(of: synthesizer.measureBuffer(for: tempo, timeSignature: timeSignature))

        for beat in 0..<timeSignature.beats {
            let beatStart = beat * framesPerBeat
            let silentRange = (beatStart + synthesizer.clickFrameCount)..<(beatStart + framesPerBeat)
            #expect(samples[silentRange].allSatisfy { $0 == 0 })
        }
    }

    private static func samples(of buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channel = buffer.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
    }
}
