import AVFoundation
import Testing
@testable import Metronome

@MainActor
struct MetronomeModelTests {
    private static func makeEngine(sampleRate: Double) throws -> AVAudioEngine {
        let engine = AVAudioEngine()
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1))
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4_096)
        return engine
    }

    private static func render(_ totalFrameCount: Int, on engine: AVAudioEngine) throws {
        var remainingFrameCount = totalFrameCount
        while remainingFrameCount > 0 {
            let frameCount = min(remainingFrameCount, Int(engine.manualRenderingMaximumFrameCount))
            let buffer = try #require(
                AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: AVAudioFrameCount(frameCount))
            )
            _ = try engine.renderOffline(AVAudioFrameCount(frameCount), to: buffer)
            remainingFrameCount -= frameCount
        }
    }

    private static func makeIsolatedStore() -> TempoStore {
        TempoStore(defaults: UserDefaults(suiteName: "MetronomeModelTests.\(UUID().uuidString)")!)
    }

    private static func makeIsolatedTimeSignatureStore() -> TimeSignatureStore {
        TimeSignatureStore(defaults: UserDefaults(suiteName: "MetronomeModelTests.\(UUID().uuidString)")!)
    }

    @Test func startSetsIsRunning() throws {
        let model = MetronomeModel(player: ClickPlayer(engine: try Self.makeEngine(sampleRate: 48_000)), store: Self.makeIsolatedStore())

        model.start()

        #expect(model.isRunning)
        #expect(model.errorMessage == nil)
    }

    @Test func stopClearsIsRunning() throws {
        let model = MetronomeModel(player: ClickPlayer(engine: try Self.makeEngine(sampleRate: 48_000)), store: Self.makeIsolatedStore())
        model.start()

        model.stop()

        #expect(!model.isRunning)
    }

    @Test func toggleFlipsRunningState() throws {
        let model = MetronomeModel(player: ClickPlayer(engine: try Self.makeEngine(sampleRate: 48_000)), store: Self.makeIsolatedStore())

        model.toggle()
        #expect(model.isRunning)

        model.toggle()
        #expect(!model.isRunning)
    }

    @Test func settingTempoPersistsToStore() throws {
        let store = Self.makeIsolatedStore()
        let model = MetronomeModel(player: ClickPlayer(engine: try Self.makeEngine(sampleRate: 48_000)), store: store)

        model.tempo = Tempo(bpm: 150)

        #expect(store.tempo == Tempo(bpm: 150))
    }

    @Test func settingTimeSignaturePersistsToStore() throws {
        let timeSignatureStore = Self.makeIsolatedTimeSignatureStore()
        let model = MetronomeModel(
            player: ClickPlayer(engine: try Self.makeEngine(sampleRate: 48_000)),
            store: Self.makeIsolatedStore(),
            timeSignatureStore: timeSignatureStore
        )

        model.timeSignature = TimeSignature(beats: 3, noteValue: .quarter)

        #expect(timeSignatureStore.timeSignature == TimeSignature(beats: 3, noteValue: .quarter))
    }

    @Test func beatPhaseIsZeroWhileStopped() throws {
        let model = MetronomeModel(player: ClickPlayer(engine: try Self.makeEngine(sampleRate: 48_000)), store: Self.makeIsolatedStore())

        #expect(model.beatPhase() == 0)
    }

    @Test func beatPhaseAdvancesAsFramesRender() throws {
        let sampleRate = 48_000.0
        let engine = try Self.makeEngine(sampleRate: sampleRate)
        let model = MetronomeModel(player: ClickPlayer(engine: engine), store: Self.makeIsolatedStore())
        model.tempo = Tempo(bpm: 120) // framesPerBeat == 24_000 at 48 kHz

        model.start()
        try Self.render(6_000, on: engine) // a quarter of the way through the beat

        #expect(model.beatPhase() == 0.25)
    }

    @Test func changingTempoWhileRunningForwardsToPlayer() throws {
        let sampleRate = 48_000.0
        let engine = try Self.makeEngine(sampleRate: sampleRate)
        let model = MetronomeModel(player: ClickPlayer(engine: engine), store: Self.makeIsolatedStore())
        model.tempo = Tempo(bpm: 120) // framesPerBeat == 24_000, framesPerMeasure == 96_000 at 48 kHz

        model.start()
        try Self.render(30_000, on: engine) // partway through the second beat of the first measure
        #expect(model.beatPhase() == 0.25)

        model.tempo = Tempo(bpm: 60) // framesPerBeat becomes 48_000; takes effect at the next downbeat
        try Self.render(66_000, on: engine) // reach that downbeat (frame 96_000)
        try Self.render(12_000, on: engine) // a quarter of the way through the new tempo's first beat

        #expect(model.beatPhase() == 0.25)
    }

    @Test func changingTimeSignatureWhileRunningUpdatesValue() throws {
        let sampleRate = 48_000.0
        let engine = try Self.makeEngine(sampleRate: sampleRate)
        let model = MetronomeModel(player: ClickPlayer(engine: engine), store: Self.makeIsolatedStore())

        model.start()
        model.timeSignature = TimeSignature(beats: 3, noteValue: .quarter)

        #expect(model.isRunning)
        #expect(model.timeSignature == TimeSignature(beats: 3, noteValue: .quarter))
    }

    @Test func startFailureSetsErrorMessage() throws {
        let engine = AVAudioEngine()
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 0, channels: 1))
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4_096)
        let model = MetronomeModel(player: ClickPlayer(engine: engine), store: Self.makeIsolatedStore())

        model.start()

        #expect(!model.isRunning)
        #expect(model.errorMessage != nil)
    }
}
