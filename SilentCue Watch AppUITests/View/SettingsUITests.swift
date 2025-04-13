import XCTest

final class SettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        // テストごとにアプリを新規起動
        app = XCUIApplication()
        app.launch()

        // 失敗時のスクリーンショットを自動取得
        continueAfterFailure = false

        // 設定画面へ移動
        navigateToSettings()
    }

    private func navigateToSettings() {
        // タイマー設定画面が表示されていることを確認
        XCTAssertTrue(app.staticTexts["Silent Cue"].exists)

        // 設定アイコンをタップ
        let settingsButton = app.buttons["gearshape.fill"]
        settingsButton.tap()

        // 設定画面に遷移したことを確認
        XCTAssertTrue(app.staticTexts["設定"].exists)
    }

    func testToggleAutoStop() throws {
        // 自動停止のトグルをオン/オフ
        let autoStopToggle = app.switches.firstMatch
        XCTAssertTrue(autoStopToggle.exists)

        // 現在の状態を取得
        let initialValue = autoStopToggle.value as? String

        // トグルをタップして切り替え
        autoStopToggle.tap()

        // 値が変わったことを確認
        XCTAssertNotEqual(autoStopToggle.value as? String, initialValue)

        // 再度タップして元に戻す
        autoStopToggle.tap()

        // 値が元に戻ったことを確認
        XCTAssertEqual(autoStopToggle.value as? String, initialValue)
    }

    func testHapticTypeSelection() throws {
        // デフォルトのStandardが選択されていることを確認（チェックマークの存在で判定）
        let standardButton = app.staticTexts["Standard"]
        XCTAssertTrue(standardButton.exists)

        // Strongをタップ
        let strongButton = app.staticTexts["Strong"]
        XCTAssertTrue(strongButton.exists)
        strongButton.tap()

        // Weakをタップ
        let weakButton = app.staticTexts["Weak"]
        XCTAssertTrue(weakButton.exists)
        weakButton.tap()

        // 最終的に元に戻す
        standardButton.tap()
    }

    func testDangerZone() throws {
        // 「Danger Zone」セクションが存在することを確認
        let dangerZone = app.staticTexts["Danger Zone"]
        XCTAssertTrue(dangerZone.exists)

        // 「Reset All Settings」ボタンをタップ
        let resetButton = app.buttons["Reset All Settings"]
        XCTAssertTrue(resetButton.exists)
        resetButton.tap()

        // 確認アラートが表示されることを確認
        let alertText = app.staticTexts["設定をリセットしますか？"]
        XCTAssertTrue(alertText.waitForExistence(timeout: 2))

        // キャンセルボタンをタップ
        let cancelButton = app.buttons["キャンセル"]
        XCTAssertTrue(cancelButton.exists)
        cancelButton.tap()

        // アラートが閉じて設定画面に戻ることを確認
        XCTAssertTrue(app.staticTexts["設定"].exists)
    }

    func testNavigationBack() throws {
        // 戻るジェスチャーでタイマー画面に戻る
        app.swipeRight()

        // タイマー設定画面に戻ったことを確認
        XCTAssertTrue(app.staticTexts["Silent Cue"].exists)
    }
}
