//@testable import SilentCue_Watch_App
import XCTest

final class SettingsViewUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false

        // 環境設定を行い、アプリを起動する (設定画面から開始)
        // setupUITestEnv内で "uiTesting" が渡され、アプリ側で依存性がTestValueに設定される
        SCAppEnvironment.setupUITestEnv(for: app, initialView: .settingsView)
        app.launch()

        // 設定タイトルが表示されていることを確認して起動を検証
        XCTAssertTrue(
            app.navigationBars[SCAccessibilityIdentifiers.SettingsView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "設定画面のナビゲーションバーが表示されている"
        )

        // 初回起動時に対して通知を許可
        NotificationPermissionHelper.ensureNotificationPermission(for: app)
    }

    // MARK: - Helper Functions

    /// 指定された要素が表示されるまでデジタルクラウンを回転させる
    /// 現在は 2(0.2 * 10) 回転まで対応
    private func rotateDigitalCrownToFindElement(
        _ element: XCUIElement,
        timeout: TimeInterval = UITestConstants.Timeout.standard,
        scrollDelta: CGFloat = 0.2,
        maxScrollAttempts: Int = 10
    ) {
        let startTime = Date()
        var scrollAttempts = 0

        while !element.exists, Date().timeIntervalSince(startTime) < timeout, scrollAttempts < maxScrollAttempts {
            XCUIDevice.shared.rotateDigitalCrown(delta: scrollDelta)
            scrollAttempts += 1
        }

        // タイムアウトまたは最大試行回数に達しても要素が見つからない場合はアサーション失敗
        XCTAssertTrue(
            element.waitForExistence(timeout: UITestConstants.Timeout.short),
            "要素 \"\(element.identifier)\" がスクロールしても見つかりませんでした。"
        )
    }

    // MARK: - Tests

    func testInitialUIElementsExist() {
        // 設定画面のナビゲーションバーが表示されていることを確認
        XCTAssertTrue(
            app.navigationBars[SCAccessibilityIdentifiers.SettingsView.navigationBarTitle.rawValue].exists,
            "設定画面のナビゲーションバーが表示されている"
        )

        app.swipeUp(velocity: UITestConstants.scrollVelocity)

        // 振動タイプのヘッダーが表示されていることを確認
        let vibrationTypeHeader = app.staticTexts[SCAccessibilityIdentifiers.SettingsView.vibrationTypeHeader.rawValue]
        XCTAssertTrue(vibrationTypeHeader.exists, "振動タイプを選ぶセクションのヘッダーが表示されている")

        app.swipeUp(velocity: UITestConstants.scrollVelocity)

        // デフォルトでStandardが表示されていることを確認
        let standardOption = app.buttons[SCAccessibilityIdentifiers.SettingsView.vibrationTypeOptionStandard.rawValue]
        XCTAssertTrue(standardOption.exists, "Standard オプションが表示されている")
    }

    func testSelectVibrationType() {
        let standardOption = app.buttons[SCAccessibilityIdentifiers.SettingsView.vibrationTypeOptionStandard.rawValue]
        let strongOption = app.buttons[SCAccessibilityIdentifiers.SettingsView.vibrationTypeOptionStrong.rawValue]
        let weakOption = app.buttons[SCAccessibilityIdentifiers.SettingsView.vibrationTypeOptionWeak.rawValue]

        // 初期状態を確認 (Standard がデフォルトと仮定)
        // Standardは最初から表示されているはずなので、スクロールなしで確認
        XCTAssertTrue(standardOption.waitForExistence(timeout: UITestConstants.Timeout.short), "Standard オプションが表示されている")
        XCTAssertTrue(standardOption.isSelected, "Standard が初期選択されている")
        XCTAssertFalse(strongOption.isSelected, "Strong が初期選択されていない")
        XCTAssertFalse(weakOption.isSelected, "Weak が初期選択されていない")

        // Strong を選択
        rotateDigitalCrownToFindElement(strongOption) // Strongが見えるまでスクロール
        strongOption.tap()

        // Assert: Strong が選択され、他が非選択になったことを確認
        XCTAssertTrue(strongOption.isSelected, "Strong が選択されている")
        XCTAssertFalse(standardOption.isSelected, "Standard が選択解除されている")
        // weakOptionが表示されているとは限らないため、状態のみ確認
        XCTAssertFalse(weakOption.isSelected, "Weak が選択解除されている")

        // Weak を選択
        rotateDigitalCrownToFindElement(weakOption) // Weakが見えるまでスクロール
        weakOption.tap()

        // Assert: Weak が選択され、他が非選択になったことを確認
        XCTAssertTrue(weakOption.isSelected, "Weak が選択されている")
        XCTAssertFalse(standardOption.isSelected, "Standard が選択解除されている")
        XCTAssertFalse(strongOption.isSelected, "Strong が選択解除されている")
    }

    func testBackButtonNavigatesToSetTimerView() {
        // 通常、最初のボタンが戻るボタン
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: UITestConstants.Timeout.short), "戻るボタンが表示されている")
        backButton.tap()

        // Assert
        // SetTimerViewに戻ったことを確認（アプリタイトルが表示されるはず）
        XCTAssertTrue(
            app.staticTexts[SCAccessibilityIdentifiers.SetTimerView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "SetTimerView に戻り、アプリタイトルが表示されている"
        )
    }
}
