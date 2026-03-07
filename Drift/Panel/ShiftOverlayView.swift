import SwiftUI

struct ShiftOverlayView: View {
    @Binding var isVisible: Bool
    let engine: DriftTimeEngine

    @State private var actualWake: String = "10:00"
    @State private var idealWake: String = "06:00"

    private var offsetMinutes: Int {
        ShiftConfig.calcOffsetMinutes(actualWake: actualWake, idealWake: idealWake)
    }

    private var offsetText: String {
        ShiftConfig.formatOffset(offsetMinutes)
    }

    private var isShiftActive: Bool {
        ShiftConfig.load()?.enabled ?? false
    }

    var body: some View {
        if isVisible {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("TIME SHIFT")
                    .font(DriftFonts.spaceGroteskMedium(11))
                    .tracking(0.15 * 11)
                    .foregroundColor(Color(hex: "A1A1AA"))
                    .padding(.bottom, 6)

                // Description
                Text("See what time it would be if you woke up on schedule.")
                    .font(DriftFonts.spaceGrotesk(11))
                    .foregroundColor(DriftColors.textSecondary)
                    .lineSpacing(11 * 0.5)
                    .padding(.bottom, 14)

                // Fields
                VStack(spacing: 10) {
                    ShiftField(label: "I ACTUALLY WAKE UP AT", value: $actualWake)
                    ShiftField(label: "I WANT TO WAKE UP AT", value: $idealWake)
                }
                .padding(.bottom, 12)

                // Preview
                Text(offsetText)
                    .font(DriftFonts.jetbrainsRegular(12))
                    .tracking(0.05 * 12)
                    .foregroundColor(offsetMinutes == 0 ? DriftColors.textTertiary : DriftColors.fresh)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 14)

                // Actions
                HStack {
                    Spacer()

                    Button("cancel") {
                        withAnimation(DriftAnimations.panelFade) {
                            isVisible = false
                        }
                    }
                    .buttonStyle(ShiftButtonStyle(color: DriftColors.textTertiary))

                    if isShiftActive {
                        Button("turn off") {
                            engine.disableShift()
                            withAnimation(DriftAnimations.panelFade) {
                                isVisible = false
                            }
                        }
                        .buttonStyle(ShiftButtonStyle(color: DriftColors.closing))
                    }

                    Button("start") {
                        engine.toggleShift(actualWake: actualWake, idealWake: idealWake)
                        withAnimation(DriftAnimations.panelFade) {
                            isVisible = false
                        }
                    }
                    .buttonStyle(ShiftStartButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(DriftColors.infoBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DriftColors.border, lineWidth: 1)
            )
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .onAppear {
                if let config = ShiftConfig.load() {
                    actualWake = config.actualWake
                    idealWake = config.idealWake
                }
            }
        }
    }
}

// MARK: - Shift Field

private struct ShiftField: View {
    let label: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DriftFonts.spaceGrotesk(9))
                .tracking(0.08 * 9)
                .foregroundColor(DriftColors.textTertiary)

            TextField("", text: $value)
                .font(DriftFonts.jetbrainsRegular(13))
                .foregroundColor(DriftColors.textPrimary)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(DriftColors.inputBg)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(DriftColors.disabled, lineWidth: 1)
                )
        }
    }
}

// MARK: - Button Styles

private struct ShiftButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DriftFonts.jetbrainsRegular(10))
            .tracking(0.1 * 10)
            .foregroundColor(color.opacity(configuration.isPressed ? 0.7 : 1))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
    }
}

private struct ShiftStartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DriftFonts.jetbrainsRegular(10))
            .tracking(0.1 * 10)
            .foregroundColor(DriftColors.fresh)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(DriftColors.fresh.opacity(configuration.isPressed ? 0.19 : 0.125))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
