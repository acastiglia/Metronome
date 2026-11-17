import AVFoundation

enum ClickPlayerError: Error {
    case unsupportedSampleRate(Double)
}

/// Plays a continuous metronome click through an `AVAudioEngine`.
///
/// Each measure is one PCM buffer that an `AVAudioPlayerNode` loops, so the audio hardware clock
/// alone sets the pace. A tempo or time signature change schedules a new buffer that replaces
/// the looping one at its loop point, so the change always lands exactly on a downbeat.
///
/// If the audio configuration changes while running (for example, the output device changes),
/// the player rebuilds its connection at the new sample rate and restarts at the same tempo and
/// time signature.
@MainActor
final class ClickPlayer {
    private let engine: AVAudioEngine
    private let playerNode = AVAudioPlayerNode()
    private var session: Session?
    private var configurationObservation: NotificationObservation?

    var isRunning: Bool {
        session != nil
    }

    /// Preallocates the engine's render resources up front so the first real `start()` isn't
    /// delayed by that setup. Skipped for engines tests put in manual rendering mode, where
    /// preparing before the render graph is fully connected makes `renderOffline` fail.
    ///
    /// - Parameter engine: The engine to play through. Tests can pass one in manual rendering mode.
    init(engine: AVAudioEngine = AVAudioEngine()) {
        self.engine = engine
        engine.attach(playerNode)
        if !engine.isInManualRenderingMode {
            _ = engine.outputNode
            engine.prepare()
        }
        configurationObservation = NotificationObservation(
            name: .AVAudioEngineConfigurationChange,
            object: engine
        ) { [weak self] in
            self?.restartAfterConfigurationChange()
        }
    }

    /// Starts clicking at `tempo` and `timeSignature`, with the first click sounding immediately.
    ///
    /// Calling this while already running changes the tempo and time signature instead.
    func start(tempo: Tempo, timeSignature: TimeSignature = .defaultTimeSignature) throws {
        guard !isRunning else {
            setTempo(tempo, timeSignature: timeSignature)
            return
        }

        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        guard let synthesizer = ClickSynthesizer(sampleRate: sampleRate) else {
            throw ClickPlayerError.unsupportedSampleRate(sampleRate)
        }
        engine.connect(playerNode, to: engine.mainMixerNode, format: synthesizer.format)
        try engine.start()

        let buffer = synthesizer.measureBuffer(for: tempo, timeSignature: timeSignature)
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        playerNode.play()

        session = Session(
            synthesizer: synthesizer,
            tempo: tempo,
            timeSignature: timeSignature,
            beatGrids: [
                BeatGrid(
                    startFrame: 0,
                    framesPerBeat: AVAudioFramePosition(tempo.framesPerBeat(sampleRate: sampleRate)),
                    beatsPerMeasure: timeSignature.beats
                ),
            ]
        )
    }

    /// Switches to `tempo` and `timeSignature` at the next downbeat. Does nothing while stopped.
    ///
    /// A second change made before the first has taken effect replaces it, so dragging the
    /// tempo slider never queues up a backlog of intermediate tempos.
    func setTempo(_ tempo: Tempo, timeSignature: TimeSignature = .defaultTimeSignature) {
        guard var session, tempo != session.tempo || timeSignature != session.timeSignature else { return }

        let buffer = session.synthesizer.measureBuffer(for: tempo, timeSignature: timeSignature)
        let frame = currentFrame() ?? 0
        let playingGrid = session.beatGrids.last { $0.startFrame <= frame } ?? session.beatGrids[0]
        playerNode.scheduleBuffer(buffer, at: nil, options: [.loops, .interruptsAtLoop], completionHandler: nil)

        session.tempo = tempo
        session.timeSignature = timeSignature
        session.beatGrids = [
            playingGrid,
            BeatGrid(
                startFrame: playingGrid.nextMeasureBoundary(after: frame),
                framesPerBeat: AVAudioFramePosition(tempo.framesPerBeat(sampleRate: session.synthesizer.sampleRate)),
                beatsPerMeasure: timeSignature.beats
            ),
        ]
        self.session = session
    }

    func stop() {
        playerNode.stop()
        engine.pause()
        session = nil
    }

    /// The player's position in frames since it started, or `nil` while stopped.
    func currentFrame() -> AVAudioFramePosition? {
        guard let renderTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: renderTime) else {
            return nil
        }
        return playerTime.sampleTime
    }

    /// The fraction of the current beat that has elapsed (0 ≤ phase < 1), or `nil` while stopped.
    func beatPhase() -> Double? {
        guard let session,
              let frame = currentFrame(),
              let grid = session.beatGrids.last(where: { $0.startFrame <= frame }) else {
            return nil
        }
        return grid.phase(at: frame)
    }

    /// The index of the current beat within the measure (0..<timeSignature.beats), or `nil` while
    /// stopped.
    func beatIndex() -> Int? {
        guard let session,
              let frame = currentFrame(),
              let grid = session.beatGrids.last(where: { $0.startFrame <= frame }) else {
            return nil
        }
        return grid.beatIndex(at: frame)
    }

    private func restartAfterConfigurationChange() {
        guard let session else { return }
        stop()
        try? start(tempo: session.tempo, timeSignature: session.timeSignature)
    }
}

/// State that exists only while the player is running.
private struct Session {
    let synthesizer: ClickSynthesizer
    var tempo: Tempo
    var timeSignature: TimeSignature
    var beatGrids: [BeatGrid]
}

/// Evenly spaced beats, grouped into measures of `beatsPerMeasure` beats, starting at a given
/// player frame.
private struct BeatGrid {
    let startFrame: AVAudioFramePosition
    let framesPerBeat: AVAudioFramePosition
    let beatsPerMeasure: Int

    var framesPerMeasure: AVAudioFramePosition {
        framesPerBeat * AVAudioFramePosition(beatsPerMeasure)
    }

    func phase(at frame: AVAudioFramePosition) -> Double {
        Double((frame - startFrame) % framesPerBeat) / Double(framesPerBeat)
    }

    /// The index of the beat `frame` falls in, within the measure (0..<beatsPerMeasure).
    func beatIndex(at frame: AVAudioFramePosition) -> Int {
        Int((frame - startFrame) / framesPerBeat) % beatsPerMeasure
    }

    /// The frame at which the currently-looping measure buffer will next restart from its
    /// downbeat — the only point at which `.interruptsAtLoop` can swap in a new buffer.
    func nextMeasureBoundary(after frame: AVAudioFramePosition) -> AVAudioFramePosition {
        startFrame + ((frame - startFrame) / framesPerMeasure + 1) * framesPerMeasure
    }
}

/// Delivers a notification to a main-actor handler, and stops observing when released.
private final class NotificationObservation {
    private let token: any NSObjectProtocol

    init(name: Notification.Name, object: AnyObject, handler: @escaping @MainActor @Sendable () -> Void) {
        token = NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { _ in
            MainActor.assumeIsolated(handler)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(token)
    }
}
