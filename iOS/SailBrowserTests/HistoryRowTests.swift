import Foundation
import Testing
@testable import SailBrowser

struct HistoryRowTests {
    private func row(_ title: String?, _ url: String) -> HistoryRow {
        HistoryRow(title: title, url: URL(string: url)!)
    }

    @Test func titledPageShowsItsTitleAndNamesItsSite() {
        let row = row("Sailfish - Wikipedia", "https://en.wikipedia.org/wiki/Sailfish")
        #expect(row.title == "Sailfish - Wikipedia")
        #expect(row.accessibilityLabel == "Sailfish - Wikipedia, en.wikipedia.org")
    }

    @Test func untitledPageShowsWhereItIs() {
        #expect(row(nil, "https://example.com/").title == "example.com")
        #expect(row("", "https://example.com/a/b?q=1").title == "example.com/a/b")
        #expect(row(" \n", "https://example.com").title == "example.com")
        #expect(row(nil, "https://example.com/").accessibilityLabel == "example.com")
    }

    @Test func titleIsTrimmed() {
        let row = row("  Example Domain\n", "https://example.com/")
        #expect(row.title == "Example Domain")
        #expect(row.accessibilityLabel == "Example Domain, example.com")
    }

    @Test func titleThatIsTheAddressIsNotRepeated() {
        #expect(row("example.com", "https://example.com/").accessibilityLabel == "example.com")
    }

    @Test func pageWithNoHostShowsItsWholeURL() {
        let row = row(nil, "data:text/html,hi")
        #expect(row.title == "data:text/html,hi")
        #expect(row.accessibilityLabel == "data:text/html,hi")
    }

    @Test func blankPageIsNoPage() {
        #expect(!HistoryRow.isPage(URL(string: "about:blank")!))
        #expect(HistoryRow.isPage(URL(string: "https://example.com/")!))
        #expect(HistoryRow.isPage(URL(string: "about:srcdoc")!))
    }
}
