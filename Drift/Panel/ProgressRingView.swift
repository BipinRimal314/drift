import SwiftUI

struct ProgressRingView: View {
    let percentage: Double
    let phase: PhaseInfo

    private let radius: CGFloat = 88
    private let lineWidth: CGFloat = 6
    private let size: CGFloat = 220

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(DriftColors.ringTrack, lineWidth: lineWidth)
                .frame(width: radius * 2, height: radius * 2)

            // Progress
            Circle()
                .trim(from: 0, to: percentage / 100)
                .stroke(
                    phase.ring,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .shadow(color: phase.ring.opacity(0.25), radius: 6)
                .animation(DriftAnimations.ringProgress, value: percentage)
                .animation(DriftAnimations.colorTransition, value: phase.label)
        }
        .frame(width: size, height: size)
    }
}
