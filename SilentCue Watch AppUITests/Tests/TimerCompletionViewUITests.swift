import SCShared
@testable import SilentCue_Watch_App
import XCTest

final class TimerCompletionViewUITests: XCTestCase {
    var app: XCUIApplication!
    let timerCompletionViewIDs = SCAccessibilityIdentifiers.TimerCompletionView.self

    private func setup() {
        continueAfterFailure = false
        app = XCUIApplication()
        SCAppEnvironment.setupUITestEnv(
            for: app,
            initialView: .timerCompletionView
        )
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    /// 主要なUI要素が正しく表示されること
    /// - 終了時刻、タイマー概要、閉じるボタンは表示される
    func testUIElementsExist() throws {
        setup()

        let notifyEndTimeView = app.otherElements[timerCompletionViewIDs.notifyEndTimeSection.rawValue]
        let closeButton = app.buttons[timerCompletionViewIDs.closeTimeCompletionViewButton.rawValue]
        let timerSummaryView = app.otherElements[timerCompletionViewIDs.timerSummarySection.rawValue]

        XCTAssertTrue(notifyEndTimeView.exists, "終了時刻表示エリアが表示される")
        XCTAssertTrue(closeButton.exists, "閉じるボタンが表示される")
        XCTAssertTrue(timerSummaryView.exists, "タイマー概要エリアが表示される")
    }

    /// 閉じるボタンをタップすると SetTimerView に戻ること
    func testCloseButtonNavigatesBack() throws {
        setup()

        let closeButton = app.buttons[timerCompletionViewIDs.closeTimeCompletionViewButton.rawValue]
        XCTAssertTrue(closeButton.exists, "閉じるボタンが表示される")

        closeButton.tap()

        XCTAssertTrue(
            app.buttons[SCAccessibilityIdentifiers.SetTimerView.startTimerButton.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "閉じるボタンをタップ後、SetTimerViewに遷移する"
        )
    }
}
