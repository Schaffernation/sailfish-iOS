import Foundation

nonisolated enum HistoryDirection: Sendable {
    case back, forward
}

// A row of the list a hold on Back or Forward opens. A page with no title shows where it is, as the nav pill does,
// and VoiceOver hears the site after a title, since titles alone often repeat across a site's pages.
nonisolated struct HistoryRow: Equatable, Sendable {
    let title: String
    let accessibilityLabel: String

    init(title: String?, url: URL) {
        let place = Self.place(url)
        let title = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.title = title.isEmpty ? place : title
        accessibilityLabel =
            if let host = url.host(), !title.isEmpty, title != place {
                "\(title), \(host)"
            } else {
                self.title
            }
    }

    // The pool's prewarmed blank page sits under a new tab's first page; going back to it would show nothing.
    static func isPage(_ url: URL) -> Bool {
        url.absoluteString != "about:blank"
    }

    // The nav pill's address too: the host and path, the host alone for a site's root, and the whole URL for one with
    // no host.
    static func place(_ url: URL) -> String {
        guard let host = url.host() else { return url.absoluteString }
        let path = url.path()
        return path == "/" ? host : host + path
    }
}
