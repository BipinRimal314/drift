import SwiftUI

struct SegmentBarView: View {
    let percentage: Double
    let phase: PhaseInfo

    private let ticks: [Double] = [0, 25, 50, 75]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(segmentColor(for: i))
                    .frame(width: 40, height: 3)
            }
        }
        .animation(DriftAnimations.colorTransition, value: phase.label)
    }

    private func segmentColor(for index: Int) -> Color {
        let tick = ticks[index]
        if percentage >= tick + 25 {
            return phase.ring  // Fully filled
        } else if percentage >= tick {
            return phase.ring.opacity(0.375)  // Partially filled (0x60 = 37.5%)
        } else {
            return DriftColors.segmentEmpty
        }
    }
}
