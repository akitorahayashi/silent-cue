import XCTest

final class TimerCompletionViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // TimerCompletionView テスト用の環境設定とアプリの起動
        SCAppEnvironment.setupEnvAndLaunchForTimerCompletionViewTest(for: app)
        XCTAssertTrue(
            app.buttons[SCAccessibilityIdentifiers.TimerCompletionView.okButton.rawValue].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "TimerCompletionView (OK button) should appear on launch with argument"
        )
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testViewElements() throws {
        // Arrange: setUpWithError で TimerCompletionView は表示されているはず

        // Assert: Check for expected elements in TimerCompletionView
        // Note: Specific text might depend on the mock data provided in SilentCueApp.swift for this launch argument.
        //       Adjust the mock store in SilentCueApp.swift if needed.

        // "OK" ボタンが存在するか確認
        let okButton = app.buttons[SCAccessibilityIdentifiers.TimerCompletionView.okButton.rawValue]
        XCTAssertTrue(okButton.exists, "OK button should exist")
        XCTAssertTrue(okButton.isEnabled, "OK button should be enabled")

        // Example: Check if some static text exists.
        //          This might fail if the mock store doesn't provide the necessary data (e.g., completionDate)
        // XCTAssertTrue(app.staticTexts["予定時刻"].exists) // Replace with actual text or identifier if needed
    }

    func testTapOKButton() throws {
        // Arrange: setUpWithError で TimerCompletionView は表示されているはず
        let okButton = app.buttons[SCAccessibilityIdentifiers.TimerCompletionView.okButton.rawValue]
        XCTAssertTrue(okButton.exists, "OK button should exist before tapping")

        // Act: Tap the OK button
        okButton.tap()

        // Assert: Check if returned to SetTimerView
        //         (The app should transition back to the normal flow after dismissing the test view)
        XCTAssertTrue(
            app.buttons[SCAccessibilityIdentifiers.SetTimerView.startTimerButton.rawValue].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "Should return to SetTimerView after tapping OK button"
        )
        // Check that the completion view elements are gone
        XCTAssertFalse(okButton.exists, "OK button should not exist after returning to SetTimerView")

        // Check if the ScrollView of SetTimerView exists as well (using the identifier from the previous test)
        XCTAssertTrue(app.otherElements[SCAccessibilityIdentifiers.SetTimerView.setTimerScrollView.rawValue].exists, "SetTimerScrollView should exist after returning")
    }
} 