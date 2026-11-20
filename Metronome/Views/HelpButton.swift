import SwiftUI

/// A minimal "?" affordance that reveals keyboard shortcuts and control tips in a popover,
/// keeping the main view free of permanent help text.
struct HelpButton: View {
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "questionmark.circle")
                .imageScale(.large)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Help")
        .popover(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Shortcuts")
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                    GridRow {
                        Text("Space")
                            .foregroundStyle(.secondary)
                        Text("Start / stop")
                    }
                    GridRow {
                        Text("⌃Space")
                            .foregroundStyle(.secondary)
                        Text("Tap tempo")
                    }
                    GridRow {
                        Text("↑ / ↓")
                            .foregroundStyle(.secondary)
                        Text("Tempo ±1")
                    }
                    GridRow {
                        Text("← / →")
                            .foregroundStyle(.secondary)
                        Text("Tempo ±5")
                    }
                }
                .font(.callout.monospacedDigit())

                Divider()

                Text("Tap the tempo or time signature to edit them directly.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 260)
        }
    }
}

#Preview {
    HelpButton()
        .padding(40)
}
