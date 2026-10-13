import SwiftUI

struct DriftPanelView: View {
    static let size = CGSize(width: 280, height: 340)

    let engine: DriftTimeEngine

    @State private var showInfo = false
    @State private var showShift = false

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
                .allowsHitTesting(false)

            // Main content
            VStack(spacing: 16) {
                // Ring area
                ZStack {
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
        .frame(width: Self.size.width, height: Self.size.height)
    }
}
