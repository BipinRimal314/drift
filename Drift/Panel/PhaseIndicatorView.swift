import SwiftUI

struct PhaseIndicatorView: View {
    let phase: PhaseInfo
    let minutesLeft: Int

    var body: some View {
        HStack(spacing: 8) {
            // Phase label
            Text(phase.label)
                .font(DriftFonts.spaceGroteskMedium(11))
                .tracking(0.15 * 11)
                .textCase(.uppercase)
                .foregroundColor(phase.ring)

            // Separator
            Text("\u{00B7}")
                .font(DriftFonts.spaceGrotesk(11))
                .foregroundColor(DriftColors.textQuaternary)

            // Minutes left
            Text("\(minutesLeft)m left")
                .font(DriftFonts.jetbrainsRegular(11))
                .foregroundColor(DriftColors.textTertiary)
        }
        .animation(DriftAnimations.colorTransition, value: phase.label)
    }
}
