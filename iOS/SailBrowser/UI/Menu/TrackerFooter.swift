import SwiftUI

// The count is a floor: WebKit reports no rule list matches, so only blocked element loads are seen.
struct TrackerFooter: View {
    enum Content: Equatable {
        case scrubbed(Int), allowed, allowedOnce
    }

    // What the footer shows, and for which site. A page under blocking offers its reload without blockers, with or
    // without a count: a page that counted nothing can still have had its fetches or scripts blocked.
    struct Shown: Equatable {
        let host: String
        let content: Content?
        let offersUnblockedReload: Bool

        static func of(host: String, blocksGlobally: Bool, blocksSite: Bool, isUnblocked: Bool, count: Int) -> Shown? {
            guard blocksGlobally else { return nil }
            guard blocksSite else { return Shown(host: host, content: .allowed, offersUnblockedReload: false) }
            guard !isUnblocked else { return Shown(host: host, content: .allowedOnce, offersUnblockedReload: false) }
            return Shown(host: host, content: count > 0 ? .scrubbed(count) : nil, offersUnblockedReload: true)
        }
    }

    let shown: Shown
    let fill: Color
    let open: () -> Void
    let reloadUnblocked: () -> Void

    // One card, as the menu's rows are: each row its own fill, apart by a hairline that shows the sheet.
    var body: some View {
        VStack(spacing: Theme.Metrics.menuRowGap) {
            if let content = shown.content {
                Button(action: open) {
                    row(label(content))
                }
                .accessibilityHint("Opens Site Settings")
            }
            if shown.offersUnblockedReload {
                Button(action: reloadUnblocked) {
                    row(Text("Reload Without Blockers"))
                }
                .buttonStyle(PressStyle(scale: Theme.Metrics.pressScaleWide, preparing: .menuNav))
                .accessibilityHint("Reloads this page once with content blocking off")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.menuListCorner, style: .continuous))
    }

    private func row(_ label: some View) -> some View {
        label
            .font(Theme.Typography.menuFooter)
            .frame(maxWidth: .infinity, minHeight: Theme.Metrics.menuListRowHeight, alignment: .leading)
            .padding(.horizontal, Theme.Metrics.menuFooterInset)
            .background(fill)
            .contentShape(Rectangle())
    }

    private func label(_ content: Content) -> Text {
        switch content {
        case .scrubbed(let count):
            let number = Text(count, format: .number).font(Theme.Typography.menuFooterCount)
            return Text("\(number) \(count == 1 ? "tracker" : "trackers") blocked")
        case .allowed:
            return Text("Trackers allowed")
        case .allowedOnce:
            return Text("Trackers allowed for this load")
        }
    }
}
