import Foundation

@main
struct ClockCheck {
    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kathmandu")!
        func clock(_ time: String) -> DriftClock {
            let date = ISO8601DateFormatter().date(from: "2026-10-13T\(time)+05:45")!
            return DriftClock(date: date, calendar: calendar)
        }
        assert(clock("00:00:00").percentage == 0)
        assert(clock("00:00:00").time == "12:00 AM")
        assert(clock("00:00:35").percentage == 0)
        assert(clock("00:00:36").percentage == 1)
        assert(clock("12:15:00").phase == "flowing")
        assert(clock("12:30:00").phase == "ticking")
        assert(clock("12:45:00").phase == "closing")
        assert(clock("23:59:59").percentage == 99)
        assert(clock("23:59:59").minutesLeft == 1)
        let dates = clock("23:59:59").timelineDates()
        assert(dates[1].timeIntervalSince(dates[0]) == 1)
        assert(DriftClock(date: dates[1], calendar: calendar).percentage == 0)
        assert(dates[2].timeIntervalSince(dates[1]) == 36)
        assert(DriftClock(date: dates[2], calendar: calendar).percentage == 1)
        print("iOS widget clock checks passed")
    }
}
