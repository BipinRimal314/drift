import XCTest
@testable import Drift

final class ShiftConfigTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: ShiftConfig.storageKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: ShiftConfig.storageKey)
        super.tearDown()
    }

    // MARK: - Offset Calculation

    func testOffsetWhenWakingLate() {
        // Wake at 10:00 instead of 06:00 → +4h = +240min
        let offset = ShiftConfig.calcOffsetMinutes(actualWake: "10:00", idealWake: "06:00")
        XCTAssertEqual(offset, 240)
    }

    func testOffsetWhenWakingEarly() {
        // Wake at 05:00 instead of 07:00 → -2h = -120min
        let offset = ShiftConfig.calcOffsetMinutes(actualWake: "05:00", idealWake: "07:00")
        XCTAssertEqual(offset, -120)
    }

    func testOffsetZero() {
        let offset = ShiftConfig.calcOffsetMinutes(actualWake: "06:00", idealWake: "06:00")
        XCTAssertEqual(offset, 0)
    }

    func testOffsetNormalizesAcrossMidnight() {
        // Wake at 23:00, want 01:00 → should be -2h, not +22h
        let offset = ShiftConfig.calcOffsetMinutes(actualWake: "23:00", idealWake: "01:00")
        XCTAssertEqual(offset, -120)
    }

    func testOffsetWithMinutes() {
        let offset = ShiftConfig.calcOffsetMinutes(actualWake: "10:30", idealWake: "06:00")
        XCTAssertEqual(offset, 270)
    }

    // MARK: - Format

    func testFormatPositiveOffset() {
        XCTAssertEqual(ShiftConfig.formatOffset(240), "shift: +4h 00m")
    }

    func testFormatNegativeOffset() {
        XCTAssertEqual(ShiftConfig.formatOffset(-120), "shift: -2h 00m")
    }

    func testFormatZeroOffset() {
        XCTAssertEqual(ShiftConfig.formatOffset(0), "shift: +0h 00m")
    }

    func testFormatOffsetWithMinutes() {
        XCTAssertEqual(ShiftConfig.formatOffset(270), "shift: +4h 30m")
    }

    // MARK: - Persistence

    func testSaveAndLoad() {
        var config = ShiftConfig(actualWake: "10:00", idealWake: "06:00",
                                 offsetMinutes: 240, enabled: true)
        config.save()

        let loaded = ShiftConfig.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.actualWake, "10:00")
        XCTAssertEqual(loaded?.idealWake, "06:00")
        XCTAssertEqual(loaded?.offsetMinutes, 240)
        XCTAssertEqual(loaded?.enabled, true)
    }

    func testDisable() {
        var config = ShiftConfig(actualWake: "10:00", idealWake: "06:00",
                                 offsetMinutes: 240, enabled: true)
        config.save()

        config.disable()
        let loaded = ShiftConfig.load()
        XCTAssertEqual(loaded?.enabled, false)
    }

    func testLoadReturnsNilWhenEmpty() {
        XCTAssertNil(ShiftConfig.load())
    }

    // MARK: - Shifted Date

    func testShiftedDate() {
        let now = Date()
        let shifted = ShiftConfig.shiftedDate(from: now, offsetMinutes: 240)
        let diff = now.timeIntervalSince(shifted)
        XCTAssertEqual(diff, 14400, accuracy: 1) // 240 * 60 = 14400s
    }
}
