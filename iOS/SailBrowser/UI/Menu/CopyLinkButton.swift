import SwiftUI

// The address pill's Copy Link: each copy winks the glyph out and back, and the copy itself says so in a toast. The
// glyph keeps its touch while it is out, so another tap copies again and restarts the wink.
struct CopyLinkButton<Label: View>: View {
    let copy: () -> Void
    @ViewBuilder let label: Label
    @State private var copies = 0

    var body: some View {
        Button(action: tap) {
            // The touch area is the glyph's frame, outside the wink, which would otherwise shrink and hide it.
            label
                .wink(on: copies)
                .contentShape(.rect)
        }
        .buttonStyle(PressStyle(scale: Theme.Metrics.pressScaleWide, preparing: .menuCopyLink))
        .accessibilityLabel("Copy Link")
        #if DEBUG
        .debugAction(.menuCopyLink, tap)
        #endif
    }

    private func tap() {
        copies += 1
        copy()
    }
}
