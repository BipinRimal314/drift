import SwiftUI

struct PhaseIndicatorView: View {
    let phase: PhaseInfo
    let minutesLeft: Int

    @State private var dotOpacity: Double = 0.4

    var body: some View {
        HStack(spacing: 8) {
            // Pulsing dot
            Circle()
                .fill(phase.ring)
                .frame(width: 6, height: 6)
                .shadow(color: phase.ring.opacity(0.375), radius: 4)
                .opacity(dotOpacity)
                .onAppear {
                    withAnimation(DriftAnimations.pulseGlow) {
                        dotOpacity = 0.8
                    }
                }

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
