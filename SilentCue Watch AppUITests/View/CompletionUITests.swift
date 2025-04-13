import XCTest

final class CompletionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        // テストごとにアプリを新規起動
        app = XCUIApplication()

        // タイマー完了画面をテストするための特別な起動引数を設定
        // アプリ側でこの引数を検知して、タイマー完了画面を表示するように実装が必要
        app.launchArguments = ["--ui-testing", "--show-completion-view"]
        app.launch()

        // 失敗時のスクリーンショットを自動取得
        continueAfterFailure = false
    }

    func testCompletionViewElements() throws {
        // 完了画面が表示されることを待機
        // UIテスト用の特別な起動引数により、アプリは直接完了画面を表示するはず

        // 閉じるボタンが表示されていることを確認
        let closeButton = app.buttons["閉じる"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3))

        // ベルアイコンが表示されていることを確認（アイコンは直接テストできないが、関連テキストで代用）
        XCTAssertTrue(app.staticTexts["終了時刻"].exists)

        // 時刻表示が存在することを確認（具体的な値はテスト環境で変わるため、存在確認のみ）
        // 時刻表示は通常テキストコンポーネントとして認識される

        // 開始時刻と使用時間の情報が表示されていることを確認
        XCTAssertTrue(app.staticTexts["開始時刻"].exists)
        XCTAssertTrue(app.staticTexts["タイマー時間"].exists)

        // 閉じるボタンをタップして画面を閉じる
        closeButton.tap()

        // タイマー設定画面に戻ったことを確認
        XCTAssertTrue(app.staticTexts["Silent Cue"].waitForExistence(timeout: 3))
    }

    func testCompletionViewAnimation() throws {
        // 注意: アニメーションのテストは難しいため、基本的な要素の表示確認に限定

        // 閉じるボタンが表示されていることを確認（アニメーション完了後）
        let closeButton = app.buttons["閉じる"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3))

        // 時間情報が表示されることを確認
        XCTAssertTrue(app.staticTexts["タイマー時間"].waitForExistence(timeout: 3))

        // 表示されるはずの他の要素も存在確認
        XCTAssertTrue(app.staticTexts["終了時刻"].exists)
    }
}
