import SCShared
@testable import SilentCue_Watch_App
import XCTest

final class TimerCompletionViewUITests: XCTestCase {
    var app: XCUIApplication!
    // Accessibility Identifiers
    let timerCompletionView = SCAccessibilityIdentifiers.TimerCompletionView.self
    let setTimerView = SCAccessibilityIdentifiers.SetTimerView.self
    // countdownViewのAccessibility Identifierを追加する必要がある
    let countdownView = SCAccessibilityIdentifiers.CountdownView.self

    override func setUp() {
        continueAfterFailure = false
        let application = XCUIApplication()
        // TimerCompletionView からテストを開始するように環境設定
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .timerCompletionView)
        application.launch()
        app = application

        XCTAssertTrue(
            app.staticTexts[timerCompletionView.completionMessage.rawValue].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "TimerCompletionView should be displayed initially."
        )
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    func testInitialUIElementsExist() throws {
        let completionMessage = app.staticTexts[timerCompletionView.completionMessage.rawValue]
        let finishButton = app.buttons[timerCompletionView.finishButton.rawValue]
        let restartButton = app.buttons[timerCompletionView.restartButton.rawValue]

        XCTAssertTrue(completionMessage.exists)
        XCTAssertTrue(finishButton.exists)
        XCTAssertTrue(restartButton.exists)
    }

    func testFinishButtonAction() throws {
        let finishButton = app.buttons[timerCompletionView.finishButton.rawValue]
        XCTAssertTrue(finishButton.exists)
        finishButton.tap()

        XCTAssertTrue(
            app.buttons[setTimerView.startTimerButton.rawValue].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "Should navigate back to SetTimerView after tapping Finish."
        )
    }

    func testRestartButtonAction() throws {
        let restartButton = app.buttons[timerCompletionView.restartButton.rawValue]
        XCTAssertTrue(restartButton.exists)
        restartButton.tap()

        XCTAssertTrue(
            app.staticTexts[countdownView.countdownTimeDisplay.rawValue].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "Should navigate to CountdownView after tapping Restart."
        )
    }
}
