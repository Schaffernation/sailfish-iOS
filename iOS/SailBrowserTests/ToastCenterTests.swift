import Testing
@testable import SailBrowser

struct ToastCenterTests {
    private let copied = Toast(message: "Link Copied", systemImage: "checkmark")

    // A second copy while the toast is up replaces it, so the first one's timer must not take the second one down.
    @Test func showingAgainReplacesAndOutlivesTheEarlierDismissal() throws {
        let center = ToastCenter()
        center.show(copied)
        let first = try #require(center.shown)
        center.show(copied)
        let second = try #require(center.shown)
        #expect(second.toast == copied)
        #expect(second.showing != first.showing)
        center.dismiss(first.showing)
        #expect(center.shown == second)
        center.dismiss(second.showing)
        #expect(center.shown == nil)
    }
}
