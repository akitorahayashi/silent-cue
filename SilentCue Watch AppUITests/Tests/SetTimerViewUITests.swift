import XCTest

final class SetTimerViewUITests: XCTestCase {

    // XCUIApplication をオプショナルに変更
    var app: XCUIApplication?
    let setTimerView = SCAccessibilityIdentifiers.SetTimerView.self
    let afterMinutesButtonId = "TimerModeButtonAfterMinutes" // SetTimerView から取得した Raw String
    let atTimeButtonId = "TimerModeButtonAtTime" // SetTimerView から取得した Raw String

    // TimerCompletionViewUITests に合わせて setUp と tearDown を実装
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
            app!.navigationBars[setTimerView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "SetTimerView のナビゲーションバーが表示されること"
        )
        
        // 初回起動時に対して通知を許可
        NotificationPermissionHelper.ensureNotificationPermission(for: app!)
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testInitialViewState() throws {
        // 初期要素が存在することを確認する
        XCTAssertTrue(app?.buttons[afterMinutesButtonId].exists ?? false)
        XCTAssertTrue(app?.buttons[atTimeButtonId].exists ?? false)
        XCTAssertTrue(app?.pickers[setTimerView.minutesPickerView.rawValue].exists ?? false)
        XCTAssertFalse(app?.pickers[setTimerView.hourMinutePickerView.rawValue].exists ?? false) // 初期状態では非表示である
        XCTAssertTrue(app?.buttons[setTimerView.startTimerButton.rawValue].exists ?? false)
        XCTAssertTrue(app?.navigationBars[setTimerView.navigationBarTitle.rawValue].exists ?? false)
        XCTAssertTrue(app?.buttons[setTimerView.openSettingsPage.rawValue].exists ?? false)
    }

    func testModeSwitching() throws {
        let atTimeButton = app?.buttons[atTimeButtonId]
        let afterMinutesButton = app?.buttons[afterMinutesButtonId]
        let minutesPicker = app?.pickers[setTimerView.minutesPickerView.rawValue]
        let hourMinutePicker = app?.pickers[setTimerView.hourMinutePickerView.rawValue]

        // 「時刻指定」モードに切り替える
        atTimeButton?.tap()
        // waitForExistence は Bool を返す
        XCTAssertTrue(hourMinutePicker?.waitForExistence(timeout: 1) ?? false, "HourMinutePickerが表示されること")
        XCTAssertFalse(minutesPicker?.exists ?? false, "MinutesPickerが非表示になること")

        // 「分数指定」モードに戻す
        afterMinutesButton?.tap()
        XCTAssertTrue(minutesPicker?.waitForExistence(timeout: 1) ?? false, "MinutesPickerが再表示されること")
        XCTAssertFalse(hourMinutePicker?.exists ?? false, "HourMinutePickerが非表示になること")
    }

    func testMinutesPickerInteraction() throws {
        let minutesPicker = app?.pickers[setTimerView.minutesPickerView.rawValue]
        let pickerWheel = minutesPicker?.pickerWheels.firstMatch // 単一ホイールと仮定する

        XCTAssertTrue(minutesPicker?.exists ?? false)
        // ピッカーホイールを上（または下）にスワイプして値を変更する
        // 特定の値を確認するには、複数回のスワイプやチェックが必要な場合がある
        pickerWheel?.swipeUp()
        // 例: 値が変更されたか可能であれば確認する
        // let newValue = pickerWheel.value as? String
        // XCTAssertNotEqual(newValue, initialValue)
    }

    func testHourMinutePickerInteraction() throws {
        app?.buttons[atTimeButtonId].tap()
        let hourMinutePicker = app?.pickers[setTimerView.hourMinutePickerView.rawValue]
        // waitForExistence は Bool を返す
        XCTAssertTrue(hourMinutePicker?.waitForExistence(timeout: 1) ?? false)

        let hourWheel = hourMinutePicker?.pickerWheels.element(boundBy: 0)
        let minuteWheel = hourMinutePicker?.pickerWheels.element(boundBy: 1)

        // 時と分のホイールをスワイプする
        // 必要に応じてスワイプ方向（上/下）と回数を調整する
        hourWheel?.swipeDown()
        minuteWheel?.swipeUp()
        minuteWheel?.swipeUp() // 例: 2回スワイプ

        // 必要に応じてアサーションを追加して選択された値を確認する
    }

    // 注意: 開始ボタンのテストは、単純なUIテストの範囲外で、モックや状態変更の監視、
    // または次のビューへのナビゲーションが必要になる場合がある
    func testStartButtonExistsAndTappable() throws {
        let startButton = app?.buttons[setTimerView.startTimerButton.rawValue]
        XCTAssertTrue(startButton?.exists ?? false)
        XCTAssertTrue(startButton?.isEnabled ?? false)
        // タップすると画面遷移や状態変更が発生する可能性があるため、該当する場合はチェックを追加する
        // startButton?.tap()
        // XCTAssertTrue(app?.staticTexts[CountdownView.countdownTimeDisplay.rawValue].waitForExistence(timeout: 2) ?? false) // 確認例
    }

     func testSettingsButtonExistsAndTappable() throws {
        let settingsButton = app?.buttons[setTimerView.openSettingsPage.rawValue]
        XCTAssertTrue(settingsButton?.exists ?? false)
        XCTAssertTrue(settingsButton?.isEnabled ?? false)
        // タップすると設定ビューに遷移するはずである
        // settingsButton?.tap()
        // XCTAssertTrue(app?.navigationBars[SettingsView.navigationBarTitle.rawValue].waitForExistence(timeout: 2) ?? false) // 確認例
    }
}
