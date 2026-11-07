import Foundation

// One load of a tab's page with content blocking off, asked for from the menu. It is the tab's alone and leaves the
// site's setting as it is: it ends at the next main-frame navigation that is not the reload's own way in, so a normal
// reload, a history move or a new page blocks again.
nonisolated struct UnblockedLoad: Equatable, Sendable {
    // How a main-frame navigation came about, as far as the end of an unblocked load cares.
    enum Navigation: Equatable, Sendable {
        case link, reload, backForward, other
    }

    private enum State: Equatable, Sendable {
        case off, requested, loading
        case shown(URL)
    }

    private var state = State.off

    // Whether the page loading, or the one shown, is under no blocking.
    var isOn: Bool {
        state != .off
    }

    // Set before the tab's reload, which is the next navigation decided.
    mutating func request() {
        state = .requested
    }

    // The tab navigates on the user's word, or a navigation failed and left the page before it, which loaded with
    // blocking on: a navigation off the unblocked page turns it off when it is decided, before it can fail.
    mutating func end() {
        state = .off
    }

    // A main-frame navigation is decided, before its site is applied. The reload's own redirects come as reloads or as
    // navigations of no kind, and stay unblocked; a link or a history move off the old page, still shown while the
    // reload is under way, leaves. Once the page is shown, only a move within its document keeps it: that loads no new
    // document, so its later requests still belong to the unblocked page. WebKit keeps the document for a URL that
    // differs only in a fragment it has; the same URL bare is a new load.
    mutating func decide(_ url: URL?, as navigation: Navigation) {
        switch state {
        case .off:
            break
        case .requested:
            state = .loading
        case .loading:
            if navigation == .link || navigation == .backForward {
                state = .off
            }
        case .shown(let page):
            if navigation == .reload || !Self.isSameDocument(url, page) {
                state = .off
            }
        }
    }

    // A main-frame document committed. Only the reload's own commit shows an unblocked page; any other is a document
    // that was decided with blocking on.
    mutating func commit(_ url: URL?) {
        if state == .loading, let url {
            state = .shown(url)
        } else {
            state = .off
        }
    }

    private static func isSameDocument(_ url: URL?, _ page: URL) -> Bool {
        guard let url, url.fragment() != nil else { return false }
        return withoutFragment(url) == withoutFragment(page)
    }

    private static func withoutFragment(_ url: URL) -> URL? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        return components?.url
    }
}
