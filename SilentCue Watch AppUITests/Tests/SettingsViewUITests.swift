// @testable import SilentCue_Watch_App
import XCTest

final class SettingsViewUITests: XCTestCase {
    // app プロパティをオプショナルに変更
    var app: XCUIApplication?
    // Accessibility Identifiers
    let settingsView = SCAccessibilityIdentifiers.SettingsView.self
    let setTimerView = SCAccessibilityIdentifiers.SetTimerView.self // 戻るボタンの遷移先確認用

    override func setUp() {
        continueAfterFailure = false

        // ローカルでインスタンスを作成
        let application = XCUIApplication()
        // 環境設定を行い、アプリを起動する (設定画面から開始)
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .settingsView)
        application.launch()
        // プロパティに代入
        app = application

        guard let unwrappedApp = app else {
            XCTFail("XCUIApplication instance failed to initialize in setUp.")
            return
        }
        XCTAssertNotNil(unwrappedApp, "XCUIApplication が初期化されている")

        // 設定タイトルが表示されていることを確認して起動を検証
        XCTAssertTrue(
            unwrappedApp.navigationBars[settingsView.navigationBarTitle.rawValue] // 定数を使用
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "設定画面のナビゲーションバーが表示されている"
        )

        // 初回起動時に対して通知を許可
        NotificationPermissionHelper.ensureNotificationPermission(for: unwrappedApp)
    }

    // tearDown を追加
    override func tearDown() {
        app?.terminate() // アプリ終了
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
        guard let app else { // ヘルパー内でも nil チェック
            XCTFail("rotateDigitalCrownToFindElement: app is nil")
            return
        }
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
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
        // 設定画面のナビゲーションバーが表示されていることを確認
        XCTAssertTrue(
            app.navigationBars[settingsView.navigationBarTitle.rawValue].exists, // 定数を使用
            "設定画面のナビゲーションバーが表示されている"
        )

        app.swipeUp(velocity: UITestConstants.scrollVelocity)

        // 振動タイプのヘッダーが表示されていることを確認
        let vibrationTypeHeader = app.staticTexts[settingsView.vibrationTypeHeader.rawValue] // 定数を使用
        XCTAssertTrue(vibrationTypeHeader.exists, "振動タイプを選ぶセクションのヘッダーが表示されている")

        app.swipeUp(velocity: UITestConstants.scrollVelocity)

        // デフォルトでStandardが表示されていることを確認
        let standardOption = app.buttons[settingsView.vibrationTypeOptionStandard.rawValue] // 定数を使用
        XCTAssertTrue(standardOption.exists, "Standard オプションが表示されている")
    }

    func testSelectVibrationType() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
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
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
        // 通常、最初のボタンが戻るボタン
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
}
