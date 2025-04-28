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

    func testNavigationTitleIsCorrect() throws {
        // Assert: ナビゲーションバーのタイトルが期待通りか確認
        let navBar = app.navigationBars[settingsView.navigationBarTitle.rawValue]
        XCTAssertTrue(navBar.waitForExistence(timeout: UITestConstants.Timeout.short), "ナビゲーションバーが表示されている")
        XCTAssertEqual(navBar.identifier, settingsView.navigationBarTitle.rawValue, "ナビゲーションバーのタイトルが正しい")
    }

    func testSelectVibrationType() throws {
        // 各要素の取得
        let standardOption = app.buttons[settingsView.vibrationTypeOptionStandard.rawValue]
        let strongOption = app.buttons[settingsView.vibrationTypeOptionStrong.rawValue]
        let weakOption = app.buttons[settingsView.vibrationTypeOptionWeak.rawValue]

        // Assert: 全ての振動オプションが存在することを確認
        XCTAssertTrue(standardOption.waitForExistence(timeout: UITestConstants.Timeout.short), "Standard オプションが表示されている")
        // StrongとWeakは画面内にない可能性があるのでスクロールして探す
        rotateDigitalCrownToFindElement(strongOption)
        XCTAssertTrue(strongOption.exists, "Strong オプションが表示されている")
        rotateDigitalCrownToFindElement(weakOption)
        XCTAssertTrue(weakOption.exists, "Weak オプションが表示されている")

        // スクロールによってStandardが見えなくなる可能性があるので、再度Standardまでスクロールする
        rotateDigitalCrownToFindElement(standardOption, scrollDelta: -0.5, maxScrollAttempts: 5) // 逆方向にスクロール

        // Assert: 初期状態を確認 (Standard がデフォルト)
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

        // Standard を再度選択
        rotateDigitalCrownToFindElement(standardOption) // Standardが見えるまでスクロール
        standardOption.tap()

        // Assert: Standard が選択され、他が非選択になったことを確認
        XCTAssertTrue(standardOption.isSelected, "Standard が選択されている")
        XCTAssertFalse(strongOption.isSelected, "Strong が選択解除されている")
        XCTAssertFalse(weakOption.isSelected, "Weak が選択解除されている")
    }

    func testBackButtonNavigatesToSetTimerView() throws {
        // SettingsViewのカスタム戻るボタンを Accessibility Identifier で取得
        let backButton = app.buttons[settingsView.backButton.rawValue]
        XCTAssertTrue(backButton.waitForExistence(timeout: UITestConstants.Timeout.short), "カスタム戻るボタン（ID: \(settingsView.backButton.rawValue)）が表示されている")

        // 戻るボタンをタップ
        backButton.tap()

        // Assert: SetTimerViewに戻ったことを確認（ナビゲーションバータイトルで判断）
        XCTAssertTrue(
            app.navigationBars[setTimerView.navigationBarTitle.rawValue] // SetTimerView のタイトルを期待
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "SetTimerView に戻り、ナビゲーションバータイトル '\\(setTimerView.navigationBarTitle.rawValue)' が表示されている"
        )
    }
}
