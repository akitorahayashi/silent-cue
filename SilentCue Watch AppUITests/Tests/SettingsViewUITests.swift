import SCShared
@testable import SilentCue_Watch_App
import XCTest

final class SettingsViewUITests: XCTestCase {
    var app: XCUIApplication!
    // Accessibility Identifiers
    let settingsView = SCAccessibilityIdentifiers.SettingsView.self
    let setTimerView = SCAccessibilityIdentifiers.SetTimerView.self

    override func setUp() {
        continueAfterFailure = false
        let application = XCUIApplication()
        // SettingsView からテストを開始するように環境設定
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .settingsView)
        application.launch()
        app = application

        // デバッグ用に要素階層を出力
        print("--- SettingsView setUp UI Tree Start ---")
        print(app.debugDescription)
        print("--- SettingsView setUp UI Tree End ---")

        // SettingsView の主要要素（ナビゲーションバータイトル）が表示されることを確認
        XCTAssertTrue(app.navigationBars[settingsView.navigationBarTitle.rawValue].waitForExistence(timeout: UITestConstants.Timeout.standard))
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
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

        // element の存在チェックはそのまま
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

    func testInitialUIElementsExist() throws {
        let navBar = app.navigationBars[settingsView.navigationBarTitle.rawValue]
        XCTAssertTrue(navBar.exists)

        let vibrationSectionHeader = app.staticTexts[settingsView.vibrationSectionHeader.rawValue]
        let notificationSectionHeader = app.staticTexts[settingsView.notificationSectionHeader.rawValue]
        let otherSectionHeader = app.staticTexts[settingsView.otherSectionHeader.rawValue]

        XCTAssertTrue(vibrationSectionHeader.exists)
        XCTAssertTrue(notificationSectionHeader.exists)
        XCTAssertTrue(otherSectionHeader.exists)

        let vibrationPatternButton = app.buttons[settingsView.vibrationPatternButton.rawValue]
        let soundToggleButton = app.switches[settingsView.soundToggle.rawValue]
        let notificationTimeButton = app.buttons[settingsView.notificationTimingButton.rawValue]
        let autoStartToggleButton = app.switches[settingsView.autoStartToggle.rawValue]

        XCTAssertTrue(vibrationPatternButton.exists)
        XCTAssertTrue(soundToggleButton.exists)
        XCTAssertTrue(notificationTimeButton.exists)
        XCTAssertTrue(autoStartToggleButton.exists)
    }

    func testSelectVibrationType() throws {
        // 各要素の取得
        let standardOption = app.buttons[settingsView.vibrationTypeOptionStandard.rawValue] // 定数を使用
        let strongOption = app.buttons[settingsView.vibrationTypeOptionStrong.rawValue] // 定数を使用
        let weakOption = app.buttons[settingsView.vibrationTypeOptionWeak.rawValue] // 定数を使用

        // 初期状態を確認 (Standard がデフォルト)
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
        XCTAssertFalse(weakOption.isSelected, "Weak が選択解除されている")

        // Weak を選択
        rotateDigitalCrownToFindElement(weakOption) // Weakが見えるまでスクロール
        weakOption.tap()

        // Assert: Weak が選択され、他が非選択になったことを確認
        XCTAssertTrue(weakOption.isSelected, "Weak が選択されている")
        XCTAssertFalse(standardOption.isSelected, "Standard が選択解除されている")
        XCTAssertFalse(strongOption.isSelected, "Strong が選択解除されている")
    }

    func testBackButtonNavigatesToSetTimerView() throws {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: UITestConstants.Timeout.short), "戻るボタンが表示されている")
        backButton.tap()

        // Assert: SetTimerViewに戻ったことを確認（ナビゲーションバータイトルで判断）
        XCTAssertTrue(
            app.navigationBars[setTimerView.navigationBarTitle.rawValue] // 定数を使用
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "SetTimerView に戻り、ナビゲーションバータイトルが表示されている"
        )
    }

    func testVibrationPatternNavigation() throws {
        let vibrationButton = app.buttons[settingsView.vibrationPatternButton.rawValue]
        XCTAssertTrue(vibrationButton.exists)
        vibrationButton.tap()

        XCTAssertTrue(app.navigationBars["バイブレーションパターン"].waitForExistence(timeout: UITestConstants.Timeout.standard))
        app.navigationBars.buttons.element(boundBy: 0).tap() // Back button
    }

    func testSoundToggleInteraction() throws {
        let soundToggle = app.switches[settingsView.soundToggle.rawValue]
        XCTAssertTrue(soundToggle.exists)
    }

    func testNotificationTimeNavigation() throws {
        let notificationTimeButton = app.buttons[settingsView.notificationTimingButton.rawValue]
        XCTAssertTrue(notificationTimeButton.exists)
        notificationTimeButton.tap()

        XCTAssertTrue(app.navigationBars["通知タイミング"].waitForExistence(timeout: UITestConstants.Timeout.standard))
        app.navigationBars.buttons.element(boundBy: 0).tap() // Back button
    }

    func testAutoStartToggleInteraction() throws {
        let autoStartToggle = app.switches[settingsView.autoStartToggle.rawValue]
        XCTAssertTrue(autoStartToggle.exists)
    }

    func testBackButtonNavigation() throws {
        let backButton = app.navigationBars[settingsView.navigationBarTitle.rawValue].buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.exists)
        backButton.tap()

        XCTAssertTrue(app.navigationBars[setTimerView.navigationBarTitle.rawValue].waitForExistence(timeout: UITestConstants.Timeout.standard))
    }
}
