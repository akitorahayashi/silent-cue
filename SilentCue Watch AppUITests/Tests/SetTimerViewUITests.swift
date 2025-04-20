import XCTest

final class SetTimerViewUITests: XCTestCase {
    var app: XCUIApplication?
    // Accessibility Identifiers
    let setTimerView = SCAccessibilityIdentifiers.SetTimerView.self
    let countdownView = SCAccessibilityIdentifiers.CountdownView.self
    let settingsView = SCAccessibilityIdentifiers.SettingsView.self

    override func setUp() {
        continueAfterFailure = false
        let application = XCUIApplication()
        // SCAppEnvironment を使用して初期ビューを設定
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .setTimerView)
        application.launch()
        app = application

        guard let unwrappedApp = app else {
            XCTFail("XCUIApplication instance failed to initialize in setUp.")
            return
        }
        XCTAssertNotNil(unwrappedApp, "XCUIApplication が初期化されていること")

        // SetTimerView のナビゲーションバーが表示されることを確認
        XCTAssertTrue(
            unwrappedApp.navigationBars[setTimerView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "SetTimerView のナビゲーションバーが表示されること"
        )

        // 初回起動時に対して通知を許可
        NotificationPermissionHelper.ensureNotificationPermission(for: unwrappedApp)
    }

    override func tearDown() {
        app?.terminate()
        app = nil
        super.tearDown()
    }

    func testInitialViewState() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }

        let minutesModeButtonExists = app
            .buttons[setTimerView.minutesModeButton.rawValue]
            .waitForExistence(timeout: UITestConstants.Timeout.standard)
        XCTAssertTrue(minutesModeButtonExists)

        // 初期要素が存在することを確認する
        let settingsButtonExists = app.buttons[setTimerView.openSettingsButton.rawValue]
            .waitForExistence(timeout: UITestConstants.Timeout.short)
        XCTAssertTrue(settingsButtonExists, "設定ボタンが存在する")

        XCTAssertTrue(app.buttons[setTimerView.minutesModeButton.rawValue].exists)
        XCTAssertTrue(app.buttons[setTimerView.timeModeButton.rawValue].exists)

        // Picker として MinutesPicker が存在することを確認
        let minutesPickerExists = app.otherElements[setTimerView.minutesPickerView.rawValue]
            .waitForExistence(timeout: UITestConstants.Timeout.standard)
        XCTAssertTrue(minutesPickerExists, "分選択の Picker が存在すること")

        // Picker として HourMinutePicker が初期状態では存在しないことを確認
        XCTAssertFalse(
            app.otherElements[setTimerView.hourMinutePickerView.rawValue]
                .exists,
            "時刻指定の Picker は初期状態では存在しないこと"
        )
        XCTAssertTrue(app.buttons[setTimerView.startTimerButton.rawValue].exists)
    }

    func testTimerModeSwitching() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
        let timeModeButton = app.buttons[setTimerView.timeModeButton.rawValue]
        let minutesModeButton = app.buttons[setTimerView.minutesModeButton.rawValue]
        let minutesPicker = app.otherElements[setTimerView.minutesPickerView.rawValue]
        let hourMinutePicker = app.otherElements[setTimerView.hourMinutePickerView.rawValue]

        // 「時刻指定」モードに切り替える
        timeModeButton.tap()
        XCTAssertTrue(hourMinutePicker.waitForExistence(timeout: 1), "時刻指定 Picker が表示されること")
        XCTAssertFalse(minutesPicker.exists, "分数指定 Picker が非表示になること")

        // 「分数指定」モードに戻す
        minutesModeButton.tap()
        XCTAssertTrue(minutesPicker.waitForExistence(timeout: 1), "分数指定 Picker が再表示されること")
        XCTAssertFalse(hourMinutePicker.exists, "時刻指定 Picker が非表示になること")
    }

    func 実際の実装をよく確認して、どこをスワイプすればいいのかとかちゃんと考えてくださいね。必要であればアクセシビリティーIDを追加してもいいよ。ScアクセシビリティーID.スウィフトにね。() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
        
        let minutesPicker = app.otherElements[setTimerView.minutesPickerView.rawValue]
        // 初期値を取得
        let initialValueLabel = minutesPicker.staticTexts.firstMatch.label

        // ピッカー要素自体をスワイプ
        minutesPicker.swipeUp()

        sleep(1)

        // 新しい値を取得
        let newValueLabel = minutesPicker.staticTexts.firstMatch.label

        // 値が変わったことを確認
        XCTAssertNotEqual(newValueLabel, initialValueLabel, "スワイプ操作後に分数ピッカーの値が変わること")
    }

    func testHourMinutePickerInteraction() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }

        // 「時刻指定」モードへ
        app.buttons[setTimerView.timeModeButton.rawValue].tap()

        let hourMinutePicker = app.otherElements[setTimerView.hourMinutePickerView.rawValue]

        // ホイールのコンテナ要素を取得 (テキスト特定のため必要)
        let hourWheelContainer = hourMinutePicker.children(matching: .any).element(boundBy: 0)
        let minuteWheelContainer = hourMinutePicker.children(matching: .any).element(boundBy: 1)
        XCTAssertTrue(hourWheelContainer.exists, "時ホイールコンテナが存在すること")
        XCTAssertTrue(minuteWheelContainer.exists, "分ホイールコンテナが存在すること")

        // 初期値を取得
        let initialHourLabel = hourWheelContainer.staticTexts.firstMatch.label
        let initialMinuteLabel = minuteWheelContainer.staticTexts.firstMatch.label

        // ピッカー要素自体をスワイプ
        hourMinutePicker.swipeUp()

        sleep(1)

        // 新しい値を取得
        let newHourLabel = hourWheelContainer.staticTexts.firstMatch.label
        let newMinuteLabel = minuteWheelContainer.staticTexts.firstMatch.label

        // 値が変わったことを確認
        XCTAssertNotEqual(newHourLabel, initialHourLabel, "スワイプ操作後に時間の値が変わること")
        XCTAssertNotEqual(newMinuteLabel, initialMinuteLabel, "スワイプ操作後に分の値が変わること")
    }

    func testStartButtonExistsAndTappable() throws {
         guard let app else {
             XCTFail("XCUIApplication instance was nil")
             return
         }
         let startButton = app.buttons[setTimerView.startTimerButton.rawValue]
         XCTAssertTrue(startButton.exists)
         XCTAssertTrue(startButton.isEnabled)
         // タップして画面遷移を確認
         startButton.tap()
         // CountdownView の要素が存在するかで画面遷移を確認する例
         XCTAssertTrue(app.staticTexts[countdownView.timeFormatLabel.rawValue].waitForExistence(timeout: 2))
    }

    func testSettingsButtonExistsAndTappable() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
        // ナビゲーションバー内の設定ボタンを特定して取得
        let settingsButton = app.navigationBars[setTimerView.navigationBarTitle.rawValue]
            .buttons[setTimerView.openSettingsButton.rawValue].firstMatch
        XCTAssertTrue(settingsButton.exists, "ナビゲーションバー内に設定ボタンが存在すること")
        settingsButton.tap()
        // 設定画面のナビゲーションバーが表示されていることを確認して画面遷移を検証
        XCTAssertTrue(
            app.navigationBars[settingsView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "設定画面のナビゲーションバーが表示されている"
        )
    }
}
