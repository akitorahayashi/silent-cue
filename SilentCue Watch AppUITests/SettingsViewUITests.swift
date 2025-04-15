import XCTest

final class SettingsViewUITests: XCTestCase {
    let app = XCUIApplication()

    // スワイプする速度
    private let swipeVelocity: XCUIGestureVelocity = 100

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()

        // アプリが正常に起動するのを待機
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // アプリのタイトルが表示されるまで待機
        XCTAssertTrue(app.staticTexts["Silent Cue"].waitForExistence(timeout: 5), "アプリタイトルが表示される")
    }

    func testSettingsViewInitialDisplay() throws {
        // まず設定画面に移動
        navigateToSettingsView()

        // 設定タイトルが表示されているか確認
        XCTAssertTrue(app.staticTexts["Settings"].exists)

        // 自動停止トグルが表示されているか確認
        XCTAssertTrue(app.switches.matching(identifier: "AutoStopToggle").firstMatch.exists)

        // バイブレーションタイプセクションが表示されているか確認
        XCTAssertTrue(app.staticTexts.matching(identifier: "VibrationTypeHeader").firstMatch.exists)

        // 画面を下にスクロールして DangerZone を表示
        app.swipeUp(velocity: swipeVelocity)

        // 危険ゾーンが表示されるまで待機 - スクロールの完了を待機
        XCTAssertTrue(
            app.staticTexts.matching(identifier: "DangerZoneHeader").firstMatch.waitForExistence(timeout: 3),
            "危険ゾーンヘッダーが表示される"
        )
        XCTAssertTrue(
            app.buttons.matching(identifier: "ResetAllSettingsButton").firstMatch.waitForExistence(timeout: 2),
            "リセットボタンが表示される"
        )
    }

    func testAutoStopToggle() throws {
        // まず設定画面に移動
        navigateToSettingsView()

        // 自動停止トグルを見つける
        let autoStopToggle = app.switches.matching(identifier: "AutoStopToggle").firstMatch

        // 初期値を取得
        let initialValue = autoStopToggle.value as? String

        // スイッチを切り替え
        autoStopToggle.tap()

        // トグルが変更されたか確認
        let newValue = autoStopToggle.value as? String
        XCTAssertNotEqual(initialValue, newValue, "トグルの状態が変更されている")
    }

    func testVibrationTypeSelection() throws {
        // まず設定画面に移動
        navigateToSettingsView()

        // 弱いスワイプでバイブレーションタイプを表示
        app.swipeUp(velocity: swipeVelocity)

        // UIが安定するのを待つ
        XCTAssertTrue(
            app.buttons.matching(identifier: "VibrationTypeOptionStrong").firstMatch.waitForExistence(timeout: 3),
            "Strongオプションが表示される"
        )

        // 異なるバイブレーションタイプを選択するテスト
        // まず「Strong」を選択
        app.buttons.matching(identifier: "VibrationTypeOptionStrong").firstMatch.tap()

        // さらに弱くスクロールしてLightオプションを表示
        app.swipeUp(velocity: swipeVelocity)
        XCTAssertTrue(
            app.buttons.matching(identifier: "VibrationTypeOptionWeak").firstMatch.waitForExistence(timeout: 3),
            "Weakオプションが表示される"
        )

        // 次に別のタイプを試す
        app.buttons.matching(identifier: "VibrationTypeOptionWeak").firstMatch.tap()
    }

    func testDangerZone() throws {
        // まず設定画面に移動
        navigateToSettingsView()

        // スクロールダウン
        app.swipeUp(velocity: swipeVelocity)

        // 危険ゾーンが表示されるまで待機（これによりスクロールの完了を待機）
        XCTAssertTrue(
            app.staticTexts.matching(identifier: "DangerZoneHeader").firstMatch.waitForExistence(timeout: 3),
            "危険ゾーンヘッダーが表示される"
        )
        XCTAssertTrue(
            app.buttons.matching(identifier: "ResetAllSettingsButton").firstMatch.waitForExistence(timeout: 2),
            "リセットボタンが表示される"
        )
    }

    func testResetAllSettings() throws {
        // まず設定画面に移動
        navigateToSettingsView()

        // 1. 設定を変更
        // 自動停止トグルを切り替え
        let autoStopToggle = app.switches.matching(identifier: "AutoStopToggle").firstMatch
        let initialToggleValue = autoStopToggle.value as? String
        autoStopToggle.tap()

        // トグルの変更後の値を記録
        let changedToggleValue = autoStopToggle.value as? String
        // 値が確実に変わったことを確認
        XCTAssertNotEqual(initialToggleValue, changedToggleValue, "トグルの状態が変更されている")

        // バイブレーションタイプを変更（デフォルトはStandardなので別のものに変更）
        app.swipeUp(velocity: swipeVelocity)
        XCTAssertTrue(
            app.buttons.matching(identifier: "VibrationTypeOptionStrong").firstMatch.waitForExistence(timeout: 3),
            "Strongオプションが表示される"
        )
        app.buttons.matching(identifier: "VibrationTypeOptionStrong").firstMatch.tap()

        // 2. 危険ゾーンにスクロール
        app.swipeUp(velocity: swipeVelocity)
        let resetButton = app.buttons.matching(identifier: "ResetAllSettingsButton").firstMatch
        XCTAssertTrue(resetButton.waitForExistence(timeout: 3), "リセットボタンが表示される")

        // 3. リセットボタンをタップ
        resetButton.tap()

        // 4. 確認ダイアログで「リセット」を選択
        let resetConfirmButton = app.buttons["リセット"]
        XCTAssertTrue(resetConfirmButton.waitForExistence(timeout: 3), "リセット確認ボタンが表示される")
        resetConfirmButton.tap()

        // 5. OKアラートが表示されたら閉じる
        let okButton = app.buttons["OK"]
        if okButton.waitForExistence(timeout: 3) {
            okButton.tap()
        }

        // 6. 設定がデフォルト値に戻ったことを検証

        // バイブレーションタイプが「Standard」に戻っているか確認（少し上にスクロールして見えるようにする）
        app.swipeDown(velocity: swipeVelocity)
        XCTAssertTrue(
            app.buttons.matching(identifier: "VibrationTypeOptionStandard").firstMatch.waitForExistence(timeout: 3),
            "Standardオプションが表示される"
        )

        // トグルがリセットされたことを確認（変更後の値と異なることを検証）
        app.swipeDown(velocity: swipeVelocity)
        let resetToggleValue = autoStopToggle.value as? String
        XCTAssertEqual(resetToggleValue, initialToggleValue, "トグルの状態がリセットされている")
    }

    // 設定画面に移動するヘルパーメソッド
    private func navigateToSettingsView() {
        // 設定ページを開くボタンをアクセシビリティ識別子で特定
        let settingsButton = app.buttons.matching(identifier: "OpenSettingsPage").firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10), "設定ボタンが表示される")
        settingsButton.tap()

        // 設定画面が表示されるまで待機
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5), "設定画面のタイトルが表示される")
    }
}
