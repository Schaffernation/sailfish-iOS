import Foundation
import Testing
@testable import SailBrowser

// A load without blockers that outlived its page would leave a site unblocked with nothing on screen to say so.
struct UnblockedLoadTests {
    private let page = URL(string: "https://example.com/article")!

    private func shown() -> UnblockedLoad {
        var load = UnblockedLoad()
        load.request()
        load.decide(page, as: .reload)
        load.commit(page)
        return load
    }

    @Test func theRequestedReloadAndItsRedirectsLoadUnblocked() {
        var load = UnblockedLoad()
        #expect(!load.isOn)
        load.request()
        load.decide(page, as: .reload)
        #expect(load.isOn)
        let redirected = URL(string: "https://www.example.com/article")!
        load.decide(redirected, as: .other)
        load.decide(redirected, as: .reload)
        #expect(load.isOn)
        load.commit(redirected)
        #expect(load.isOn)
    }

    @Test func aLinkOrHistoryMoveOffTheOldPageDuringTheReloadBlocks() {
        for navigation in [UnblockedLoad.Navigation.link, .backForward] {
            var load = UnblockedLoad()
            load.request()
            load.decide(page, as: .reload)
            load.decide(URL(string: "https://example.com/other")!, as: navigation)
            #expect(!load.isOn)
            load.commit(URL(string: "https://example.com/other")!)
            #expect(!load.isOn)
        }
    }

    @Test func anyNewDocumentAfterTheShownPageBlocks() {
        let elsewhere = URL(string: "https://example.com/next")!
        let cases: [(URL, UnblockedLoad.Navigation)] = [
            (elsewhere, .link), (elsewhere, .other), (elsewhere, .backForward), (page, .reload), (page, .link),
            (page, .other), (page, .backForward),
        ]
        for (url, navigation) in cases {
            var load = shown()
            load.decide(url, as: navigation)
            #expect(!load.isOn, "\(url) as \(navigation)")
        }
    }

    // A fragment move keeps the document, so the page's later requests are still the unblocked load's.
    @Test func aMoveWithinTheShownDocumentStaysUnblocked() {
        var load = shown()
        load.decide(URL(string: "https://example.com/article#comments")!, as: .link)
        #expect(load.isOn)
        load.decide(URL(string: "https://example.com/article?page=2#comments")!, as: .link)
        #expect(!load.isOn)
    }

    @Test func aCommitNotOfTheReloadBlocks() {
        var load = shown()
        load.commit(page)
        #expect(!load.isOn)

        var requested = UnblockedLoad()
        requested.request()
        requested.commit(page)
        #expect(!requested.isOn)
    }

    @Test func endingBlocksAtOnce() {
        var load = shown()
        load.end()
        #expect(!load.isOn)
        load.decide(page, as: .reload)
        load.commit(page)
        #expect(!load.isOn)
    }

    @Test func theFooterOffersTheReloadOnlyWhileThePageIsUnderBlocking() {
        let host = "example.com"
        #expect(TrackerFooter.Shown.of(host: host, blocksGlobally: false, blocksSite: true, isUnblocked: false, count: 3) == nil)
        #expect(
            TrackerFooter.Shown.of(host: host, blocksGlobally: true, blocksSite: false, isUnblocked: false, count: 3)
                == .init(host: host, content: .allowed, offersUnblockedReload: false))
        #expect(
            TrackerFooter.Shown.of(host: host, blocksGlobally: true, blocksSite: true, isUnblocked: true, count: 3)
                == .init(host: host, content: .allowedOnce, offersUnblockedReload: false))
        #expect(
            TrackerFooter.Shown.of(host: host, blocksGlobally: true, blocksSite: true, isUnblocked: false, count: 3)
                == .init(host: host, content: .scrubbed(3), offersUnblockedReload: true))
        #expect(
            TrackerFooter.Shown.of(host: host, blocksGlobally: true, blocksSite: true, isUnblocked: false, count: 0)
                == .init(host: host, content: nil, offersUnblockedReload: true))
    }
}
