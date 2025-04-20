// @testable import SilentCue_Watch_App
import XCTest

final class SettingsViewUITests: XCTestCase {
    // app プロパティをオプショナルに変更
    var app: XCUIApplication?

    override func setUp() {
        continueAfterFailure = false

        // ローカルでインスタンスを作成
        let application = XCUIApplication()
        // 環境設定を行い、アプリを起動する (設定画面から開始)
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .settingsView)
        application.launch()
        // プロパティに代入
        app = application

        // app が nil でないことを確認
        XCTAssertNotNil(app, "XCUIApplication が初期化されている")

        // 設定タイトルが表示されていることを確認して起動を検証 (app?. を使用)
        XCTAssertTrue(
            app?.navigationBars[SCAccessibilityIdentifiers.SettingsView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard) ?? false,
            "設定画面のナビゲーションバーが表示されている"
        )

        // 初回起動時に対して通知を許可 (安全なアンラップを使用)
        if let currentApp = app {
            NotificationPermissionHelper.ensureNotificationPermission(for: currentApp)
        } else {
            XCTFail("app インスタンスが nil です")
        }
    }

    // tearDown を追加
    override func tearDown() {
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

    func testInitialUIElementsExist() {
        // 設定画面のナビゲーションバーが表示されていることを確認 (app?. を使用)
        XCTAssertTrue(
            app?.navigationBars[SCAccessibilityIdentifiers.SettingsView.navigationBarTitle.rawValue].exists ?? false,
            "設定画面のナビゲーションバーが表示されている"
        )

        // swipeUp はオプショナルチェイニングで呼び出す
        app?.swipeUp(velocity: UITestConstants.scrollVelocity)

        // 振動タイプのヘッダーが表示されていることを確認 (app?. を使用)
        let vibrationTypeHeader = app?.staticTexts[SCAccessibilityIdentifiers.SettingsView.vibrationTypeHeader.rawValue]
        XCTAssertTrue(vibrationTypeHeader?.exists ?? false, "振動タイプを選ぶセクションのヘッダーが表示されている")

        app?.swipeUp(velocity: UITestConstants.scrollVelocity)

        // デフォルトでStandardが表示されていることを確認 (app?. を使用)
        let standardOption = app?.buttons[SCAccessibilityIdentifiers.SettingsView.vibrationTypeOptionStandard.rawValue]
        XCTAssertTrue(standardOption?.exists ?? false, "Standard オプションが表示されている")
    }

    func testSelectVibrationType() {
        // 各要素の取得に app?. を使用
        let standardOption = app?.buttons[SCAccessibilityIdentifiers.SettingsView.vibrationTypeOptionStandard.rawValue]
        let strongOption = app?.buttons[SCAccessibilityIdentifiers.SettingsView.vibrationTypeOptionStrong.rawValue]
        let weakOption = app?.buttons[SCAccessibilityIdentifiers.SettingsView.vibrationTypeOptionWeak.rawValue]

        // 各要素が存在することを確認してからテストを進める (nil チェック兼ねる)
        guard let standard = standardOption, let strong = strongOption, let weak = weakOption else {
            XCTFail("必要なオプションボタンが見つかりません")
            return
        }

        // 初期状態を確認 (Standard がデフォルトと仮定)
        XCTAssertTrue(standard.waitForExistence(timeout: UITestConstants.Timeout.short), "Standard オプションが表示されている")
        XCTAssertTrue(standard.isSelected, "Standard が初期選択されている")
        // isSelected は Bool を返すので ?? false 不要
        XCTAssertFalse(strong.isSelected, "Strong が初期選択されていない")
        XCTAssertFalse(weak.isSelected, "Weak が初期選択されていない")

        // Strong を選択
        rotateDigitalCrownToFindElement(strong) // Strongが見えるまでスクロール
        strong.tap()

        // Assert: Strong が選択され、他が非選択になったことを確認
        XCTAssertTrue(strong.isSelected, "Strong が選択されている")
        XCTAssertFalse(standard.isSelected, "Standard が選択解除されている")
        XCTAssertFalse(weak.isSelected, "Weak が選択解除されている")

        // Weak を選択
        rotateDigitalCrownToFindElement(weak) // Weakが見えるまでスクロール
        weak.tap()

        // Assert: Weak が選択され、他が非選択になったことを確認
        XCTAssertTrue(weak.isSelected, "Weak が選択されている")
        XCTAssertFalse(standard.isSelected, "Standard が選択解除されている")
        XCTAssertFalse(strong.isSelected, "Strong が選択解除されている")
    }

    func testBackButtonNavigatesToSetTimerView() {
        // 通常、最初のボタンが戻るボタン (app?. を使用)
        let backButton = app?.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton?.waitForExistence(timeout: UITestConstants.Timeout.short) ?? false, "戻るボタンが表示されている")
        backButton?.tap()

        // Assert
        // SetTimerViewに戻ったことを確認（アプリタイトルが表示されるはず）(app?. を使用)
        XCTAssertTrue(
            app?.staticTexts[SCAccessibilityIdentifiers.SetTimerView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard) ?? false,
            "SetTimerView に戻り、アプリタイトルが表示されている"
        )
    }
}
