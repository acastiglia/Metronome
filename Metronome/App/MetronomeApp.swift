import SwiftUI

@main
struct MetronomeApp: App {
    @State private var model = MetronomeModel(player: ClickPlayer())

    var body: some Scene {
        Window("Metronome", id: "metronome") {
            MetronomeView()
                .environment(model)
        }
        .windowResizability(.contentSize)
    }
}
