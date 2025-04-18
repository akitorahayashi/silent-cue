import XCTest

final class CountdownViewUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false

        // CountdownView テスト用の環境設定とアプリの起動
        SCAppEnvironment.setupEnvAndLaunchForCountdownViewTest(for: app)

        XCTAssertTrue(
            app.staticTexts["Silent Cue"].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "アプリタイトルが表示される"
        )
    }

    func testInitialUIElementsExist() {
        // Arrange
        navigateToCountdownView()

        // Assert
        let timeFormatExists = app.staticTexts
            .matching(identifier: SCAccessibilityIdentifiers.CountdownView.timeFormatLabel.rawValue).firstMatch
        XCTAssertTrue(timeFormatExists.exists, "時間フォーマットラベルが存在する")

        let timeDisplayExists = app.staticTexts
            .matching(identifier: SCAccessibilityIdentifiers.CountdownView.countdownTimeDisplay.rawValue).firstMatch
        XCTAssertTrue(timeDisplayExists.exists, "カウントダウン時間表示が存在する")

        let cancelButtonExists = app.buttons
            .matching(identifier: SCAccessibilityIdentifiers.CountdownView.cancelTimerButton.rawValue).firstMatch
        XCTAssertTrue(cancelButtonExists.exists, "キャンセルボタンが存在する")
    }

    func testTimerUpdatesTimeDisplay() {
        // Arrange
        navigateToCountdownView()

        let initialTimeDisplay = app.staticTexts
            .matching(identifier: SCAccessibilityIdentifiers.CountdownView.timeFormatLabel.rawValue).firstMatch.label

        // Act
        // 1秒待機して時間が更新されることを確認
        sleep(1)

        // Assert
        let updatedTimeDisplay = app.staticTexts
            .matching(identifier: SCAccessibilityIdentifiers.CountdownView.timeFormatLabel.rawValue).firstMatch.label
        XCTAssertNotEqual(initialTimeDisplay, updatedTimeDisplay, "1秒後に時間表示が更新される")
    }

    func testCancelButtonReturnsToSetTimerView() {
        // Arrange
        navigateToCountdownView()
        let cancelButton = app.buttons
            .matching(identifier: SCAccessibilityIdentifiers.CountdownView.cancelTimerButton.rawValue).firstMatch

        // Act
        cancelButton.tap()

        // Assert
        // SetTimerViewに戻ったことを確認 (例: Startボタンの存在)
        XCTAssertTrue(
            app.buttons[SCAccessibilityIdentifiers.SetTimerView.startTimerButton.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "キャンセル後に SetTimerView に戻る"
        )
    }

    // Helper function to navigate to CountdownView
    private func navigateToCountdownView(minutes: Int = 1) {
        // SetTimerView でタイマーを設定して開始
        let minutePickerWheel = app.pickers.pickerWheels.firstMatch
        if minutePickerWheel.waitForExistence(timeout: UITestConstants.Timeout.short) {
            minutePickerWheel.adjust(toPickerWheelValue: "\(minutes)")
        }
        // StartTimerButtonを見つけてタップ
        let startButton = app.buttons
            .matching(identifier: SCAccessibilityIdentifiers.SetTimerView.startTimerButton.rawValue).firstMatch
        XCTAssertTrue(startButton.waitForExistence(timeout: UITestConstants.Timeout.short), "開始ボタンが存在する")
        startButton.tap()

        // CountdownViewが表示されるのを待つ
        XCTAssertTrue(
            app.staticTexts[SCAccessibilityIdentifiers.CountdownView.countdownTimeDisplay.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "カウントダウンビューが表示される"
        )
    }
}
