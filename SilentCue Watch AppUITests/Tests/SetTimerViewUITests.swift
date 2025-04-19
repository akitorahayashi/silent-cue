import XCTest

final class SetTimerViewUITests: XCTestCase {
    var app: XCUIApplication?
    
    override func setUp() {
        continueAfterFailure = false
        let application = XCUIApplication()
        // SCAppEnvironment を使用して初期ビューを設定
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .setTimerView)
        application.launch()
        app = application
        
        XCTAssertNotNil(app, "XCUIApplication が初期化されていること")
        
        // SetTimerView のナビゲーションバーが表示されることを確認
        XCTAssertTrue(
            app!.navigationBars[SCAccessibilityIdentifiers.SetTimerView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "SetTimerView のナビゲーションバーが表示されること"
        )
        
        // 初回起動時に対して通知を許可
        NotificationPermissionHelper.ensureNotificationPermission(for: app!)
    }
    
    override func tearDown() {
        app?.terminate()
        app = nil
        super.tearDown()
    }
    
    func testInitialViewState() throws {
        guard let app = app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
        
        let minutesModeButtonExists = app
            .buttons[SCAccessibilityIdentifiers.SetTimerView.minutesModeButton.rawValue]
            .waitForExistence(timeout: UITestConstants.Timeout.standard)
        XCTAssertTrue(minutesModeButtonExists)
        
        // 初期要素が存在することを確認する
        let settingsButtonExists = app.buttons[SCAccessibilityIdentifiers.SetTimerView.openSettingsButton.rawValue]
                                      .waitForExistence(timeout: UITestConstants.Timeout.short)
        XCTAssertTrue(settingsButtonExists, "設定ボタンが存在する")
        
        XCTAssertTrue(app.buttons[SCAccessibilityIdentifiers.SetTimerView.minutesModeButton.rawValue].exists)
        XCTAssertTrue(app.buttons[SCAccessibilityIdentifiers.SetTimerView.timeModeButton.rawValue].exists)

        let minutesPickerExists = app.pickers[SCAccessibilityIdentifiers.SetTimerView.minutesPickerView.rawValue]
                                     .waitForExistence(timeout: UITestConstants.Timeout.standard)
        XCTAssertTrue(minutesPickerExists, "分選択の Pickerが存在する")

        XCTAssertFalse(app.pickers[SCAccessibilityIdentifiers.SetTimerView.hourMinutePickerView.rawValue].exists) // 初期状態では非表示
        XCTAssertTrue(app.buttons[SCAccessibilityIdentifiers.SetTimerView.startTimerButton.rawValue].exists)
    }
    
    
    func testTimerModeSwitching() throws {
        let timeModeButton = app?.buttons[SCAccessibilityIdentifiers.SetTimerView.timeModeButton.rawValue]
        let minutesModeButton = app?.buttons[SCAccessibilityIdentifiers.SetTimerView.minutesModeButton.rawValue]
        let minutesPicker = app?.pickers[
            SCAccessibilityIdentifiers.SetTimerView.minutesPickerView.rawValue]
        let hourMinutePicker = app?.pickers[SCAccessibilityIdentifiers.SetTimerView.hourMinutePickerView.rawValue]
        
        // 「時刻指定」モードに切り替える
        timeModeButton?.tap()
        XCTAssertTrue(hourMinutePicker?.waitForExistence(timeout: 1) ?? false, "HourMinutePickerが表示されること")
        XCTAssertFalse(minutesPicker?.exists ?? false, "MinutesPickerが非表示になること")
        
        // 「分数指定」モードに戻す
        minutesModeButton?.tap()
        XCTAssertTrue(minutesPicker?.waitForExistence(timeout: 1) ?? false, "MinutesPickerが再表示されること")
        XCTAssertFalse(hourMinutePicker?.exists ?? false, "HourMinutePickerが非表示になること")
    }
    
    func testMinutesPickerInteraction() throws {
        let minutesPickerIdentifier = SCAccessibilityIdentifiers.SetTimerView.minutesPickerView.rawValue
        let minutesPicker = app?.pickers[minutesPickerIdentifier]
        
        // ピッカーが存在することを確認
        XCTAssertTrue(minutesPicker?.waitForExistence(timeout: UITestConstants.Timeout.standard) ?? false, "分数ピッカーが存在すること")
        
        let minutesPickerWheel = minutesPicker?.pickerWheels.firstMatch
        XCTAssertTrue(minutesPickerWheel?.exists ?? false, "分数ピッカーホイールが存在すること")
        
        // 初期値を取得
        guard let initialValue = minutesPickerWheel?.value as? String else {
            XCTFail("分数ピッカーホイールから初期値を取得できませんでした")
            return
        }
        
        // ピッカーを操作
        minutesPickerWheel?.swipeUp()

         sleep(3) // 必要に応じて短い遅延を追加検討
        
        // 新しい値を取得
        guard let newValue = minutesPickerWheel?.value as? String else {
            XCTFail("スワイプ後に分数ピッカーホイールから新しい値を取得できませんでした")
            return
        }
        
        // 値が変わったことを確認
        XCTAssertNotEqual(newValue, initialValue, "スワイプ後に分数ピッカーの値が変わること")
    }
    
    func testHourMinutePickerInteraction() throws {
        app?.buttons[SCAccessibilityIdentifiers.SetTimerView.timeModeButton.rawValue].tap()
        let hourMinutePicker = app?.pickers[SCAccessibilityIdentifiers.SetTimerView.hourMinutePickerView.rawValue]
        // waitForExistence は Bool を返す
        XCTAssertTrue(hourMinutePicker?.waitForExistence(timeout: 1) ?? false)
        
        let hourWheel = hourMinutePicker?.pickerWheels.element(boundBy: 0)
        let minuteWheel = hourMinutePicker?.pickerWheels.element(boundBy: 1)
        
        // 初期値を取得
        let initialHourValue = hourWheel?.value as? String
        let initialMinuteValue = minuteWheel?.value as? String
        
        // 時と分のホイールをスワイプする
        hourWheel?.swipeDown()
        minuteWheel?.swipeUp()
        minuteWheel?.swipeUp()
        
        // スワイプ後の新しい値を取得
        let newHourValue = hourWheel?.value as? String
        let newMinuteValue = minuteWheel?.value as? String
        
        // 値が変わったことを確認
        XCTAssertNotEqual(newHourValue, initialHourValue, "スワイプ後に時間の値が変わること")
        XCTAssertNotEqual(newMinuteValue, initialMinuteValue, "スワイプ後に分の値が変わること")
    }
    
    // 注意: 開始ボタンのテストは、単純なUIテストの範囲外で、モックや状態変更の監視、
    // または次のビューへのナビゲーションが必要になる場合がある
    func testStartButtonExistsAndTappable() throws {
        let startButton = app?.buttons[SCAccessibilityIdentifiers.SetTimerView.startTimerButton.rawValue]
        XCTAssertTrue(startButton?.exists ?? false)
        XCTAssertTrue(startButton?.isEnabled ?? false)
        // タップすると画面遷移や状態変更が発生する可能性があるため、該当する場合はチェックを追加する
        // startButton?.tap()
        // XCTAssertTrue(app?.staticTexts[CountdownView.countdownTimeDisplay.rawValue].waitForExistence(timeout: 2) ?? false) // 確認例
    }
    
    func testSettingsButtonExistsAndTappable() throws {
        let settingsButton = app?.buttons[SCAccessibilityIdentifiers.SetTimerView.openSettingsButton.rawValue]
        XCTAssertTrue(settingsButton?.exists ?? false)
        // 設定タイトルが表示されていることを確認して起動を検証
        XCTAssertTrue(
            app?.navigationBars[SCAccessibilityIdentifiers.SettingsView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard) ?? false,
            "設定画面のナビゲーションバーが表示されている")
    }
}
