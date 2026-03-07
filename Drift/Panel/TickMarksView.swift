import SwiftUI

struct TickMarksView: View {
    let percentage: Double
    let phase: PhaseInfo

    private let ticks: [Double] = [0, 25, 50, 75]
    private let outerRadius: CGFloat = 96
    private let innerRadius: CGFloat = 88
    private let center: CGFloat = 110

    var body: some View {
        Canvas { context, size in
            for tick in ticks {
                let angle = Angle.degrees(tick / 100 * 360 - 90)
                let cos = cos(angle.radians)
                let sin = sin(angle.radians)

                let x1 = center + outerRadius * cos
                let y1 = center + outerRadius * sin
                let x2 = center + innerRadius * cos
                let y2 = center + innerRadius * sin

                var path = Path()
                path.move(to: CGPoint(x: x1, y: y1))
                path.addLine(to: CGPoint(x: x2, y: y2))

                let color: Color = percentage >= tick ? phase.ring : DriftColors.disabled
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }
        .frame(width: 220, height: 220)
        .animation(DriftAnimations.colorTransition, value: phase.label)
    }
}
