import SwiftUI
import CoreText

enum DriftFonts {
    static func registerFonts() {
        let fontNames = [
            "JetBrainsMono-Light",
            "JetBrainsMono-Regular",
            "SpaceGrotesk-Medium",
            "SpaceGrotesk-Regular"
        ]
        for name in fontNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else {
                // Fallback: try without subdirectory (flat bundle)
                if let flatURL = Bundle.main.url(forResource: name, withExtension: "ttf") {
                    CTFontManagerRegisterFontsForURL(flatURL as CFURL, .process, nil)
                }
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    // JetBrains Mono
    static func jetbrainsLight(_ size: CGFloat) -> Font {
        .custom("JetBrains Mono Light", size: size)
            .weight(.light)
    }

    static func jetbrainsRegular(_ size: CGFloat) -> Font {
        .custom("JetBrains Mono", size: size)
    }

    // Space Grotesk
    static func spaceGrotesk(_ size: CGFloat) -> Font {
        .custom("Space Grotesk", size: size)
    }

    static func spaceGroteskMedium(_ size: CGFloat) -> Font {
        .custom("Space Grotesk Medium", size: size)
            .weight(.medium)
    }

    // Fallbacks for attributed strings (AppKit)
    static func jetbrainsLightNS(_ size: CGFloat) -> NSFont {
        NSFont(name: "JetBrainsMono-Light", size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .light)
    }

    static func jetbrainsRegularNS(_ size: CGFloat) -> NSFont {
        NSFont(name: "JetBrainsMono-Regular", size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
}
