import SwiftUI
import Combine

@Observable
final class DriftTimeEngine {
    // Published state
    private(set) var percentage: Double = 0
    private(set) var displayPercentage: Int = 0
    private(set) var phase: PhaseInfo = PhaseInfo.from(percentage: 0)
    private(set) var minutesLeft: Int = 60
    private(set) var clockTimeString: String = ""
    private(set) var localTimeString: String = ""
    private(set) var isShiftActive: Bool = false
    private(set) var isFlashing: Bool = false

    private var timer: Timer?
    private var previousPercentage: Double = 0
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    init() {
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Public

    var menubarText: String {
        " \(displayPercentage)%"
    }

    func toggleShift(actualWake: String, idealWake: String) {
        let offset = ShiftConfig.calcOffsetMinutes(actualWake: actualWake, idealWake: idealWake)
        let config = ShiftConfig(actualWake: actualWake, idealWake: idealWake,
                                 offsetMinutes: offset, enabled: true)
        config.save()
        tick()
    }

    func disableShift() {
        if var config = ShiftConfig.load() {
            config.disable()
        }
        tick()
    }

    // MARK: - Private

    private func tick() {
        let now = Date()
        let calendar = Calendar.current
        let minutes = calendar.component(.minute, from: now)
        let seconds = calendar.component(.second, from: now)

        percentage = Double(minutes * 60 + seconds) / 3600.0 * 100.0
        displayPercentage = Int(percentage)
        phase = PhaseInfo.from(percentage: percentage)
        minutesLeft = Int(ceil((100.0 - percentage) / 100.0 * 60.0))

        // Shift handling
        let config = ShiftConfig.load()
        isShiftActive = config?.enabled ?? false

        if let config, config.enabled {
            let shifted = ShiftConfig.shiftedDate(from: now, offsetMinutes: config.offsetMinutes)
            clockTimeString = timeFormatter.string(from: shifted)
            localTimeString = timeFormatter.string(from: now)
        } else {
            clockTimeString = timeFormatter.string(from: now)
            localTimeString = ""
        }

        // Flash detection at quarter boundaries
        checkFlash()
        previousPercentage = percentage
    }

    private func checkFlash() {
        let prev = previousPercentage
        let curr = percentage
        let crossed = (prev < 25 && curr >= 25) ||
                      (prev < 50 && curr >= 50) ||
                      (prev < 75 && curr >= 75) ||
                      (prev > 90 && curr < 10)

        if crossed {
            isFlashing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.isFlashing = false
            }
        }
    }
}
