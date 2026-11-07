import SwiftUI

// A short confirmation that something happened off screen, such as a link reaching the pasteboard. It shows at the top
// of the window, over the page and any sheet, takes no touches, and leaves on its own.
nonisolated struct Toast: Equatable, Sendable {
    let message: String
    let systemImage: String
}

// The one toast on screen. Showing another while one is up replaces it and restarts its time, so repeated taps never
// stack toasts; each showing has its own number, and a dismissal meant for an earlier showing leaves a later one alone.
@Observable final class ToastCenter {
    struct Shown: Equatable {
        let toast: Toast
        let showing: Int
    }

    private(set) var shown: Shown?
    private var showings = 0

    func show(_ toast: Toast) {
        showings += 1
        shown = Shown(toast: toast, showing: showings)
    }

    func dismiss(_ showing: Int) {
        guard shown?.showing == showing else { return }
        shown = nil
    }
}

// Lies over the whole window and draws the current toast below the top safe area. With Reduce Motion it cross-fades
// rather than growing in. VoiceOver reads each showing's message, the repeats too, since each is a fresh copy.
struct ToastOverlay: View {
    let center: ToastCenter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let motion = reduceMotion ? Theme.Motion.fade : Theme.Motion.toast
        ZStack {
            if let shown = center.shown {
                ToastView(toast: shown.toast, showing: reduceMotion ? 0 : shown.showing)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .scale(scale: Theme.Metrics.toastEnterScale, anchor: .top).combined(with: .opacity)
                    )
                    .task(id: shown.showing) {
                        AccessibilityNotification.Announcement(shown.toast.message).post()
                        guard (try? await Task.sleep(for: Theme.Motion.toastHold)) != nil else { return }
                        center.dismiss(shown.showing)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, Theme.Metrics.toastTop)
        .animation(motion.animation, value: center.shown)
        .onChange(of: center.shown) { FrameRateVote.hold(motion) }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// A dark frosted capsule with a glyph and the message. The glyph bounces on each repeat, so a second copy while the
// toast is still up reads as a fresh confirmation; `showing` holds still under Reduce Motion, which leaves it at rest.
private struct ToastView: View {
    let toast: Toast
    let showing: Int

    var body: some View {
        HStack(spacing: Theme.Metrics.toastGlyphGap) {
            Image(systemName: toast.systemImage)
                .font(Theme.Typography.toastGlyph)
                .symbolEffect(.bounce, value: showing)
            Text(toast.message)
                .font(Theme.Typography.toastMessage)
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(Theme.Opacity.menuPrimary))
        .padding(.horizontal, Theme.Metrics.toastPadding)
        .frame(height: Theme.Metrics.toastHeight)
        .background { ChromeMaterialView(style: Theme.Frost.toast) }
        .clipShape(.capsule)
        .overlay {
            Capsule().strokeBorder(.white.opacity(Theme.Opacity.toastEdge), lineWidth: Theme.Metrics.hairlineWidth)
        }
        .environment(\.colorScheme, .dark)
    }
}
