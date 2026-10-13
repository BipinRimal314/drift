import XCTest

final class DriftUITests: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "com.bipinrimal.drift.mobile")

    override func setUp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        XCTAssertTrue(app.buttons["time-shift"].waitForExistence(timeout: 30))
    }

    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func replace(_ field: XCUIElement, with value: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        let existing = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + value)
    }

    func testClockAndExplanation() {
        XCTAssertTrue(app.staticTexts["THIS HOUR"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "minutes left in this hour")).firstMatch.exists)
        capture("clock")
        app.buttons["why-percentages"].tap()
        XCTAssertTrue(app.staticTexts["At :30, half of the hour has passed. Drift shows this as 50%."].waitForExistence(timeout: 5))
        capture("explanation")
        app.buttons["close-sheet"].tap()
        XCTAssertTrue(app.buttons["time-shift"].isHittable)
    }

    func testShiftValidationPersistenceAndDisable() {
        app.buttons["time-shift"].tap()
        let actual = app.textFields["actual-wake"]
        let ideal = app.textFields["ideal-wake"]
        replace(actual, with: "25:00")
        app.buttons["start-shift"].tap()
        XCTAssertTrue(app.staticTexts["Enter both times in HH:mm format. Hours must be 00 to 23. Minutes must be 00 to 59."].waitForExistence(timeout: 5))
        replace(actual, with: "10:15")
        replace(ideal, with: "06:00")
        capture("shift-form")
        app.buttons["start-shift"].tap()
        XCTAssertTrue(app.staticTexts["shift +4h 15m"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["shift +4h 15m"].waitForExistence(timeout: 30))
        capture("shift-restored")
        app.buttons["time-shift"].tap()
        XCTAssertEqual(app.textFields["actual-wake"].value as? String, "10:15")
        app.buttons["disable-shift"].tap()
        XCTAssertTrue(app.staticTexts["local time"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["local time"].waitForExistence(timeout: 30))
    }

    func testLandscapeAndBackgroundReturn() {
        XCUIDevice.shared.orientation = .landscapeLeft
        for _ in 0..<4 {
            if app.buttons["time-shift"].isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.buttons["time-shift"].isHittable)
        capture("landscape")
        app.buttons["time-shift"].tap()
        XCTAssertTrue(app.textFields["actual-wake"].waitForExistence(timeout: 5))
        app.buttons["close-sheet"].tap()
        XCUIDevice.shared.orientation = .portrait
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["THIS HOUR"].waitForExistence(timeout: 5))
        capture("foreground-return")
    }

    func testOutsideClockPresentation() {
        for _ in 0..<5 {
            if app.buttons["outside-clock"].isHittable { break }
            app.swipeUp()
        }
        app.buttons["outside-clock"].tap()
        XCTAssertTrue(app.staticTexts["Home screen widget"].waitForExistence(timeout: 5))
        capture("outside-choices")
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["iOS does not permit Drift to float over other apps. The home screen widget is available instead."].exists)
        capture("ios-floating-limit")
        app.swipeDown()
        app.buttons["close-sheet"].tap()
    }
}
