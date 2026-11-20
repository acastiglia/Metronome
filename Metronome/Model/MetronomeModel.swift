import Foundation
import Observation

/// The single source of truth for app state.
///
/// Owns a `ClickPlayer` and a `TempoStore`, both passed in through the initializer so tests
/// can supply their own.
@Observable
@MainActor
final class MetronomeModel {
    private let player: ClickPlayer
    private var store: TempoStore
    private var timeSignatureStore: TimeSignatureStore

    private(set) var isRunning = false
    private(set) var tapping = false
    var errorMessage: String?

    private var tapTempo: TapTempo?
    private var tapDiscardTask: Task<Void, Never>?

    /// The current tempo. Setting it persists the value via `TempoStore` and, while running,
    /// forwards it to `ClickPlayer`.
    var tempo: Tempo {
        didSet {
            guard tempo != oldValue else { return }
            store.tempo = tempo
            if isRunning {
                player.setTempo(tempo, timeSignature: timeSignature)
            }
        }
    }

    /// The current time signature. Setting it persists the value via `TimeSignatureStore` and,
    /// while running, forwards it to `ClickPlayer`.
    var timeSignature: TimeSignature {
        didSet {
            guard timeSignature != oldValue else { return }
            timeSignatureStore.timeSignature = timeSignature
            if isRunning {
                player.setTempo(tempo, timeSignature: timeSignature)
            }
        }
    }

    init(player: ClickPlayer, store: TempoStore = TempoStore(), timeSignatureStore: TimeSignatureStore = TimeSignatureStore()) {
        self.player = player
        self.store = store
        self.timeSignatureStore = timeSignatureStore
        self.tempo = store.tempo
        self.timeSignature = timeSignatureStore.timeSignature
    }

    func start() {
        endTapping()
        do {
            try player.start(tempo: tempo, timeSignature: timeSignature)
            isRunning = true
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't start: \(error.localizedDescription)"
        }
    }

    func stop() {
        player.stop()
        isRunning = false
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    /// Registers a tap for tap-tempo detection, updating ``tempo`` once enough taps have been
    /// recorded. The tap sequence is discarded after a 2 second pause between taps, or
    /// immediately if the player is started.
    func tap() {
        if tapTempo == nil {
            if isRunning { stop() }
            tapTempo = TapTempo()
            tapping = true
        }

        if let bpm = tapTempo?.tap() {
            tempo = Tempo(bpm: bpm)
        }

        tapDiscardTask?.cancel()
        tapDiscardTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self?.endTapping()
        }
    }

    private func endTapping() {
        tapDiscardTask?.cancel()
        tapDiscardTask = nil
        tapTempo = nil
        tapping = false
    }

    /// The fraction of the current beat that has elapsed (0 ≤ phase < 1).
    ///
    /// `date` is unused — the real clock is the audio player's sample time. `BeatIndicator` calls
    /// this from a `TimelineView(.animation)`, passing `context.date` each tick to give SwiftUI a
    /// reason to re-invalidate the view.
    func beatPhase(at date: Date = .now) -> Double {
        player.beatPhase() ?? 0
    }

    /// The index of the current beat within the measure (0..<timeSignature.beats).
    ///
    /// `date` is unused, for the same reason as in `beatPhase(at:)`.
    func beatIndex(at date: Date = .now) -> Int {
        player.beatIndex() ?? 0
    }
}
