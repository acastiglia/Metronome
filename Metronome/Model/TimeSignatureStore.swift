import Foundation

/// Loads and saves the last-used `TimeSignature` in `UserDefaults`.
struct TimeSignatureStore {
    private static let beatsKey = "timeSignature.beats"
    private static let noteValueKey = "timeSignature.noteValue"

    private let defaults: UserDefaults

    /// - Parameter defaults: The suite to read and write. Tests can pass an isolated suite.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var timeSignature: TimeSignature {
        get {
            guard let beats = defaults.object(forKey: Self.beatsKey) as? Int,
                  let rawNoteValue = defaults.object(forKey: Self.noteValueKey) as? Int,
                  let noteValue = TimeSignature.NoteValue(rawValue: rawNoteValue) else {
                return .defaultTimeSignature
            }
            return TimeSignature(beats: beats, noteValue: noteValue)
        }
        nonmutating set {
            defaults.set(newValue.beats, forKey: Self.beatsKey)
            defaults.set(newValue.noteValue.rawValue, forKey: Self.noteValueKey)
        }
    }
}
