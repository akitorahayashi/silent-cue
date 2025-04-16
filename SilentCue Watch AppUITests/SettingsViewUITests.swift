import XCTest

final class SettingsViewUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false

        // テスト用の環境変数を設定
        TestEnvironment.setupStandardTestEnvironment(for: app)

        app.launch()

        // 通知許可の確認・実行
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
        XCTAssertTrue(app.staticTexts.matching(identifier: "VibrationTypeHeader").firstMatch.exists)
    }

    func testVibrationTypeSelection() throws {
        // まず設定画面に移動
        navigateToSettingsView()

        // 弱いスワイプでバイブレーションタイプを表示
        app.swipeUp(velocity: UITestConstants.ScrollVelocity.slow)

        // UIが安定するのを待つ
        XCTAssertTrue(
            app.buttons.matching(identifier: "VibrationTypeOptionStrong").firstMatch
                .waitForExistence(timeout: UITestConstants.Timeout.short),
            "Strongオプションが表示される"
        )

        // 異なるバイブレーションタイプを選択するテスト
        // まず「Strong」を選択
        app.buttons.matching(identifier: "VibrationTypeOptionStrong").firstMatch.tap()

        // さらに弱くスクロールしてLightオプションを表示
        app.swipeUp(velocity: UITestConstants.ScrollVelocity.slow)
        XCTAssertTrue(
            app.buttons.matching(identifier: "VibrationTypeOptionWeak").firstMatch
                .waitForExistence(timeout: UITestConstants.Timeout.short),
            "Weakオプションが表示される"
        )

        // 次に別のタイプを試す
        app.buttons.matching(identifier: "VibrationTypeOptionWeak").firstMatch.tap()
    }

    // 設定画面に移動するヘルパーメソッド
    private func navigateToSettingsView() {
        // 設定ページを開くボタンをアクセシビリティ識別子で特定
        let settingsButton = app.buttons.matching(identifier: "OpenSettingsPage").firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: UITestConstants.Timeout.standard), "設定ボタンが表示される")
        settingsButton.tap()

        // 設定画面が表示されるまで待機
        XCTAssertTrue(
            app.staticTexts["Settings"].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "設定画面のタイトルが表示される"
        )
    }
}
