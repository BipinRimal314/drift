import SwiftUI

struct ButtonRowView: View {
    @Binding var showInfo: Bool
    @Binding var showShift: Bool
    let isShiftActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            // "why 100?" / "hide" button
            Button(action: {
                withAnimation(DriftAnimations.panelFade) {
                    if showInfo {
                        showInfo = false
                    } else {
                        showShift = false
                        showInfo = true
                    }
                }
            }) {
                Text(showInfo ? "hide" : "why 100?")
                    .font(DriftFonts.jetbrainsRegular(10))
                    .tracking(0.1 * 10)
                    .foregroundColor(DriftColors.textTertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DriftColors.disabled, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            // "time shift" / "shift on" button
            Button(action: {
                withAnimation(DriftAnimations.panelFade) {
                    if showShift {
                        showShift = false
                    } else {
                        showInfo = false
                        showShift = true
                    }
                }
            }) {
                HStack(spacing: 5) {
                    if isShiftActive {
                        Circle()
                            .fill(DriftColors.fresh)
                            .frame(width: 5, height: 5)
                            .shadow(color: DriftColors.fresh.opacity(0.375), radius: 2)
                    }
                    Text(isShiftActive ? "shift on" : "time shift")
                        .font(DriftFonts.jetbrainsRegular(10))
                        .tracking(0.1 * 10)
                        .foregroundColor(isShiftActive ? DriftColors.textSecondary : DriftColors.textQuaternary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }
}
