import SwiftUI
import UIKit
import WebKit

// The nav pill's Back or Forward: a tap steps once, and a hold lists the tab's pages that way. WebKit's list is not
// observable, and a SwiftUI menu made its rows when the pill last updated, which after a tap on Back was before WebKit
// moved: the list was a step behind. A deferred element asks for its rows each time the menu opens.
struct HistoryButton: UIViewRepresentable {
    let direction: HistoryDirection
    let tint: UIColor
    let items: () -> [WKBackForwardListItem]
    let favicon: (URL) -> UIImage?
    let onStep: () -> Void
    let onPick: (WKBackForwardListItem) -> Void
    let onPress: () -> Void

    // Scales on touch-down and springs back on release, as PressStyle does for the pill's other buttons.
    final class Control: UIButton {
        var onPress: () -> Void = {}

        override var isHighlighted: Bool {
            didSet {
                guard isHighlighted != oldValue else { return }
                if isHighlighted {
                    onPress()
                }
                let scale = isHighlighted ? Theme.Metrics.pressScaleWide : 1
                (isHighlighted ? Theme.Motion.press : Theme.Motion.pressRelease).animate(initialVelocity: 0) {
                    self.transform = CGAffineTransform(scaleX: scale, y: scale)
                } completion: { _ in }
            }
        }
    }

    final class Coordinator {
        var parent: HistoryButton

        init(parent: HistoryButton) {
            self.parent = parent
        }

        func menuElements() -> [UIMenuElement] {
            parent.items().map { item in
                let row = HistoryRow(title: item.title, url: item.url)
                let image = parent.favicon(item.url).map(Self.menuIcon) ?? UIImage(systemName: "globe")
                let action = UIAction(title: row.title, image: image) { [weak self] _ in
                    self?.parent.onPick(item)
                }
                action.accessibilityLabel = row.accessibilityLabel
                return action
            }
        }

        // A menu draws an image at its own size, and favicons are kept at up to 64 pixels at scale 1.
        private static func menuIcon(_ favicon: UIImage) -> UIImage {
            let size = CGSize(width: Theme.Metrics.historyFavicon, height: Theme.Metrics.historyFavicon)
            return UIGraphicsImageRenderer(size: size).image { _ in
                favicon.draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> Control {
        let control = Control(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: direction == .back ? "chevron.left" : "chevron.right")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            font: Theme.Typography.navPillGlyphUIFont)
        control.configuration = configuration
        // The press scale is the feedback, and the pill dims a disabled button itself, as for its other buttons.
        control.automaticallyUpdatesConfiguration = false
        control.accessibilityLabel = direction == .back ? "Back" : "Forward"
        let coordinator = context.coordinator
        control.addAction(UIAction { _ in coordinator.parent.onStep() }, for: .primaryActionTriggered)
        control.menu = UIMenu(children: [
            UIDeferredMenuElement.uncached { completion in completion(coordinator.menuElements()) }
        ])
        control.showsMenuAsPrimaryAction = false
        return control
    }

    func updateUIView(_ control: Control, context: Context) {
        context.coordinator.parent = self
        control.tintColor = tint
        control.isEnabled = context.environment.isEnabled
        control.onPress = onPress
    }
}
