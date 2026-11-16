import SwiftUI

struct MetronomeView: View {
    @Environment(MetronomeModel.self) private var model
    @FocusState private var isTempoFieldFocused: Bool

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 24) {
            BeatIndicator()

            TempoControl(tempo: $model.tempo, isFocused: $isTempoFieldFocused)

            TimeSignatureControl(timeSignature: $model.timeSignature)

            Button {
                model.toggle()
            } label: {
                Text(model.isRunning ? "Stop" : "Start")
                    .frame(minWidth: 80)
            }
            .controlSize(.large)
            .keyboardShortcut(.space, modifiers: [])

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .padding(40)
        .overlay(alignment: .topTrailing) {
            HelpButton()
                .padding(12)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isTempoFieldFocused = false
        }
        .background {
            Group {
                Button("Increase Tempo") { model.tempo = model.tempo.stepped(by: 1) }
                    .keyboardShortcut(.upArrow, modifiers: [])
                Button("Increase Tempo") { model.tempo = model.tempo.stepped(by: 5) }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                Button("Decrease Tempo") { model.tempo = model.tempo.stepped(by: -1) }
                    .keyboardShortcut(.downArrow, modifiers: [])
                Button("Decrease Tempo") { model.tempo = model.tempo.stepped(by: -5) }
                    .keyboardShortcut(.leftArrow, modifiers: [])
            }
            .disabled(isTempoFieldFocused)
            .opacity(0)
            .accessibilityHidden(true)
        }
    }
}

#Preview {
    MetronomeView()
        .environment(MetronomeModel(player: ClickPlayer()))
}
