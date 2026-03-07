import SwiftUI

enum DriftColors {
    // Phase colors
    static let fresh    = Color(hex: "4ADE80")
    static let flowing  = Color(hex: "FACC15")
    static let ticking  = Color(hex: "FB923C")
    static let closing  = Color(hex: "F87171")

    // Backgrounds
    static let panelBg      = Color(hex: "0A0A0B")
    static let infoBg       = Color(hex: "0F0F10")
    static let inputBg      = Color(hex: "18181B")

    // Text
    static let textPrimary    = Color(hex: "E4E4E7")
    static let textHighlight  = Color(hex: "FAFAFA")
    static let textSecondary  = Color(hex: "71717A")
    static let textTertiary   = Color(hex: "52525B")
    static let textQuaternary = Color(hex: "3F3F46")

    // Structural
    static let disabled  = Color(hex: "27272A")
    static let border    = Color(hex: "1C1C1E")
    static let ringTrack = Color(hex: "18181B")

    // Segment empty
    static let segmentEmpty = Color(hex: "1C1C1E")

    // NSColor versions for AppKit
    static let panelBgNS = NSColor(hex: "0A0A0B")
}

struct PhaseInfo {
    let ring: Color
    let ringHex: String
    let glow: Color
    let label: String

    static func from(percentage: Double) -> PhaseInfo {
        if percentage < 25 {
            return PhaseInfo(ring: DriftColors.fresh, ringHex: "4ADE80",
                           glow: Color(hex: "4ADE80", opacity: 0.15), label: "fresh")
        } else if percentage < 50 {
            return PhaseInfo(ring: DriftColors.flowing, ringHex: "FACC15",
                           glow: Color(hex: "FACC15", opacity: 0.12), label: "flowing")
        } else if percentage < 75 {
            return PhaseInfo(ring: DriftColors.ticking, ringHex: "FB923C",
                           glow: Color(hex: "FB923C", opacity: 0.12), label: "ticking")
        } else {
            return PhaseInfo(ring: DriftColors.closing, ringHex: "F87171",
                           glow: Color(hex: "F87171", opacity: 0.15), label: "closing")
        }
    }
}
