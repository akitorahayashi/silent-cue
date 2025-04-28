import SCShared
@testable import SilentCue_Watch_App
import XCTest

final class SetTimerViewUITests: XCTestCase {
    var app: XCUIApplication!
    // Accessibility Identifiers
    let setTimerView = SCAccessibilityIdentifiers.SetTimerView.self
    let countdownView = SCAccessibilityIdentifiers.CountdownView.self
    let settingsView = SCAccessibilityIdentifiers.SettingsView.self

    override func setUp() {
        continueAfterFailure = false
        let application = XCUIApplication()
        // SetTimerView からテストを開始するように環境設定
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .setTimerView)
        application.launch()
        app = application

        // デバッグ用に要素階層を出力
        print("--- SetTimerView setUp UI Tree Start ---")
        print(app.debugDescription)
        print("--- SetTimerView setUp UI Tree End ---")

        // SetTimerView の主要要素（スタートボタン）が表示されることを確認
        XCTAssertTrue(
            app.buttons[setTimerView.startTimerButton.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "SetTimerView のスタートボタンが表示されること"
        )
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    func testInitialViewState() throws {
        let minutesModeButtonExists = app
            .buttons[setTimerView.minutesModeButton.rawValue]
            .waitForExistence(timeout: UITestConstants.Timeout.standard)
        XCTAssertTrue(minutesModeButtonExists)

        // 初期UI要素の確認
        let settingsButtonExists = app.buttons[setTimerView.openSettingsButton.rawValue]
            .waitForExistence(timeout: UITestConstants.Timeout.short)
        XCTAssertTrue(settingsButtonExists, "設定ボタンが存在する")

        XCTAssertTrue(app.buttons[setTimerView.minutesModeButton.rawValue].exists)
        XCTAssertTrue(app.buttons[setTimerView.timeModeButton.rawValue].exists)

        // 分数ピッカーの存在確認
        let minutesPickerExists = app.otherElements[setTimerView.minutesPickerView.rawValue]
            .waitForExistence(timeout: UITestConstants.Timeout.standard)
        XCTAssertTrue(minutesPickerExists, "分選択の Picker が存在すること")

        // 時刻ピッカーが初期非表示か確認
        XCTAssertFalse(
            app.otherElements[setTimerView.hourMinutePickerView.rawValue]
                .exists,
            "時刻指定の Picker は初期状態では存在しないこと"
        )
        XCTAssertTrue(app.buttons[setTimerView.startTimerButton.rawValue].exists)
    }

    func testTimerModeSwitching() throws {
        let timeModeButton = app.buttons[setTimerView.timeModeButton.rawValue]
        let minutesModeButton = app.buttons[setTimerView.minutesModeButton.rawValue]
        let minutesPicker = app.otherElements[setTimerView.minutesPickerView.rawValue]
        let hourMinutePicker = app.otherElements[setTimerView.hourMinutePickerView.rawValue]

        // 時刻モードへ切り替え
        timeModeButton.tap()
        XCTAssertTrue(hourMinutePicker.waitForExistence(timeout: 1), "時刻指定 Picker が表示されること")
        XCTAssertFalse(minutesPicker.exists, "分数指定 Picker が非表示になること")

        // 分数モードへ切り替え（戻し）
        minutesModeButton.tap()
        XCTAssertTrue(minutesPicker.waitForExistence(timeout: 1), "分数指定 Picker が再表示されること")
        XCTAssertFalse(hourMinutePicker.exists, "時刻指定 Picker が非表示になること")
    }

    func testMinutesPickerInteraction() throws {
        let minutesPicker = app.otherElements[setTimerView.minutesPickerView.rawValue]
        // 初期値の取得
        let initialValueLabel = minutesPicker.staticTexts.firstMatch.label

        // ピッカーをタップしてフォーカスし、Digital Crownを回転
        minutesPicker.tap()
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.2) // 少し回転させて値を変更

        // UI更新待機 (念のため)
        sleep(1)

        // スワイプ後の値を取得
        let newValueLabel = minutesPicker.staticTexts.firstMatch.label

        // 値変更の確認
        XCTAssertNotEqual(newValueLabel, initialValueLabel, "スワイプ操作後に分数ピッカーの値が変わること")
    }

    func testHourMinutePickerInteraction() throws {
        // 時刻モードへ切り替え
        let timeModeButton = app.buttons[setTimerView.timeModeButton.rawValue]
        XCTAssertTrue(timeModeButton.waitForExistence(timeout: UITestConstants.Timeout.standard), "時刻指定モードボタンが存在すること")
        timeModeButton.tap()

        // ピッカーコンテナ表示確認
        let hourMinutePickerContainer = app.otherElements[setTimerView.hourMinutePickerView.rawValue]
        XCTAssertTrue(
            hourMinutePickerContainer.waitForExistence(timeout: UITestConstants.Timeout.standard),
            "時刻指定Pickerコンテナが存在すること"
        )

        // 時刻ピッカーコンポーネント取得
        let pickerComponents = app.otherElements.matching(identifier: setTimerView.hourMinutePickerView.rawValue)

        // 時・分コンテナ特定
        let hourContainer = pickerComponents.element(boundBy: 0)
        let minuteContainer = pickerComponents.element(boundBy: 1)

        // コンテナ存在確認
        XCTAssertTrue(hourContainer.waitForExistence(timeout: UITestConstants.Timeout.short), "時コンテナが存在すること")
        XCTAssertTrue(minuteContainer.waitForExistence(timeout: UITestConstants.Timeout.short), "分コンテナが存在すること")

        // 初期値取得
        guard let initialHourValue = hourContainer.value,
              let initialMinuteValue = minuteContainer.value
        else {
            XCTFail("Failed to get initial picker container values")
            return
        }
        print("Initial Hour Value: \(initialHourValue), Initial Minute Value: \(initialMinuteValue)")

        // --- 時コンテナ操作（タップ＆Digital Crown回転） ---
        hourContainer.tap()
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.4)
        XCUIDevice.shared.rotateDigitalCrown(delta: -0.2)

        // --- 分コンテナ操作（タップ＆Digital Crown回転） ---
        minuteContainer.tap()
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.4)
        XCUIDevice.shared.rotateDigitalCrown(delta: -0.2)

        // 操作後の値を取得
        guard let finalHourValue = hourContainer.value,
              let finalMinuteValue = minuteContainer.value
        else {
            XCTFail("Failed to get final picker container values")
            return
        }
        print("Final Hour Value: \(finalHourValue), Final Minute Value: \(finalMinuteValue)")

        // 値変更の確認
        XCTAssertTrue(
            "\(finalHourValue)" != "\(initialHourValue)" || "\(finalMinuteValue)" != "\(initialMinuteValue)",
            "操作後に時または分の値が変わること " +
                "(Initial: H=\(initialHourValue), M=\(initialMinuteValue), " +
                "Final: H=\(finalHourValue), M=\(finalMinuteValue))"
        )
    }

    func testStartButtonExistsAndTappable() throws {
        let startButton = app.buttons[setTimerView.startTimerButton.rawValue]

        // ボタンが表示されるように少し上にスワイプ (ピッカーを避けるため上部で)
        let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)

        // Add explicit wait within the test for CI stability
        XCTAssertTrue(startButton.waitForExistence(timeout: UITestConstants.Timeout.standard), "スタートボタンが存在する")
        XCTAssertTrue(startButton.isEnabled, "スタートボタンが有効である")
        // タップと画面遷移
        startButton.tap()

        // CountdownView 要素で画面遷移確認 (タイムアウト延長)
        XCTAssertTrue(
            app.staticTexts[countdownView.countdownTimeDisplay.rawValue].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "タップ後、CountdownViewに遷移して時刻フォーマットラベルが表示される"
        )
    }

    func testSettingsButtonExistsAndTappable() throws {
        // ナビゲーションバーの設定ボタン取得
        let settingsButton = app.navigationBars[setTimerView.navigationBarTitle.rawValue]
            .buttons[setTimerView.openSettingsButton.rawValue].firstMatch
        XCTAssertTrue(settingsButton.exists, "ナビゲーションバー内に設定ボタンが存在すること")
        settingsButton.tap()
        // 設定画面への遷移確認
        XCTAssertTrue(
            app.navigationBars[settingsView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "設定画面のナビゲーションバーが表示されている"
        )
    }
}
