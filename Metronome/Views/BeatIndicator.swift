import SwiftUI

/// A row of dots, one per beat in the measure, with the currently-sounding beat lit in the
/// accent color. The downbeat is always the leftmost dot, so its position alone identifies it —
/// no separate coloring is needed for it.
///
/// The beat change is detected from the audio player's sample-accurate clock via a
/// `TimelineView(.animation)`, so the flash can never drift from the click. The decay afterward
/// is a deliberately chosen visual duration handed off to SwiftUI's own animation engine, rather
/// than a trace of the audio envelope — the actual click is only ~20ms long, too brief to read
/// reliably against this view's own polling rate (sampling a signal that brief this way is prone
/// to aliasing: depending on exactly when a tick lands relative to the beat, you might catch the
/// click near its peak, already decayed, or not at all).
struct BeatIndicator: View {
    @Environment(MetronomeModel.self) private var model

    @State private var litBeat = 0
    @State private var brightness = BeatIndicator.restingOpacity

    private static let dotDiameter: CGFloat = 16
    private static let minimumDotDiameter: CGFloat = 6
    private static let restingOpacity = 0.25
    private static let decayDuration = 0.15

    var body: some View {
        TimelineView(.animation(paused: !model.isRunning)) { context in
            let beats = model.timeSignature.beats
            let currentBeat = model.beatIndex(at: context.date)
            let diameter = dotDiameter(for: beats)

            HStack(spacing: diameter / 2) {
                ForEach(0..<beats, id: \.self) { beat in
                    Circle()
                        .fill(beat == litBeat ? Color.accentColor : Color.primary)
                        .frame(width: diameter, height: diameter)
                        .opacity(beat == litBeat ? brightness : Self.restingOpacity)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Beat \(currentBeat + 1) of \(beats)")
            .onChange(of: currentBeat) { _, newBeat in
                flash(beat: newBeat)
            }
            .onChange(of: model.isRunning) { _, isRunning in
                // currentBeat is 0 both while stopped and on the very first downbeat, so
                // onChange(of: currentBeat) alone never fires for that first beat.
                if isRunning {
                    flash(beat: currentBeat)
                }
            }
        }
    }

    private func flash(beat: Int) {
        litBeat = beat
        brightness = 1
        withAnimation(.easeOut(duration: Self.decayDuration)) {
            brightness = Self.restingOpacity
        }
    }

    private func dotDiameter(for beats: Int) -> CGFloat {
        let totalSpan = Self.dotDiameter * 1.5 * CGFloat(beats)
        guard totalSpan > 220 else { return Self.dotDiameter }
        return max(Self.minimumDotDiameter, Self.dotDiameter * 220 / totalSpan)
    }
}

#Preview {
    BeatIndicator()
        .environment(MetronomeModel(player: ClickPlayer()))
        .padding(40)
}
