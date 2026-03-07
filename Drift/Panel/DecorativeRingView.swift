import SwiftUI

struct DecorativeRingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .stroke(
                Color.white.opacity(0.08),
                style: StrokeStyle(lineWidth: 0.5, dash: [2, 8])
            )
            .frame(width: 210, height: 210)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(DriftAnimations.decorativeRotation) {
                    rotation = 360
                }
            }
    }
}
