import SwiftUI

/// Displays the current tempo as text; clicking it turns it into an editable field.
///
/// Committing a non-numeric value leaves the tempo unchanged. Any numeric value is clamped
/// to ``Tempo/range`` by ``Tempo/init(bpm:)``.
struct TempoControl: View {
    @Binding var tempo: Tempo
    var isFocused: FocusState<Bool>.Binding

    @State private var isEditing = false
    @State private var text = ""

    var body: some View {
        VStack(spacing: 28) {
            Group {
                if isEditing {
                    TextField("BPM", text: $text)
                        .focused(isFocused)
                        .onSubmit(commit)
                        .multilineTextAlignment(.center)
                } else {
                    Text("\(tempo.bpm)")
                        .onTapGesture(perform: beginEditing)
                }
            }
            .font(.system(size: 64, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .frame(minWidth: 220)
            .onChange(of: isFocused.wrappedValue) {
                if isEditing && !isFocused.wrappedValue {
                    commit()
                }
            }

            Slider(
                value: sliderBinding,
                in: Double(Tempo.range.lowerBound)...Double(Tempo.range.upperBound)
            ).tint(.gray)
            .disabled(isEditing)
        }
    }

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { Double(tempo.bpm) },
            set: { tempo = Tempo(bpm: Int($0.rounded())) }
        )
    }

    private func beginEditing() {
        text = String(tempo.bpm)
        isEditing = true
        isFocused.wrappedValue = true
    }

    private func commit() {
        if let bpm = Int(text) {
            tempo = Tempo(bpm: bpm)
        }
        isEditing = false
        isFocused.wrappedValue = false
    }
}

#Preview {
    @Previewable @FocusState var isFocused: Bool
    TempoControl(tempo: .constant(.defaultTempo), isFocused: $isFocused)
        .padding(40)
}
