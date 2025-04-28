import SCShared
@testable import SilentCue_Watch_App
import XCTest

final class CountdownViewUITests: XCTestCase {
    var app: XCUIApplication!
    // Accessibility Identifiers
    let countdownView = SCAccessibilityIdentifiers.CountdownView.self
    let setTimerView = SCAccessibilityIdentifiers.SetTimerView.self

    override func setUp() {
        continueAfterFailure = false
        let application = XCUIApplication()
        // CountdownView からテストを開始するように環境設定
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .countdownView)
        application.launch()
        app = application
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    func testInitialUIElementsExist() throws {
        // 時間表示要素の存在を確認
        let timeDisplay = app.staticTexts[countdownView.countdownTimeDisplay.rawValue]
        XCTAssertTrue(timeDisplay.exists, "時間表示ラベルが存在する")
        // countdownTimeDisplay の存在も確認
        let timeFormatLabel = app.staticTexts[countdownView.countdownTimeDisplay.rawValue]
        XCTAssertTrue(timeFormatLabel.exists, "時間フォーマットラベルが存在する")

        // キャンセルボタンの存在と有効状態を確認
        let cancelButton = app.buttons[countdownView.cancelTimerButton.rawValue]
        XCTAssertTrue(cancelButton.exists, "キャンセルボタンが存在する")
        XCTAssertTrue(cancelButton.isEnabled, "キャンセルボタンが有効である")
    }

    func testCancelButtonTap() throws {
        let cancelButton = app.buttons[countdownView.cancelTimerButton.rawValue]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: UITestConstants.Timeout.standard), "キャンセルボタンが存在する")
        XCTAssertTrue(cancelButton.isEnabled, "キャンセルボタンが有効である")
        cancelButton.tap()

        // SetTimerView に戻ることを確認
        XCTAssertTrue(
            app.buttons[setTimerView.startTimerButton.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "キャンセル後、SetTimerViewに戻る"
        )
    }
}
