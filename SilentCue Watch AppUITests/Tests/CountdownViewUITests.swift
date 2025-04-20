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

        guard let unwrappedApp = app else {
            XCTFail("XCUIApplication instance failed to initialize in setUp.")
            return
        }
        XCTAssertNotNil(unwrappedApp, "XCUIApplication が初期化されていること")

        // 初回起動時に対して通知を許可 (要素チェックの前に実行)
        NotificationPermissionHelper.ensureNotificationPermission(for: unwrappedApp)

        // デバッグ用に要素階層を出力
        print("--- CountdownView setUp UI Tree Start ---")
        print(unwrappedApp.debugDescription)
        print("--- CountdownView setUp UI Tree End ---")

        // CountdownView の主要要素（時間表示）が表示されることを確認
        XCTAssertTrue(
            unwrappedApp.staticTexts[countdownView.countdownTimeDisplay.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "CountdownView の時間表示が表示されること"
        )
    }

    override func tearDown() {
        app?.terminate()
        app = nil
        super.tearDown()
    }

    func testInitialUIElementsExist() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
        // 時間表示要素の存在を確認
        let timeDisplay = app.staticTexts[countdownView.countdownTimeDisplay.rawValue]
        XCTAssertTrue(timeDisplay.exists, "時間表示ラベルが存在する")
        // timeFormatLabel の存在も確認
        let timeFormatLabel = app.staticTexts[countdownView.timeFormatLabel.rawValue]
        XCTAssertTrue(timeFormatLabel.exists, "時間フォーマットラベルが存在する")

        // キャンセルボタンの存在と有効状態を確認
        let cancelButton = app.buttons[countdownView.cancelTimerButton.rawValue]
        XCTAssertTrue(cancelButton.exists, "キャンセルボタンが存在する")
        XCTAssertTrue(cancelButton.isEnabled, "キャンセルボタンが有効である")
    }

    func testCancelButtonAction() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
        let cancelButton = app.buttons[countdownView.cancelTimerButton.rawValue]
        XCTAssertTrue(cancelButton.exists, "タップ前にキャンセルボタンが存在する")

        // キャンセルボタンをタップ
        cancelButton.tap()

        // SetTimerView に戻ることを確認 (スタートボタンの存在で判断)
        let startButton = app.buttons[setTimerView.startTimerButton.rawValue]
        XCTAssertTrue(
            startButton.waitForExistence(timeout: UITestConstants.Timeout.standard),
            "キャンセルボタンタップ後に SetTimerView に戻る"
        )

        // CountdownView のキャンセルボタンが消えていることを確認
        XCTAssertFalse(cancelButton.exists, "SetTimerView に戻った後、キャンセルボタンは存在しない")

        // SetTimerView のナビゲーションバータイトルが存在するか確認
        XCTAssertTrue(
            app.navigationBars[setTimerView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "SetTimerView に戻り、ナビゲーションバータイトルが表示されている"
        )
    }
}
