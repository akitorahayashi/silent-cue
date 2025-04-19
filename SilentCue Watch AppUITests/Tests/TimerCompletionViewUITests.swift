@testable import SilentCue_Watch_App
import XCTest

final class TimerCompletionViewUITests: XCTestCase {
    var app: XCUIApplication?

    override func setUp() {
        continueAfterFailure = false
        let application = XCUIApplication()
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .timerCompletionView)
        application.launch()
        app = application

        XCTAssertNotNil(app, "XCUIApplication が初期化されている")

        XCTAssertTrue(
            app?.buttons[SCAccessibilityIdentifiers.TimerCompletionView.closeTimeCompletionViewButton.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard) ?? false,
            "TimerCompletionView の閉じるボタンが表示される"
        )
        
        // 初回起動時に対して通知を許可
        NotificationPermissionHelper.ensureNotificationPermission(for: app!)
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testViewElements() throws {
        // --- Assert: TimerCompletionView の要素確認 ---

        // 1. 閉じるボタン
        let closeButton = app?
            .buttons[SCAccessibilityIdentifiers.TimerCompletionView.closeTimeCompletionViewButton.rawValue]
        XCTAssertTrue(closeButton?.exists ?? false, "閉じるボタンが存在する")
        XCTAssertTrue(closeButton?.isEnabled ?? false, "閉じるボタンが有効である")

        // 2. NotifyEndTimeView 関連要素
        // 完了時刻表示を確認（正確な識別子がない場合は、テキスト内容で確認）
        // モックデータが使用される前提でテスト
        let notifyEndTimeView = app?.otherElements[SCAccessibilityIdentifiers.TimerCompletionView.notifyEndTimeViewVStack.rawValue]
        XCTAssertTrue(notifyEndTimeView?.exists ?? false, "NotifyEndTimeView が存在する")

        // 3. TimerSummaryView 関連要素
        // 開始時刻とタイマー時間の表示を確認
        let timerSummaryView = app?.otherElements[SCAccessibilityIdentifiers.TimerCompletionView.timerSummaryViewVStack.rawValue]
        XCTAssertTrue(timerSummaryView?.exists ?? false, "TimerSummaryView が存在する")

        // 4. 通知許可ボタン (通知未許可の場合)
        let enableNotificationButton = app?.buttons.containing(.staticText, identifier: "通知を有効にする").firstMatch

        // SCAppEnvironment で通知状態をコントロールする場合、以下の条件テストを調整
        if let notificationButton = enableNotificationButton, notificationButton.exists {
            let notificationText = notificationButton.staticTexts["通知を有効にする"]
            XCTAssertTrue(notificationText.exists, "'通知を有効にする' テキストが存在する")

            // 通知アイコンの存在確認
            let bellIcon = app?.images["bell.badge"]
            XCTAssertTrue(bellIcon?.exists ?? false, "通知アイコンが存在する")
        }
        // 通知が許可されている場合は、ボタンが表示されないことを確認できるが、
        // テスト環境の通知状態が変動するため、この確認は省略可能
    }

    func testTapCloseButton() throws {
        // Arrange: TimerCompletionView 表示済み
        let closeButton = app?
            .buttons[SCAccessibilityIdentifiers.TimerCompletionView.closeTimeCompletionViewButton.rawValue]
        XCTAssertTrue(closeButton?.exists ?? false, "タップ前に閉じるボタンが存在する")

        // Act: 閉じるボタンをタップ
        closeButton?.tap()

        // Assert: SetTimerView に戻るか確認
        XCTAssertTrue(
            app?.buttons[SCAccessibilityIdentifiers.SetTimerView.startTimerButton.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard) ?? false,
            "閉じるボタンタップ後に SetTimerView に戻る"
        )
        // 完了ビューの要素が消えているか確認
        XCTAssertFalse(closeButton?.exists ?? false, "SetTimerView に戻った後、閉じるボタンは存在しない")

        // SetTimerView のナビゲーションバータイトルが存在するか確認
        XCTAssertTrue(
            app!.staticTexts[SCAccessibilityIdentifiers.SetTimerView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "SetTimerView に戻り、アプリタイトルが表示されている"
        )
    }
}
