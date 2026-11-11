import Foundation

/// Loads and saves the last-used `Tempo` in `UserDefaults`.
struct TempoStore {
    private static let bpmKey = "tempo.bpm"

    private let defaults: UserDefaults

    /// - Parameter defaults: The suite to read and write. Tests can pass an isolated suite.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var tempo: Tempo {
        get {
            let storedBPM = defaults.object(forKey: Self.bpmKey) as? Int
            return storedBPM.map(Tempo.init(bpm:)) ?? .defaultTempo
        }
        nonmutating set {
            defaults.set(newValue.bpm, forKey: Self.bpmKey)
        }
    }
}
