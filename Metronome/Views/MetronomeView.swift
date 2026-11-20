import SwiftUI

struct MetronomeView: View {
    @Environment(MetronomeModel.self) private var model
    @FocusState private var isTempoFieldFocused: Bool

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 32) {
            BeatIndicator()

            TempoControl(tempo: $model.tempo, isFocused: $isTempoFieldFocused)

            VStack(spacing: 16) {
                TimeSignatureControl(timeSignature: $model.timeSignature)

                HStack(spacing: 16) {
                    Button {
                        model.toggle()
                    } label: {
                        Label(
                            model.isRunning ? "Stop" : "Start",
                            systemImage: model.isRunning ? "stop.fill" : "play.fill"
                        )
                        .frame(minWidth: 100)
                    }
                    .keyboardShortcut(.space, modifiers: [])

                    Button("Tap") {
                        model.tap()
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.space, modifiers: [.control])
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            }

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
