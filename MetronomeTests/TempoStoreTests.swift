import Foundation
import Testing
@testable import Metronome

struct TempoStoreTests {
    private static func makeIsolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "TempoStoreTests.\(UUID().uuidString)")!
    }

    @Test func defaultsToDefaultTempoWhenNothingStored() {
        let store = TempoStore(defaults: Self.makeIsolatedDefaults())
        #expect(store.tempo == .defaultTempo)
    }

    @Test func roundTripsSavedTempo() {
        let store = TempoStore(defaults: Self.makeIsolatedDefaults())

        store.tempo = Tempo(bpm: 150)

        #expect(store.tempo == Tempo(bpm: 150))
    }

    @Test func persistsAcrossInstancesSharingTheSameDefaults() {
        let defaults = Self.makeIsolatedDefaults()
        let store = TempoStore(defaults: defaults)
        store.tempo = Tempo(bpm: 90)

        let reloaded = TempoStore(defaults: defaults)

        #expect(reloaded.tempo == Tempo(bpm: 90))
    }

    @Test func isolatedSuitesDoNotShareState() {
        let store = TempoStore(defaults: Self.makeIsolatedDefaults())
        store.tempo = Tempo(bpm: 200)

        let other = TempoStore(defaults: Self.makeIsolatedDefaults())

        #expect(other.tempo == .defaultTempo)
    }
}
