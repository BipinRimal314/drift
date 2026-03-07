import SwiftUI

struct DriftPanelView: View {
    let engine: DriftTimeEngine

    @State private var showInfo = false
    @State private var showShift = false
    @State private var glowScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background
            DriftColors.panelBg
                .ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(engine.phase.glow)
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .scaleEffect(glowScale)
                .allowsHitTesting(false)
                .onAppear {
                    withAnimation(DriftAnimations.subtlePulse) {
                        glowScale = 1.01
                    }
                }

            // Main content
            VStack(spacing: 16) {
                // Title
                Text("DRIFT")
                    .font(DriftFonts.spaceGroteskMedium(11))
                    .tracking(0.2 * 11)
                    .foregroundColor(DriftColors.textTertiary)

                // Ring area
                ZStack {
                    DecorativeRingView()
                    TickMarksView(percentage: engine.percentage, phase: engine.phase)
                    ProgressRingView(percentage: engine.percentage, phase: engine.phase)
                    CenterContentView(
                        displayPercentage: engine.displayPercentage,
                        clockTime: engine.clockTimeString,
                        localTime: engine.localTimeString,
                        isShiftActive: engine.isShiftActive
                    )
                }
                .frame(width: 220, height: 220)

                // Phase indicator
                PhaseIndicatorView(phase: engine.phase, minutesLeft: engine.minutesLeft)

                // Segment bar
                SegmentBarView(percentage: engine.percentage, phase: engine.phase)

                // Button row
                ButtonRowView(
                    showInfo: $showInfo,
                    showShift: $showShift,
                    isShiftActive: engine.isShiftActive
                )
            }
            .flashEffect(isFlashing: engine.isFlashing)
            .opacity(1)
            .animation(DriftAnimations.fadeIn, value: true)

            // Signature
            VStack {
                Spacer()
                Text("DESIGNED FOR ADHD BRAINS")
                    .font(DriftFonts.spaceGrotesk(9))
                    .tracking(0.15 * 9)
                    .foregroundColor(DriftColors.disabled)
                    .padding(.bottom, 20)
            }

            // Overlays
            VStack {
                Spacer()
                InfoOverlayView(isVisible: $showInfo)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }

            VStack {
                Spacer()
                ShiftOverlayView(isVisible: $showShift, engine: engine)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
        .frame(width: 280, height: 420)
    }
}
