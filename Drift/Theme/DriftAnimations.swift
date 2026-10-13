import SwiftUI

enum DriftAnimations {
    // Ring progress — matches CSS cubic-bezier(0.4, 0, 0.2, 1)
    static let ringProgress = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 1.0)

    // Color transitions — 0.8s ease
    static let colorTransition = Animation.easeInOut(duration: 0.8)

    // Info panel fade — 0.4s ease-out
    static let panelFade = Animation.easeOut(duration: 0.4)

    // Flash border — 0.8s ease-out
    static let flash = Animation.easeOut(duration: 0.8)
}
