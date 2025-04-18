import XCTest

final class SettingsViewUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false

        // 環境設定を行い、アプリを起動する
        SCAppEnvironment.setupEnvironment(for: app, launchArgument: .testingSettingsView)
        app.launch()
        NotificationPermissionHelper.ensureNotificationPermission(for: app)

        XCTAssertTrue(
            app.staticTexts["Silent Cue"].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "アプリタイトルが表示される"
        )
    }

    func testSettingsViewInitialDisplay() throws {
        // まず設定画面に移動
        navigateToSettingsView()

        // 設定タイトルが表示されているか確認
        XCTAssertTrue(app.staticTexts["Settings"].exists)

        // バイブレーションタイプセクションが表示されているか確認
        XCTAssertTrue(
            app.staticTexts
                .matching(identifier: SCAccessibilityIdentifiers.SettingsView.vibrationTypeHeader.rawValue).firstMatch
                .exists
        )
    }

    func testInitialUIElementsExist() {
        // Arrange
        navigateToSettingsView()

        // Assert
        XCTAssertTrue(
            app.staticTexts.matching(identifier: SCAccessibilityIdentifiers.SettingsView.vibrationTypeHeader.rawValue)
                .firstMatch.exists,
            "Vibration type header should exist"
        )
        // デフォルトでStandardが選択されていることを確認
        let standardOption = app.buttons
            .matching(identifier: SCAccessibilityIdentifiers.SettingsView.vibrationTypeOptionStandard.rawValue)
            .firstMatch
        XCTAssertTrue(standardOption.exists, "Standard option should exist")
        // checkmarkの存在で選択状態を確認するのは難しい場合があるため、別の方法（例: 選択後の動作）を検討
    }

    func testSelectVibrationType() {
        // Arrange
        navigateToSettingsView()
        let strongOption = app.buttons
            .matching(identifier: SCAccessibilityIdentifiers.SettingsView.vibrationTypeOptionStrong.rawValue).firstMatch

        // Act
        XCTAssertTrue(
            strongOption.waitForExistence(timeout: UITestConstants.Timeout.short),
            "Strong option should exist"
        )
        strongOption.tap()

        // Assert
        // Strongが選択されたことを確認（UI上での明確な確認は難しい場合がある）
        // 例: 別のオプションをタップして再度Strongを選択した際の動作を確認するなど

        // Weakを選択
        let weakOption = app.buttons
            .matching(identifier: SCAccessibilityIdentifiers.SettingsView.vibrationTypeOptionWeak.rawValue).firstMatch
        XCTAssertTrue(weakOption.waitForExistence(timeout: UITestConstants.Timeout.short), "Weak option should exist")
        weakOption.tap()

        // Assert
        // Weakが選択されたことを確認
    }

    // Helper function to navigate to SettingsView
    private func navigateToSettingsView() {
        // SetTimerViewから設定ボタンをタップ
        let settingsButton = app.buttons
            .matching(identifier: SCAccessibilityIdentifiers.SetTimerView.openSettingsPage.rawValue).firstMatch
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: UITestConstants.Timeout.standard),
            "Settings button should exist on SetTimerView"
        )
        settingsButton.tap()

        // SettingsViewが表示されるのを待つ
        XCTAssertTrue(
            app.navigationBars["Settings"].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "Settings view navigation bar should appear"
        )
    }
}
