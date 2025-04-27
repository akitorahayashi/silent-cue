import SCShared
@testable import SilentCue_Watch_App
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
        // SetTimerView からテストを開始するように環境設定
        SCAppEnvironment.setupUITestEnv(for: application, initialView: .setTimerView)
        application.launch()
        app = application

        guard let unwrappedApp = app else {
            XCTFail("XCUIApplication instance failed to initialize in setUp.")
            return
        }
        XCTAssertNotNil(unwrappedApp, "XCUIApplication が初期化されていること")

        // 初回起動時に対して通知を許可 (要素チェックの前に実行)
        NotificationPermissionHelper.ensureNotificationPermission(for: unwrappedApp)

        // デバッグ用に要素階層を出力
        print("--- SetTimerView setUp UI Tree Start ---")
        print(unwrappedApp.debugDescription)
        print("--- SetTimerView setUp UI Tree End ---")

        // SetTimerView の主要要素（スタートボタン）が表示されることを確認
        XCTAssertTrue(
            unwrappedApp.buttons[setTimerView.startTimerButton.rawValue]
                .waitForExistence(timeout: UITestConstants.Timeout.standard),
            "SetTimerView のスタートボタンが表示されること"
        )
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
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
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
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }

        let minutesPicker = app.otherElements[setTimerView.minutesPickerView.rawValue]
        // 初期値の取得
        let initialValueLabel = minutesPicker.staticTexts.firstMatch.label

        // ピッカーをスワイプ
        minutesPicker.swipeUp()

        // スワイプ後の値を取得
        let newValueLabel = minutesPicker.staticTexts.firstMatch.label

        // 値変更の確認
        XCTAssertNotEqual(newValueLabel, initialValueLabel, "スワイプ操作後に分数ピッカーの値が変わること")
    }

    func testHourMinutePickerInteraction() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }

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
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.2)
        XCUIDevice.shared.rotateDigitalCrown(delta: -0.1)

        // --- 分コンテナ操作（タップ＆Digital Crown回転） ---
        minuteContainer.tap()
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.2)
        XCUIDevice.shared.rotateDigitalCrown(delta: -0.1)

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
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
        let startButton = app.buttons[setTimerView.startTimerButton.rawValue]
        XCTAssertTrue(startButton.exists)
        XCTAssertTrue(startButton.isEnabled)
        // タップと画面遷移確認
        startButton.tap()
        // CountdownView 要素で画面遷移確認
        XCTAssertTrue(app.staticTexts[countdownView.timeFormatLabel.rawValue].waitForExistence(timeout: 2))
    }

    func testSettingsButtonExistsAndTappable() throws {
        guard let app else {
            XCTFail("XCUIApplication instance was nil")
            return
        }
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
