import SwiftUI

struct InfoOverlayView: View {
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                (Text("Your brain thinks in percentages, not sixths. When a clock says ")
                 + Text(":30").foregroundColor(DriftColors.textHighlight)
                 + Text(", it doesn\u{2019}t ")
                 + Text("feel").italic()
                 + Text(" like half. But ")
                 + Text("50%").foregroundColor(DriftColors.textHighlight)
                 + Text(" does.")
                 + Text("\n\nThis is time in a language your mind already speaks."))
                    .font(DriftFonts.spaceGrotesk(12))
                    .foregroundColor(Color(hex: "A1A1AA"))
                    .lineSpacing(12 * 0.7)
                    .multilineTextAlignment(.center)
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
            .onTapGesture {
                withAnimation(DriftAnimations.panelFade) {
                    isVisible = false
                }
            }
        }
    }
}
