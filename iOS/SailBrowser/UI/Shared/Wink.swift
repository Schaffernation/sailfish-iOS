import SwiftUI

extension View {
    // Winks the view out and back each time `trigger` changes: it shrinks away on a quick spring, stays gone a moment,
    // then springs back. A change while it is out keeps it out and restarts the wait; a change on its way back sends it
    // out again from where it is drawn, so repeated taps never jump. Reduce Motion fades it instead of scaling it.
    func wink<Trigger: Equatable>(on trigger: Trigger) -> some View {
        modifier(Wink(trigger: trigger))
    }
}

private struct Wink<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOut = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isOut && !reduceMotion ? Theme.Metrics.winkScale : 1)
            .opacity(isOut ? 0 : 1)
            .onChange(of: trigger) {
                change(to: true, on: reduceMotion ? Theme.Motion.fade : Theme.Motion.winkOut)
            }
            // A new trigger cancels the wait, and the cancelled wait leaves the view out for the new one.
            .task(id: trigger) {
                guard isOut, (try? await Task.sleep(for: Theme.Motion.winkHold)) != nil else { return }
                change(to: false, on: reduceMotion ? Theme.Motion.fade : Theme.Motion.winkIn)
            }
    }

    private func change(to out: Bool, on motion: MotionToken) {
        FrameRateVote.hold(motion)
        withAnimation(motion.animation) { isOut = out }
    }
}
