import XCTest

final class TimerCompletionViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // TimerCompletionView を直接表示するための起動引数
        app.launchArguments = ["-testing-timer-completion-view"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testViewElements() throws {
        // メインの完了メッセージが存在するか確認
        // "Timer Completed!" を実際の TimerCompletionView に表示されるテキストに置き換えてください
        XCTAssertTrue(app.staticTexts["Timer Completed!"].waitForExistence(timeout: 5))

        // "OK" ボタンが存在するか確認
        // "OKButtonIdentifier" を OK ボタンの実際の accessibility identifier に置き換えてください
        XCTAssertTrue(app.buttons["OKButtonIdentifier"].exists)
        XCTAssertTrue(app.buttons["OKButtonIdentifier"].isEnabled)
    }

    func testTapOKButton() throws {
        let okButton = app.buttons["OKButtonIdentifier"] // 正しい識別子を使用してください

        // タップする前にボタンが存在することを確認
        XCTAssertTrue(okButton.waitForExistence(timeout: 5))

        okButton.tap()

        // OK をタップした後の状態を確認するアサーションを追加
        // 例: アプリが SetTimerView に戻ったか確認
        // これには SetTimerView に一意の識別子が必要です
        // XCTAssertTrue(app.otherElements["SetTimerScrollView"].waitForExistence(timeout: 5))

        // または、ビューが単に閉じる場合は、完了要素がなくなったことを確認
        // XCTAssertFalse(app.staticTexts["Timer Completed!"].exists)
        // XCTAssertFalse(okButton.exists)
    }
} 