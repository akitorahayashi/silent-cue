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

        // デバッグ用に要素階層を出力
        print("--- CountdownView setUp UI Tree Start ---")
        print(unwrappedApp.debugDescription)
        print("--- CountdownView setUp UI Tree End ---")
        
        // SetTimerView のナビゲーションバーが表示されることを確認
        XCTAssertTrue(
            unwrappedApp.navigationBars[setTimerView.navigationBarTitle.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.short),
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

    func testMinutesPickerInteraction() throws {
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

        // 時刻指定モードへ切り替える
        let timeModeButton = app.buttons[setTimerView.timeModeButton.rawValue]
        XCTAssertTrue(timeModeButton.waitForExistence(timeout: UITestConstants.Timeout.standard), "時刻指定モードボタンが存在すること")
        timeModeButton.tap()

        // ピッカーコンテナが表示されるのを待つ (モード切り替えの確認)
        let hourMinutePickerContainer = app.otherElements[setTimerView.hourMinutePickerView.rawValue]
        XCTAssertTrue(hourMinutePickerContainer.waitForExistence(timeout: UITestConstants.Timeout.standard), "時刻指定Pickerコンテナが存在すること")

        // 'hourMinutePickerView' 識別子を持つ要素をすべて取得
        let pickerComponents = app.otherElements.matching(identifier: setTimerView.hourMinutePickerView.rawValue)

        // 最初の要素を時コンテナ、2番目の要素を分コンテナとする
        let hourContainer = pickerComponents.element(boundBy: 0)
        let minuteContainer = pickerComponents.element(boundBy: 1)

        // コンテナが存在するか確認
        XCTAssertTrue(hourContainer.waitForExistence(timeout: UITestConstants.Timeout.short), "時コンテナが存在すること")
        XCTAssertTrue(minuteContainer.waitForExistence(timeout: UITestConstants.Timeout.short), "分コンテナが存在すること")

        // 初期値を取得 (コンテナ要素の value プロパティを使用)
        guard let initialHourValue = hourContainer.value,
              let initialMinuteValue = minuteContainer.value else {
            XCTFail("Failed to get initial picker container values")
            return
        }
        print("Initial Hour Value: \(initialHourValue), Initial Minute Value: \(initialMinuteValue)")

        // 各コンテナを直接スワイプして操作
        hourContainer.swipeUp(velocity: 250)   // 例: 上スワイプ
        minuteContainer.swipeDown(velocity: 250) // 例: 下スワイプ
        sleep(1) // スワイプ後のUI更新のための待機

        // 操作後の値を取得
        guard let finalHourValue = hourContainer.value,
              let finalMinuteValue = minuteContainer.value else {
            XCTFail("Failed to get final picker container values")
            return
        }
        print("Final Hour Value: \(finalHourValue), Final Minute Value: \(finalMinuteValue)")

        // 値が変わったことを確認 (Any型なので比較前にString等にキャスト推奨だが、直接比較も可能)
        XCTAssertTrue(
            "\(finalHourValue)" != "\(initialHourValue)" || "\(finalMinuteValue)" != "\(initialMinuteValue)",
            "操作後に時または分の値が変わること (Initial: H=\(initialHourValue), M=\(initialMinuteValue), Final: H=\(finalHourValue), M=\(finalMinuteValue))"
        )
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
