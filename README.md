# Drift (Native)

macOS menubar app that shows the current hour as a percentage (0–100%) instead of minutes. Built for ADHD-adjacent brains that think in percentages, not base-60.

This is the native Swift/SwiftUI rewrite. The original Electron version lives in `../clock/`.

## What Changed

| Metric | Electron | Native |
|--------|----------|--------|
| Binary | ~95MB | <5MB |
| Memory | ~100MB | ~20MB |
| Startup | 2-3s | <200ms |
| CPU idle | 0.1-0.5% | Undetectable |

## Requirements

- macOS 14.0+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for project generation)

## Build

```bash
# Generate Xcode project (only needed once, or after changing project.yml)
xcodegen generate

# Build from command line
xcodebuild build -scheme Drift -destination 'platform=macOS'

# Or open in Xcode
open Drift.xcodeproj
```

## Test

```bash
xcodebuild test -scheme Drift -destination 'platform=macOS'
```

## Architecture

**Hybrid AppKit + SwiftUI:**

- `NSStatusItem` (AppKit) for menubar text — SwiftUI's `MenuBarExtra` can't do custom dark transparent panels
- `NSPanel` subclass (AppKit) for the frameless, transparent floating window
- SwiftUI views inside the panel via `NSHostingView`
- `NSMenu` (AppKit) for right-click context menu

### File Structure

```
Drift/
├── App/
│   ├── DriftApp.swift              # @main entry
│   └── AppDelegate.swift           # NSStatusItem, panel, context menu
├── Core/
│   ├── DriftTimeEngine.swift       # @Observable: percentage, phase, shift
│   └── ShiftConfig.swift           # Codable + UserDefaults persistence
├── Panel/
│   ├── DriftPanelWindow.swift      # NSPanel subclass (borderless, transparent)
│   ├── DriftPanelView.swift        # Root SwiftUI composition
│   ├── ProgressRingView.swift      # Circle().trim() ring
│   ├── TickMarksView.swift         # Canvas quarter tick marks
│   ├── DecorativeRingView.swift    # 120s rotating dashed ring
│   ├── CenterContentView.swift     # Percentage + clock time
│   ├── PhaseIndicatorView.swift    # Pulsing dot + phase label
│   ├── SegmentBarView.swift        # 4 progress segments
│   ├── ButtonRowView.swift         # "why 100?" and "time shift"
│   ├── InfoOverlayView.swift       # Philosophy explanation
│   └── ShiftOverlayView.swift      # Time shift configuration
├── Theme/
│   ├── DriftColors.swift           # All color constants
│   ├── DriftFonts.swift            # Font registration + accessors
│   └── DriftAnimations.swift       # Named timing curves
├── Resources/
│   ├── Assets.xcassets/
│   ├── Fonts/                      # JetBrains Mono + Space Grotesk
│   ├── Info.plist
│   └── Drift.entitlements
└── Utilities/
    ├── Color+Hex.swift
    └── View+FlashEffect.swift
```

## Phases

- **Fresh** (0–24%): Green `#4ADE80`
- **Flowing** (25–49%): Yellow `#FACC15`
- **Ticking** (50–74%): Orange `#FB923C`
- **Closing** (75–100%): Red `#F87171`

## License

MIT
