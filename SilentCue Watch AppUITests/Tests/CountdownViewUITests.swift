import XCTest

final class CountdownViewUITests: XCTestCase {
    var app: XCUIApplication?
    let countdownView = SCAccessibilityIdentifiers.CountdownView.self
    let setTimerView = SCAccessibilityIdentifiers.SetTimerView.self

    override func setUp() {
        continueAfterFailure = false
        let application = XCUIApplication()
        // CountdownView からテストを開始するように環境設定
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .countdownView)
        application.launch()
        app = application

        XCTAssertNotNil(app, "XCUIApplication が初期化されていること")

        // CountdownView の主要要素（例: 時間表示）が表示されることを確認
        XCTAssertTrue(
            app?.staticTexts[countdownView.countdownTimeDisplay.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard) ?? false,
            "CountdownView の時間表示が表示されること"
        )

        // 初回起動時に対して通知を許可
        if let currentApp = app {
            NotificationPermissionHelper.ensureNotificationPermission(for: currentApp)
        } else {
            XCTFail("app インスタンスが nil です")
        }
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testInitialUIElementsExist() throws {
        // 時間表示要素の存在を確認
        let timeDisplay = app?.staticTexts[countdownView.countdownTimeDisplay.rawValue]
        XCTAssertTrue(timeDisplay?.exists ?? false, "時間表示ラベルが存在する")
        // TODO: 必要であれば、timeFormatLabel の存在も確認
        // let timeFormatLabel = app?.staticTexts[countdownView.timeFormatLabel.rawValue]
        // XCTAssertTrue(timeFormatLabel?.exists ?? false, "時間フォーマットラベルが存在する")

        // キャンセルボタンの存在と有効状態を確認
        let cancelButton = app?.buttons[countdownView.cancelTimerButton.rawValue]
        XCTAssertTrue(cancelButton?.exists ?? false, "キャンセルボタンが存在する")
        XCTAssertTrue(cancelButton?.isEnabled ?? false, "キャンセルボタンが有効である")
    }

    func testCancelButtonAction() throws {
        let cancelButton = app?.buttons[countdownView.cancelTimerButton.rawValue]
        XCTAssertTrue(cancelButton?.exists ?? false, "タップ前にキャンセルボタンが存在する")

        // キャンセルボタンをタップ
        cancelButton?.tap()

        // SetTimerView に戻ることを確認
        // 例としてスタートボタンの存在を確認
        let startButton = app?.buttons[setTimerView.startTimerButton.rawValue]
        XCTAssertTrue(
            startButton?.waitForExistence(timeout: UITestConstants.Timeout.standard) ?? false,
            "キャンセルボタンタップ後に SetTimerView に戻る"
        )

        // CountdownView の要素（キャンセルボタン）が消えていることを確認
        XCTAssertFalse(cancelButton?.exists ?? false, "SetTimerView に戻った後、キャンセルボタンは存在しない")

        // SetTimerView のナビゲーションバータイトルが存在するか確認
        XCTAssertTrue(
            app?.staticTexts[SCAccessibilityIdentifiers.SetTimerView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard) ?? false,
            "SetTimerView に戻り、アプリタイトルが表示されている"
        )
    }
}
