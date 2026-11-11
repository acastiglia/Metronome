import SwiftUI

/// A compact button showing the current time signature; clicking it opens a popover with
/// controls for the beat count and which note gets the beat.
struct TimeSignatureControl: View {
    @Binding var timeSignature: TimeSignature

    @State private var isPresented = false

    private static let noteValues: [TimeSignature.NoteValue] = [.whole, .half, .quarter, .eighth]

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Text("\(timeSignature.beats)/\(timeSignature.noteValue.rawValue)")
                .font(.title2.monospacedDigit())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented) {
            HStack(spacing: 8) {
                Stepper(value: beatsBinding, in: TimeSignature.range) {
                    Text("\(timeSignature.beats)")
                }
                .accessibilityLabel("Beats per measure")

                Text("/")

                Stepper(
                    onIncrement: Self.noteValues.indices.contains(noteValueIndex + 1)
                        ? { setNoteValue(at: noteValueIndex + 1) }
                        : nil,
                    onDecrement: Self.noteValues.indices.contains(noteValueIndex - 1)
                        ? { setNoteValue(at: noteValueIndex - 1) }
                        : nil
                ) {
                    Text("\(timeSignature.noteValue.rawValue)")
                }
                .accessibilityLabel("Note that gets the beat")
            }
            .padding()
        }
    }

    private var beatsBinding: Binding<Int> {
        Binding(
            get: { timeSignature.beats },
            set: { timeSignature = TimeSignature(beats: $0, noteValue: timeSignature.noteValue) }
        )
    }

    private var noteValueIndex: Int {
        Self.noteValues.firstIndex(of: timeSignature.noteValue) ?? 0
    }

    private func setNoteValue(at index: Int) {
        guard Self.noteValues.indices.contains(index) else { return }
        timeSignature = TimeSignature(beats: timeSignature.beats, noteValue: Self.noteValues[index])
    }
}

#Preview {
    TimeSignatureControl(timeSignature: .constant(.defaultTimeSignature))
        .padding(40)
}
