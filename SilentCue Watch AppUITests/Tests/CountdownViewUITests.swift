import SCShared
@testable import SilentCue_Watch_App
import XCTest

final class CountdownViewUITests: XCTestCase {
    var app: XCUIApplication!
    // Accessibility Identifiers
    let countdownView = SCAccessibilityIdentifiers.CountdownView.self
    let setTimerView = SCAccessibilityIdentifiers.SetTimerView.self

    override func setUp() {
        continueAfterFailure = false
        let application = XCUIApplication()
        // CountdownView からテストを開始するように環境設定
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .countdownView)
        application.launch()
        app = application

        // デバッグ用に要素階層を出力
        print("--- CountdownView setUp UI Tree Start ---")
        print(app.debugDescription)
        print("--- CountdownView setUp UI Tree End ---")

        // CountdownView の時間表示が表示されることを確認
        XCTAssertTrue(
            app.staticTexts[countdownView.countdownTimeDisplay.rawValue].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "CountdownView should be displayed initially."
        )
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    func testInitialUIElementsExist() throws {
        // 時間表示要素の存在を確認
        let timeDisplay = app.staticTexts[countdownView.countdownTimeDisplay.rawValue]
        XCTAssertTrue(timeDisplay.exists, "時間表示ラベルが存在する")
        // countdownTimeDisplay の存在も確認
        let timeFormatLabel = app.staticTexts[countdownView.countdownTimeDisplay.rawValue]
        XCTAssertTrue(timeFormatLabel.exists, "時間フォーマットラベルが存在する")

        // キャンセルボタンの存在と有効状態を確認
        let cancelButton = app.buttons[countdownView.cancelTimerButton.rawValue]
        XCTAssertTrue(cancelButton.exists, "キャンセルボタンが存在する")
        XCTAssertTrue(cancelButton.isEnabled, "キャンセルボタンが有効である")
    }

    func testCancelButton() throws {
        let cancelButton = app.buttons[countdownView.cancelTimerButton.rawValue]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: UITestConstants.Timeout.standard), "Cancel button should exist.")
        XCTAssertTrue(cancelButton.isEnabled, "Cancel button should be enabled.")
        cancelButton.tap()

        // Verify navigation back to SetTimerView
        XCTAssertTrue(
            app.buttons[setTimerView.startTimerButton.rawValue].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "Should navigate back to SetTimerView after cancel."
        )
    }

    func testPauseAndResumeButton() throws {
        let pauseButton = app.buttons[countdownView.pauseButton.rawValue]
        let resumeButton = app.buttons[countdownView.resumeButton.rawValue]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: UITestConstants.Timeout.standard), "Pause button should exist.")

        // Pause the timer
        pauseButton.tap()
        XCTAssertTrue(resumeButton.waitForExistence(timeout: UITestConstants.Timeout.standard), "Resume button should appear after pause.")
        XCTAssertFalse(pauseButton.exists, "Pause button should disappear after pause.")

        // Resume the timer
        resumeButton.tap()
        XCTAssertTrue(pauseButton.waitForExistence(timeout: UITestConstants.Timeout.standard), "Pause button should reappear after resume.")
        XCTAssertFalse(resumeButton.exists, "Resume button should disappear after resume.")
    }
}
