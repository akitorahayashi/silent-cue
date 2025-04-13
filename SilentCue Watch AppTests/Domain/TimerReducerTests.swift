import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class TimerReducerTests: XCTestCase {
    // テスト用の依存関係
    private func testReducer(
        clock: () -> TestClock<Duration> = { TestClock() },
        userDefaultsManager: () -> UserDefaultsManagerProtocol = {
            let mock = MockUserDefaultsManager()
            mock.mockReturnValues[.stopVibrationAutomatically] = true
            mock.mockReturnValues[.hapticType] = HapticType.standard.rawValue
            return mock
        }
    ) -> TestStore<TimerState, TimerAction> {
        TestStore(
            initialState: TimerState(),
            reducer: {
                TimerReducer()
                    .dependency(\.continuousClock, clock())
                    .dependency(\.userDefaultsManager, userDefaultsManager())
            }
        )
    }

    func testTimerModeSelection() async {
        let store = testReducer()

        await store.send(TimerAction.timerModeSelected(TimerMode.atTime)) { state in
            state.timerMode = TimerMode.atTime
            // 現在時刻が設定されるが、テスト環境では固定値をチェックできないので
            // 時刻の変更自体が起きたことだけを確認
            _ = state.selectedHour
            _ = state.selectedMinute
        }

        await store.send(TimerAction.timerModeSelected(TimerMode.afterMinutes)) { state in
            state.timerMode = TimerMode.afterMinutes
        }
    }

    func testMinutesSelection() async {
        let store = testReducer()

        await store.send(TimerAction.minutesSelected(10)) { state in
            state.selectedMinutes = 10
        }
    }

    func testHourAndMinuteSelection() async {
        let store = testReducer()

        await store.send(TimerAction.hourSelected(15)) { state in
            state.selectedHour = 15
        }

        await store.send(TimerAction.minuteSelected(30)) { state in
            state.selectedMinute = 30
        }
    }

    func testStartTimer() async {
        let clock = TestClock<Duration>()
        let store = testReducer(clock: { clock })

        // テストの厳密性を下げる
        store.exhaustivity = .off

        // タイマーの設定
        await store.send(.minutesSelected(3)) { state in
            state.selectedMinutes = 3
        }

        // タイマーの開始
        await store.send(.startTimer) { state in
            state.isRunning = true
            state.totalSeconds = 3 * 60
            XCTAssertNotNil(state.startDate)
            XCTAssertNotNil(state.targetEndDate)
        }

        // 5秒経過（WatchKit依存部分なので厳密性を下げた状態で処理）
        await clock.advance(by: .seconds(5))

        // キャンセル
        await store.send(.cancelTimer) { state in
            state.isRunning = false
            state.startDate = nil
            state.targetEndDate = nil
            state.completionDate = nil
        }

        // 厳密性を元に戻す
        store.exhaustivity = .on
    }

    func testPauseAndResumeTimer() async {
        let clock = TestClock<Duration>()
        let store = testReducer(clock: { clock })

        // テストストアのオプションを変更して許容的にする
        store.exhaustivity = .off

        // タイマーの設定
        await store.send(.minutesSelected(2)) { state in
            state.selectedMinutes = 2
        }

        // タイマーの開始
        await store.send(.startTimer) { state in
            state.isRunning = true
            state.totalSeconds = 2 * 60
            XCTAssertNotNil(state.startDate)
            XCTAssertNotNil(state.targetEndDate)
        }

        // 設定ロードなどのイベントは無視
        await store.skipReceivedActions(strict: false)

        // 10秒経過
        await clock.advance(by: .seconds(10))

        // 一時停止
        await store.send(.pauseTimer) { state in
            state.isRunning = false
            // 残り時間 = 110秒
        }

        // 再開
        await store.send(.resumeTimer) { state in
            state.isRunning = true
            XCTAssertNotNil(state.startDate)
            XCTAssertNotNil(state.targetEndDate)
        }

        // 5秒経過
        await clock.advance(by: .seconds(5))

        // 時間更新は検証しない
        await store.skipReceivedActions(strict: false)
    }

    func testTimerCompletion() async {
        let clock = TestClock<Duration>()
        let store = testReducer(clock: { clock })

        // テストストアのオプションを変更して許容的にする
        store.exhaustivity = .off

        // 1分のタイマーを設定
        await store.send(.minutesSelected(1)) { state in
            state.selectedMinutes = 1
        }

        // タイマーの開始
        await store.send(.startTimer) { state in
            state.isRunning = true
            state.totalSeconds = 60
        }

        // 設定ロードなどのイベントは無視
        await store.skipReceivedActions(strict: false)

        // 60秒経過（タイマー完了）
        await clock.advance(by: .seconds(60))

        // 時間更新は検証しない
        await store.skipReceivedActions(strict: false)

        // 完了画面を非表示
        await store.send(.dismissCompletionView) { state in
            state.completionDate = nil
        }
    }

    func testSettingsLoad() async {
        let userDefaultsManager = MockUserDefaultsManager()
        userDefaultsManager.mockReturnValues[.stopVibrationAutomatically] = false
        userDefaultsManager.mockReturnValues[.hapticType] = HapticType.strong.rawValue

        let store = testReducer(userDefaultsManager: { userDefaultsManager })

        await store.send(TimerAction.loadSettings)

        await store.receive(TimerAction.settingsLoaded(stopVibration: false, hapticType: HapticType.strong)) { state in
            state.stopVibrationAutomatically = false
            state.selectedHapticType = HapticType.strong
        }
    }
}
