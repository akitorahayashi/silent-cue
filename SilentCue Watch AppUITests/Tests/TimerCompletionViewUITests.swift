@testable import SilentCue_Watch_App
import XCTest

final class TimerCompletionViewUITests: XCTestCase {
    var app: XCUIApplication?
    // Accessibility Identifiers
    let timerCompletionView = SCAccessibilityIdentifiers.TimerCompletionView.self
    let setTimerView = SCAccessibilityIdentifiers.SetTimerView.self

    override func setUp() {
        continueAfterFailure = false
        let application = XCUIApplication()
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .timerCompletionView)
        application.launch()
        app = application

        XCTAssertNotNil(app, "XCUIApplication が初期化されている")

        XCTAssertTrue(
            app!.buttons[timerCompletionView.closeTimeCompletionViewButton.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "TimerCompletionView の閉じるボタンが表示される"
        )

        // 初回起動時に対して通知を許可
        NotificationPermissionHelper.ensureNotificationPermission(for: app!)
    }

    override func tearDown() {
        app?.terminate()
        app = nil
        super.tearDown()
    }

    func testViewElements() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
        // --- Assert: TimerCompletionView の要素確認 ---

        // 1. 閉じるボタン
        let closeButton = app.buttons[timerCompletionView.closeTimeCompletionViewButton.rawValue]
        XCTAssertTrue(closeButton.exists, "閉じるボタンが存在する")
        XCTAssertTrue(closeButton.isEnabled, "閉じるボタンが有効である")

        // 2. NotifyEndTimeView 関連要素
        let notifyEndTimeView = app.otherElements[timerCompletionView.notifyEndTimeViewVStack.rawValue]
        XCTAssertTrue(notifyEndTimeView.exists, "NotifyEndTimeView が存在する")

        // 3. TimerSummaryView 関連要素
        let timerSummaryView = app.otherElements[timerCompletionView.timerSummaryViewVStack.rawValue]
        XCTAssertTrue(timerSummaryView.exists, "TimerSummaryView が存在する")

        // 4. 通知許可ボタン (通知未許可の場合)
        let enableNotificationButton = app.buttons.containing(.staticText, identifier: "通知を有効にする").firstMatch

        // SCAppEnvironment で通知状態をコントロールする場合、以下の条件テストを調整
        if enableNotificationButton.exists {
            let notificationText = enableNotificationButton.staticTexts["通知を有効にする"]
            XCTAssertTrue(notificationText.exists, "'通知を有効にする' テキストが存在する")

            // 通知アイコンの存在確認
            let bellIcon = app.images["bell.badge"]
            XCTAssertTrue(bellIcon.exists, "通知アイコンが存在する")
        }
    }

    func testTapCloseButton() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
        // Arrange: TimerCompletionView 表示済み
        let closeButton = app.buttons[timerCompletionView.closeTimeCompletionViewButton.rawValue]
        XCTAssertTrue(closeButton.exists, "タップ前に閉じるボタンが存在する")

        // Act: 閉じるボタンをタップ
        closeButton.tap()

        // Assert: SetTimerView に戻るか確認
        let startButton = app.buttons[setTimerView.startTimerButton.rawValue]
        XCTAssertTrue(
            startButton.waitForExistence(timeout: UITestConstants.Timeout.standard),
            "閉じるボタンタップ後に SetTimerView に戻る"
        )
        // 完了ビューの要素が消えているか確認
        XCTAssertFalse(closeButton.exists, "SetTimerView に戻った後、閉じるボタンは存在しない")

        // SetTimerView のナビゲーションバータイトルが存在するか確認
        XCTAssertTrue(
            app.navigationBars[setTimerView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "SetTimerView に戻り、アプリタイトルが表示されている"
        )
    }
}
