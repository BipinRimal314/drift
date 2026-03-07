import Foundation

struct ShiftConfig: Codable, Equatable {
    var actualWake: String  // "HH:mm"
    var idealWake: String   // "HH:mm"
    var offsetMinutes: Int
    var enabled: Bool

    static let storageKey = "driftShift"

    // MARK: - Persistence

    static func load() -> ShiftConfig? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(ShiftConfig.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    mutating func disable() {
        enabled = false
        save()
    }

    // MARK: - Offset Calculation

    static func calcOffsetMinutes(actualWake: String, idealWake: String) -> Int {
        let actual = parseTime(actualWake)
        let ideal = parseTime(idealWake)
        var diff = actual - ideal
        // Normalize to ±12 hours
        if diff > 720 { diff -= 1440 }
        if diff < -720 { diff += 1440 }
        return diff
    }

    static func formatOffset(_ minutes: Int) -> String {
        let sign = minutes >= 0 ? "+" : "-"
        let abs = abs(minutes)
        let h = abs / 60
        let m = abs % 60
        return "shift: \(sign)\(h)h \(String(format: "%02d", m))m"
    }

    static func shiftedDate(from date: Date, offsetMinutes: Int) -> Date {
        date.addingTimeInterval(TimeInterval(-offsetMinutes * 60))
    }

    // MARK: - Private

    private static func parseTime(_ str: String) -> Int {
        let parts = str.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }
}
