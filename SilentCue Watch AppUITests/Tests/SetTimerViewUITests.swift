import SCShared
@testable import SilentCue_Watch_App
import XCTest

final class SetTimerViewUITests: XCTestCase {
    var app: XCUIApplication!
    let setTimerViewIDs = SCAccessibilityIdentifiers.SetTimerView.self
    let countdownViewIDs = SCAccessibilityIdentifiers.CountdownView.self
    let settingsViewIDs = SCAccessibilityIdentifiers.SettingsView.self

    // MARK: - Setup & Teardown

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        
        SCAppEnvironment.setupUITestEnv(for: app, initialView: .setTimerView)
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    /// 初期状態: 分数モードが選択され、分数ピッカーが表示、時刻ピッカーは非表示であること
    func test_initialState_showsMinutesModeByDefault() throws {
        let minutesModeButton = app.buttons[setTimerViewIDs.minutesModeButton.rawValue]
        let timeModeButton = app.buttons[setTimerViewIDs.timeModeButton.rawValue]
        let settingsButton = app.buttons[setTimerViewIDs.openSettingsButton.rawValue]
        let minutesPicker = app.otherElements[setTimerViewIDs.minutesOnlyPicker.rawValue]
        let hourPicker = app.pickers[setTimerViewIDs.hourPicker.rawValue]
        let minutePicker = app.pickers[setTimerViewIDs.minutePicker.rawValue]
        let startButton = app.buttons[setTimerViewIDs.startTimerButton.rawValue]

        XCTAssertTrue(minutesModeButton.waitForExistence(timeout: UITestConstants.Timeout.short), "分数モードボタンが表示される")
        XCTAssertTrue(timeModeButton.exists, "時刻モードボタンが表示される")
        XCTAssertTrue(settingsButton.exists, "設定ボタンが表示される")
        XCTAssertTrue(minutesPicker.exists, "分数ピッカーが表示される")
        XCTAssertFalse(hourPicker.exists, "時ピッカーは表示されない")
        XCTAssertFalse(minutePicker.exists, "分ピッカーは表示されない")
        XCTAssertTrue(startButton.exists, "スタートボタンが表示される")
    }

    /// タイマーモード切替: 分数モードと時刻モードを切り替えると、対応するピッカーが表示/非表示されること
    func test_timerModeSwitching_updatesPickerVisibility() throws {
        let timeModeButton = app.buttons[setTimerViewIDs.timeModeButton.rawValue]
        let minutesModeButton = app.buttons[setTimerViewIDs.minutesModeButton.rawValue]
        let minutesPicker = app.otherElements[setTimerViewIDs.minutesOnlyPicker.rawValue]
        let hourPicker = app.otherElements[setTimerViewIDs.hourPicker.rawValue]
        let minutePicker = app.otherElements[setTimerViewIDs.minutePicker.rawValue]

        // 時刻モードへ切り替え
        timeModeButton.tap()
        XCTAssertTrue(hourPicker.waitForExistence(timeout: UITestConstants.Timeout.standard), "時刻モード切替後: 時ピッカーが表示される")
        XCTAssertTrue(minutePicker.waitForExistence(timeout: UITestConstants.Timeout.standard), "時刻モード切替後: 分ピッカーが表示される")
        XCTAssertFalse(minutesPicker.exists, "時刻モード切替後: 分数ピッカーが非表示になる")

        // 分数モードへ切り替え（戻し）
        minutesModeButton.tap()
        XCTAssertTrue(minutesPicker.waitForExistence(timeout: UITestConstants.Timeout.short), "分数モード切替後: 分数ピッカーが再表示される")
        XCTAssertFalse(hourPicker.exists, "分数モード切替後: 時ピッカーが非表示になる")
        XCTAssertFalse(minutePicker.exists, "分数モード切替後: 分ピッカーが非表示になる")
    }

    /// 分数ピッカー操作: Digital Crown を回転させるとピッカーの値が変わること
    func test_minutesPicker_whenDigitalCrownRotated_updatesValue() throws {
        let minutesPicker = app.otherElements[setTimerViewIDs.minutesOnlyPicker.rawValue]
        XCTAssertTrue(minutesPicker.waitForExistence(timeout: UITestConstants.Timeout.short), "分数ピッカーが存在する")

        let initialValueLabel = minutesPicker.staticTexts.firstMatch.label

        minutesPicker.tap() // フォーカス
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.2)

        // 値が変わるまで少し待つ (Predicateを使用)
        let predicate = NSPredicate(format: "label != %@", initialValueLabel)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: minutesPicker.staticTexts.firstMatch)
        wait(for: [expectation], timeout: UITestConstants.Timeout.short)

        let newValueLabel = minutesPicker.staticTexts.firstMatch.label
        XCTAssertNotEqual(newValueLabel, initialValueLabel, "Digital Crown 操作後に分数ピッカーの値が変わること")
    }

    /// 時刻ピッカー操作: Digital Crown を回転させると時または分の値が変わること
    func test_hourMinutePicker_whenDigitalCrownRotated_updatesValue() throws {
        // 時刻モードへ切り替え
        let timeModeButton = app.buttons[setTimerViewIDs.timeModeButton.rawValue]
        XCTAssertTrue(timeModeButton.waitForExistence(timeout: UITestConstants.Timeout.short), "時刻モードボタンが存在する")
        timeModeButton.tap()

        // 時・分ピッカーの存在確認
        let hourPicker = app.otherElements[setTimerViewIDs.hourPicker.rawValue]
        let minutePicker = app.otherElements[setTimerViewIDs.minutePicker.rawValue]
        XCTAssertTrue(hourPicker.waitForExistence(timeout: UITestConstants.Timeout.standard), "時ピッカーが存在する")
        XCTAssertTrue(minutePicker.waitForExistence(timeout: UITestConstants.Timeout.standard), "分ピッカーが存在する")

        // 初期値取得 (otherElements経由のため、staticTexts.firstMatch.label で値を取得)
        let initialHourLabel = hourPicker.staticTexts.firstMatch.label
        let initialMinuteLabel = minutePicker.staticTexts.firstMatch.label

        // 時コンテナ操作
        hourPicker.tap() // フォーカス
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.4)
        XCUIDevice.shared.rotateDigitalCrown(delta: -0.2)

        // 分コンテナ操作
        minutePicker.tap() // フォーカス
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.4)
        XCUIDevice.shared.rotateDigitalCrown(delta: -0.2)

        // 値が変わるまで待つ (otherElements経由のため、staticTexts.firstMatch.label で値を取得)
        let finalHourLabel = hourPicker.staticTexts.firstMatch.label
        let finalMinuteLabel = minutePicker.staticTexts.firstMatch.label

        // 値変更の確認
        XCTAssertTrue(
            finalHourLabel != initialHourLabel || finalMinuteLabel != initialMinuteLabel,
            "Digital Crown 操作後に時または分の値が変わること (Initial: H=\(initialHourLabel), M=\(initialMinuteLabel), Final: H=\(finalHourLabel), M=\(finalMinuteLabel))"
        )
    }

    // MARK: - Navigation

    /// スタートボタン: 表示されており、タップすると CountdownView に遷移すること
    func test_startButton_whenTapped_navigatesToCountdownView() throws {
        let startButton = app.buttons[setTimerViewIDs.startTimerButton.rawValue]

        // スワイプ操作は不安定なため、waitForExistence で確認し、存在すれば操作する方針に変更
        if !startButton.waitForExistence(timeout: UITestConstants.Timeout.standard) {
             XCTFail("スタートボタンが見つかりませんでした")
             return
         }

        XCTAssertTrue(startButton.isEnabled, "スタートボタンがタップ可能である")
        startButton.tap()

        // CountdownView 要素で画面遷移確認
        XCTAssertTrue(
            app.staticTexts[countdownViewIDs.countdownTimeDisplay.rawValue].waitForExistence(timeout: UITestConstants.Timeout.standard),
            "スタートボタンタップ後、CountdownViewに遷移する"
        )
    }

    /// 設定ボタン: 表示されており、タップすると SettingsView に遷移すること
    func test_settingsButton_whenTapped_navigatesToSettingsView() throws {
        let settingsButton = app.navigationBars[setTimerViewIDs.navigationBarTitle.rawValue]
            .buttons[setTimerViewIDs.openSettingsButton.rawValue].firstMatch

        XCTAssertTrue(settingsButton.waitForExistence(timeout: UITestConstants.Timeout.short), "設定ボタンが表示される")
        XCTAssertTrue(settingsButton.isHittable, "設定ボタンがタップ可能である")
        settingsButton.tap()

        // SettingsView 要素で画面遷移確認
        XCTAssertTrue(
            app.navigationBars[settingsViewIDs.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "設定ボタンタップ後、SettingsViewに遷移する"
        )
    }
}
