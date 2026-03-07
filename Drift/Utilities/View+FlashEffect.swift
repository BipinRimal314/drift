import SwiftUI

struct FlashEffect: ViewModifier {
    let isFlashing: Bool

    func body(content: Content) -> some View {
        content
            .shadow(
                color: .white.opacity(isFlashing ? 0.15 : 0),
                radius: isFlashing ? 40 : 0
            )
            .animation(DriftAnimations.flash, value: isFlashing)
    }
}

extension View {
    func flashEffect(isFlashing: Bool) -> some View {
        modifier(FlashEffect(isFlashing: isFlashing))
    }
}
