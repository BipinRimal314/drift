import SwiftUI

enum DriftAnimations {
    // Ring progress — matches CSS cubic-bezier(0.4, 0, 0.2, 1)
    static let ringProgress = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 1.0)

    // Color transitions — 0.8s ease
    static let colorTransition = Animation.easeInOut(duration: 0.8)

    // Button hover — 0.3s ease
    static let buttonHover = Animation.easeInOut(duration: 0.3)

    // Fade in — 0.6s ease-out
    static let fadeIn = Animation.easeOut(duration: 0.6)

    // Info panel fade — 0.4s ease-out
    static let panelFade = Animation.easeOut(duration: 0.4)

    // Flash border — 0.8s ease-out
    static let flash = Animation.easeOut(duration: 0.8)

    // Decorative ring rotation — 120s linear
    static let decorativeRotation = Animation.linear(duration: 120).repeatForever(autoreverses: false)

    // Pulse glow — 2s ease-in-out infinite
    static let pulseGlow = Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)

    // Subtle pulse — 4s ease-in-out infinite
    static let subtlePulse = Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)

    // Panel show/hide — 400ms
    static let panelToggle = Animation.easeOut(duration: 0.4)
}
