import XCTest

final class CountdownViewUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false

        // テスト用の環境変数を設定
        AppEnvironment.setupStandardTestEnvironment(for: app)

        app.launch()

        // 通知許可の確認・実行
        NotificationPermissionHelper.ensureNotificationPermission(for: app)

        XCTAssertTrue(
            app.staticTexts["Silent Cue"].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "アプリタイトルが表示される"
        )
    }

    func testNavigateToCountdown() throws {
        // 「分後」ボタンが表示されるまで待機してタップ
        navigateToCountdownView()

        // カウントダウン画面の要素が表示されるか確認
        let timeFormatExists = app.staticTexts.matching(identifier: "TimeFormatLabel").firstMatch
            .waitForExistence(timeout: UITestConstants.Timeout.standard)
        XCTAssertTrue(timeFormatExists, "時間フォーマットラベルが表示される")

        let timeDisplayExists = app.staticTexts.matching(identifier: "CountdownTimeDisplay").firstMatch
            .waitForExistence(timeout: UITestConstants.Timeout.short)
        XCTAssertTrue(timeDisplayExists, "カウントダウン表示が表示される")

        let cancelButtonExists = app.buttons.matching(identifier: "CancelTimerButton").firstMatch
            .waitForExistence(timeout: UITestConstants.Timeout.short)
        XCTAssertTrue(cancelButtonExists, "キャンセルボタンが表示される")
    }

    func testCancelCountdown() throws {
        // まずカウントダウン画面に移動
        navigateToCountdownView()

        // カウントダウン画面の要素が表示されるか確認
        XCTAssertTrue(
            app.staticTexts.matching(identifier: "TimeFormatLabel").firstMatch
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "時間をフォーマットしたラベルが表示される"
        )

        // キャンセルボタンをタップ
        let cancelButton = app.buttons.matching(identifier: "CancelTimerButton").firstMatch
        XCTAssertTrue(cancelButton.waitForExistence(timeout: UITestConstants.Timeout.short), "キャンセルボタンが表示される")
        cancelButton.tap()

        // タイマー開始画面に戻ったか確認
        let titleExists = app.staticTexts["Silent Cue"].waitForExistence(timeout: UITestConstants.Timeout.standard)
        XCTAssertTrue(titleExists, "キャンセル後、開始画面のタイトルが表示される")
    }

    // カウントダウン画面に移動するメソッド
    private func navigateToCountdownView() {
        // 画面上部3割あたりから上へスワイプ（ピッカーを避ける）
        let startPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let endPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)

        // StartTimerButtonを見つけてタップ
        let startButton = app.buttons.matching(identifier: "StartTimerButton").firstMatch
        XCTAssertTrue(startButton.waitForExistence(timeout: UITestConstants.Timeout.standard), "開始ボタンが表示される")
        startButton.tap()
    }
}
