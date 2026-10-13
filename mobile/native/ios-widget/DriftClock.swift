import Foundation

struct DriftClock {
    let date: Date
    let calendar: Calendar

    init(date: Date, calendar: Calendar = .autoupdatingCurrent) {
        self.date = date
        self.calendar = calendar
    }

    var seconds: Int {
        calendar.component(.minute, from: date) * 60 + calendar.component(.second, from: date)
    }
    var percentage: Int { seconds / 36 }
    var progress: Double { Double(seconds) / 3600 }
    var minutesLeft: Int { (3600 - seconds + 59) / 60 }
    var phase: String { ["fresh", "flowing", "ticking", "closing"][seconds / 900] }
    var color: UInt32 { [0x4ADE80, 0xFACC15, 0xFB923C, 0xF87171][seconds / 900] }
    var time: String {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return String(format: "%d:%02d %@", hour % 12 == 0 ? 12 : hour % 12, minute, hour < 12 ? "AM" : "PM")
    }

    func timelineDates() -> [Date] {
        let next = Date(timeIntervalSince1970: floor(date.timeIntervalSince1970) + Double(36 - seconds % 36))
        return [date] + (0..<200).map { next.addingTimeInterval(Double($0 * 36)) }
    }
}
