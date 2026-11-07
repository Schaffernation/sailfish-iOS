import SwiftUI
import UIKit

// A deck card's shadow: one blurred rounded rectangle, drawn once and stretched to each card's clip. A view's own
// shadow blurs the card's rendered pixels offscreen on every frame it moves, for every card in the deck; this is a
// picture, so a scroll, lift or zoom only moves it. The picture is drawn around the deck's card corner, and a card
// drawn with a larger corner, as it zooms toward the screen, takes it scaled by the same ratio, its blur growing
// with the card. The card is cut out of it, so a card fading in shows no shadow through itself.
struct CardShadow: View {
    let clip: CardClip
    let screen: CGSize

    private static let corner = Theme.Metrics.cardCorner
    private static let offset = Theme.Metrics.cardShadowOffset
    // How far past the card's edge the picture runs: the blur's tail and the offset, so it fades to nothing inside.
    private static let reach = 2 * Theme.Metrics.cardShadowBlur + max(abs(offset.width), abs(offset.height))
    // The picture's unstretched edge: the reach and the corner. Only the point between the caps stretches.
    private static let cap = reach + corner

    private static let image: UIImage = {
        let side = 2 * cap + 1
        let card = CGRect(x: reach, y: reach, width: 2 * corner + 1, height: 2 * corner + 1)
        let path = UIBezierPath(roundedRect: card, cornerRadius: corner).cgPath
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { renderer in
            let context = renderer.cgContext
            context.setShadow(
                offset: offset, blur: Theme.Metrics.cardShadowBlur,
                color: UIColor.black.withAlphaComponent(Theme.Opacity.cardShadow).cgColor)
            context.addPath(path)
            context.fillPath()
            context.setShadow(offset: .zero, blur: 0, color: nil)
            context.setBlendMode(.clear)
            context.addPath(path)
            context.fillPath()
        }
    }()

    var body: some View {
        let scale = clip.corner / Self.corner
        let height = min(clip.height, screen.height) - clip.top
        Image(uiImage: Self.image)
            .resizable(capInsets: EdgeInsets(top: Self.cap, leading: Self.cap, bottom: Self.cap, trailing: Self.cap))
            .frame(width: screen.width / scale + 2 * Self.reach, height: height / scale + 2 * Self.reach)
            .scaleEffect(scale)
            .offset(y: clip.top + height / 2 - screen.height / 2)
            .frame(width: screen.width, height: screen.height)
    }
}
