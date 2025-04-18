import XCTest

final class TimerCompletionViewUITests: XCTestCase {
    var app: XCUIApplication?

    override func setUpWithError() throws {
        continueAfterFailure = false
        let application = XCUIApplication()
        SCAppEnvironment.setupEnvironment(for: application, launchArgument: .testingTimerCompletionView)
        application.launch()
        XCTAssertNotNil(application, "XCUIApplication should be initialized")
        self.app = application // プロパティに代入

        // アンラップしてアクセス
        guard let currentApp = app else {
            XCTFail("app should not be nil after setup")
            return
        }

        XCTAssertTrue(
            currentApp.buttons[SCAccessibilityIdentifiers.TimerCompletionView.okButton.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "TimerCompletionView (閉じるボタン) が表示される"
        )
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testViewElements() throws {
        // アンラップ
        guard let app = app else {
            XCTFail("app should not be nil")
            return
        }

        // --- Assert: TimerCompletionView の要素確認 ---

        // 1. 閉じるボタン (Identifier: "closeTimeCompletionViewButton")
        let closeButton = app.buttons[SCAccessibilityIdentifiers.TimerCompletionView.closeTimeCompletionViewButton.rawValue]
        XCTAssertTrue(closeButton.exists, "閉じるボタンが存在する")
        XCTAssertTrue(closeButton.isEnabled, "閉じるボタンが有効である")

        // 2. NotifyEndTimeView 関連 (例: 完了時刻)
        // TODO: モックデータに基づいたアサーションを追加

        // 3. TimerSummaryView 関連 (例: 開始時刻, タイマー時間)
        // TODO: モックデータに基づいたアサーションを追加

        // 4. 通知許可ボタン (通知未許可の場合)
        //    SCAppEnvironment が通知未許可状態を設定している前提
        let enableNotificationButton = app.buttons.containing(.staticText, identifier: "通知を有効にする").firstMatch
        let notificationText = enableNotificationButton.staticTexts["通知を有効にする"]

        // テスト環境が通知無効で始まる場合
        XCTAssertTrue(enableNotificationButton.exists, "通知許可ボタンが存在する (通知未許可時)")
        XCTAssertTrue(notificationText.exists, "'通知を有効にする' テキストが存在する")

        // TODO: テスト環境が最初に通知を許可している場合、通知ボタンが存在しないことを確認
    }

    func testTapCloseButton() throws {
        // メソッド名を testTapCloseButton に変更する方が良いかもしれないが、一旦このまま
        guard let app = app else {
            XCTFail("app should not be nil")
            return
        }
        // Arrange: TimerCompletionView 表示済み
        let closeButton = app.buttons[SCAccessibilityIdentifiers.TimerCompletionView.okButton.rawValue]
        XCTAssertTrue(closeButton.exists, "タップ前に 閉じるボタンが存在する")

        // Act: 閉じるボタンをタップ
        closeButton.tap()

        // Assert: SetTimerView に戻るか確認
        XCTAssertTrue(
            app.buttons[SCAccessibilityIdentifiers.SetTimerView.startTimerButton.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "閉じるボタンタップ後に SetTimerView に戻る"
        )
        // 完了ビューの要素が消えているか確認
        XCTAssertFalse(closeButton.exists, "SetTimerView に戻った後、閉じるボタンは存在しない")

        // SetTimerView の ScrollView が存在するか確認
        XCTAssertTrue(
            app.otherElements[SCAccessibilityIdentifiers.SetTimerView.setTimerScrollView.rawValue].exists,
            "戻った後に SetTimerScrollView が存在する"
        )
    }

    // TODO: 必要なら "通知を有効にする" ボタンタップのテストを追加
    // func testTapEnableNotificationsButton() throws { ... }
}
