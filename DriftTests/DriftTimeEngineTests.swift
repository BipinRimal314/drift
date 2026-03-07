import XCTest
@testable import Drift

final class DriftTimeEngineTests: XCTestCase {

    func testPercentageRangeIsValid() {
        let engine = DriftTimeEngine()
        XCTAssertGreaterThanOrEqual(engine.percentage, 0)
        XCTAssertLessThan(engine.percentage, 100)
    }

    func testDisplayPercentageIsFloor() {
        let engine = DriftTimeEngine()
        XCTAssertEqual(engine.displayPercentage, Int(engine.percentage))
    }

    func testMinutesLeftIsPositive() {
        let engine = DriftTimeEngine()
        XCTAssertGreaterThan(engine.minutesLeft, 0)
        XCTAssertLessThanOrEqual(engine.minutesLeft, 60)
    }

    func testMenubarTextFormat() {
        let engine = DriftTimeEngine()
        let text = engine.menubarText
        XCTAssertTrue(text.hasPrefix(" "))
        XCTAssertTrue(text.hasSuffix("%"))
    }

    func testPhaseColorAtBoundaries() {
        XCTAssertEqual(PhaseInfo.from(percentage: 0).label, "fresh")
        XCTAssertEqual(PhaseInfo.from(percentage: 24.9).label, "fresh")
        XCTAssertEqual(PhaseInfo.from(percentage: 25).label, "flowing")
        XCTAssertEqual(PhaseInfo.from(percentage: 49.9).label, "flowing")
        XCTAssertEqual(PhaseInfo.from(percentage: 50).label, "ticking")
        XCTAssertEqual(PhaseInfo.from(percentage: 74.9).label, "ticking")
        XCTAssertEqual(PhaseInfo.from(percentage: 75).label, "closing")
        XCTAssertEqual(PhaseInfo.from(percentage: 99.9).label, "closing")
    }

    func testClockTimeStringIsNotEmpty() {
        let engine = DriftTimeEngine()
        XCTAssertFalse(engine.clockTimeString.isEmpty)
    }
}
