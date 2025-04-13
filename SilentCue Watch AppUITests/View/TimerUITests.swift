import XCTest

final class TimerUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        // テストごとにアプリを新規起動
        app = XCUIApplication()
        app.launch()

        // 失敗時のスクリーンショットを自動取得
        continueAfterFailure = false
    }

    func testTimerSetupAndCancel() throws {
        // タイマー設定画面が表示されていることを確認
        XCTAssertTrue(app.staticTexts["Silent Cue"].exists)

        // 「分数」モードが選択されていることを確認
        let minutesMode = app.buttons["分数"]
        XCTAssertTrue(minutesMode.exists)

        // Pickerを操作して5分を選択
        let minutesPicker = app.pickers.firstMatch
        // 時計アプリではピッカーのUIテストは難しいので、存在確認のみ
        XCTAssertTrue(minutesPicker.exists)

        // 開始ボタンをタップ
        let startButton = app.buttons["開始"]
        XCTAssertTrue(startButton.exists)
        startButton.tap()

        // カウントダウン画面に遷移したことを確認
        // 画面上に表示される値は変動するため、キャンセルボタンの存在で確認
        let cancelButton = app.buttons["キャンセル"]
        XCTAssertTrue(cancelButton.exists)

        // キャンセルをタップ
        cancelButton.tap()

        // 初期画面に戻ったことを確認
        XCTAssertTrue(app.staticTexts["Silent Cue"].exists)
    }

    func testTimeModeSelection() throws {
        // 「時刻」モードをタップ
        let timeMode = app.buttons["時刻"]
        XCTAssertTrue(timeMode.exists)
        timeMode.tap()

        // 時刻モードのピッカーが表示されたことを確認
        let timePickers = app.pickers
        XCTAssertEqual(timePickers.count, 2) // 時と分の2つのピッカーがあるはず

        // 分数モードに戻る
        let minutesMode = app.buttons["分数"]
        minutesMode.tap()

        // 分数ピッカーに戻ったことを確認
        XCTAssertEqual(app.pickers.count, 1)
    }

    func testSettingsNavigation() throws {
        // 設定アイコンをタップ
        let settingsButton = app.buttons["gearshape.fill"]
        XCTAssertTrue(settingsButton.exists)
        settingsButton.tap()

        // 設定画面に遷移したことを確認
        XCTAssertTrue(app.staticTexts["設定"].exists)

        // 振動設定のトグルが存在することを確認
        let autoStopToggle = app.switches.firstMatch
        XCTAssertTrue(autoStopToggle.exists)

        // 振動タイプの選択肢が存在することを確認
        XCTAssertTrue(app.staticTexts["Vibration Type"].exists)
        XCTAssertTrue(app.staticTexts["Standard"].exists)

        // バックナビゲーションで戻る（watchOSでは標準ジェスチャーが使える）
        app.swipeRight() // watchOSの標準的な「戻る」ジェスチャー

        // タイマー設定画面に戻ったことを確認
        XCTAssertTrue(app.staticTexts["Silent Cue"].exists)
    }
}
