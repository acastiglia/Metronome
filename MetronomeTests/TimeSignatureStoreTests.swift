import Foundation
import Testing
@testable import Metronome

struct TimeSignatureStoreTests {
    private static func makeIsolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "TimeSignatureStoreTests.\(UUID().uuidString)")!
    }

    @Test func defaultsToDefaultTimeSignatureWhenNothingStored() {
        let store = TimeSignatureStore(defaults: Self.makeIsolatedDefaults())
        #expect(store.timeSignature == .defaultTimeSignature)
    }

    @Test func roundTripsSavedTimeSignature() {
        let store = TimeSignatureStore(defaults: Self.makeIsolatedDefaults())

        store.timeSignature = TimeSignature(beats: 3, noteValue: .quarter)

        #expect(store.timeSignature == TimeSignature(beats: 3, noteValue: .quarter))
    }

    @Test func persistsAcrossInstancesSharingTheSameDefaults() {
        let defaults = Self.makeIsolatedDefaults()
        let store = TimeSignatureStore(defaults: defaults)
        store.timeSignature = TimeSignature(beats: 6, noteValue: .eighth)

        let reloaded = TimeSignatureStore(defaults: defaults)

        #expect(reloaded.timeSignature == TimeSignature(beats: 6, noteValue: .eighth))
    }

    @Test func isolatedSuitesDoNotShareState() {
        let store = TimeSignatureStore(defaults: Self.makeIsolatedDefaults())
        store.timeSignature = TimeSignature(beats: 2, noteValue: .half)

        let other = TimeSignatureStore(defaults: Self.makeIsolatedDefaults())

        #expect(other.timeSignature == .defaultTimeSignature)
    }
}
