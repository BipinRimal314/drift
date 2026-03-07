import SwiftUI

struct CenterContentView: View {
    let displayPercentage: Int
    let clockTime: String
    let localTime: String
    let isShiftActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Percentage
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(displayPercentage)")
                    .font(DriftFonts.jetbrainsLight(52))
                    .tracking(-0.02 * 52)
                    .foregroundColor(DriftColors.textHighlight)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("%")
                    .font(DriftFonts.jetbrainsRegular(20))
                    .foregroundColor(DriftColors.textTertiary)
                    .padding(.leading, 2)
            }

            // Clock time
            Text(clockTime)
                .font(DriftFonts.jetbrainsRegular(12))
                .foregroundColor(DriftColors.textSecondary)
                .padding(.top, 6)

            // Local time (when shift is active)
            if isShiftActive {
                HStack(spacing: 5) {
                    Text("LOCAL")
                        .font(DriftFonts.spaceGrotesk(8))
                        .tracking(0.08 * 8)
                        .foregroundColor(DriftColors.textQuaternary)
                        .textCase(.uppercase)

                    Text(localTime)
                        .font(DriftFonts.jetbrainsRegular(10))
                        .foregroundColor(DriftColors.textTertiary)
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
    }
}
