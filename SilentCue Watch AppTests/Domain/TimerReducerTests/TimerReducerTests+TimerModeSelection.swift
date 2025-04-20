import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

extension TimerReducerTests {
    // テスト: タイマーモード選択時の状態変化と秒数再計算
    func testTimerModeSelection() async {
        let initialDate = Date(timeIntervalSince1970: 1000)
        let actionDate = Date(timeIntervalSince1970: 2000)
        let calendar = Calendar.current // 一貫性のために Calendar.current を使用

        // 初期状態を作成
        let initialState = createInitialState(now: initialDate)

        // 期待される初期合計秒数をユーティリティ関数で計算
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: initialDate,
            calendar: calendar // 一貫性のあるカレンダーを渡す
        )

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(actionDate)
            // TestSupport からモックを注入
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // 初期状態のアサーション
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 60)

        // .time を選択
        let expectedHour = calendar.component(.hour, from: actionDate)
        let expectedMinute = calendar.component(.minute, from: actionDate)
        // 期待される合計秒数をユーティリティ関数で計算
        let expectedAtTimeSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes, // この値は .time では影響しない
            selectedHour: expectedHour,
            selectedMinute: expectedMinute,
            now: actionDate,
            calendar: calendar
        )

        await store.send(TimerReducer.Action.timerModeSelected(.time)) { /* 状態変更 */
            $0.timerMode = .time
            $0.selectedHour = expectedHour
            $0.selectedMinute = expectedMinute
            // totalSeconds/currentRemainingSeconds/duration は Reducer が TimeCalculation を呼び出して計算
            $0.totalSeconds = expectedAtTimeSeconds
            $0.currentRemainingSeconds = expectedAtTimeSeconds
            $0.timerDurationMinutes = expectedAtTimeSeconds / 60
        }

        // 再度 .minutes を選択
        // ユーティリティ関数で期待される秒数を計算
        let currentState = store.state // .time に切り替えた後の状態を取得
        let expectedAfterMinutesSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .minutes,
            selectedMinutes: currentState.selectedMinutes, // 1 であるはず
            selectedHour: currentState.selectedHour,
            selectedMinute: currentState.selectedMinute,
            now: actionDate,
            calendar: calendar
        )

        await store.send(TimerReducer.Action.timerModeSelected(.minutes)) { /* 状態変更 */
            $0.timerMode = .minutes
            $0.totalSeconds = expectedAfterMinutesSeconds
            $0.currentRemainingSeconds = expectedAfterMinutesSeconds
            $0.timerDurationMinutes = expectedAfterMinutesSeconds / 60
            XCTAssertEqual(expectedAfterMinutesSeconds, 60)
        }
        // モード選択アクションはエフェクトを返さないはずだが、念のため完了を確認
        await store.finish()
    }

    // テスト: 分数選択時の状態変化と秒数再計算
    func testMinutesSelected() async {
        let initialDate = Date(timeIntervalSince1970: 0)
        let actionDate = Date(timeIntervalSince1970: 100)
        let initialMinutes = 1
        let newMinutes = 5
        let calendar = Calendar.current // Add calendar instance

        // 初期状態を作成 (.minutes)
        let initialState = createInitialState(now: initialDate, selectedMinutes: initialMinutes, timerMode: .minutes)
        // Pass all required args
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .minutes,
            selectedMinutes: initialMinutes,
            selectedHour: initialState.selectedHour, // Pass required arg
            selectedMinute: initialState.selectedMinute, // Pass required arg
            now: initialDate,
            calendar: calendar // Pass calendar
        )

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(actionDate)
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
            $0.continuousClock = TestClock() // 依存性として必要
        }

        // 初期状態確認
        XCTAssertEqual(store.state.selectedMinutes, initialMinutes)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 60)

        // 新しい分数を選択
        // Pass all required args
        let expectedNewSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .minutes,
            selectedMinutes: newMinutes,
            selectedHour: initialState.selectedHour, // Pass required arg
            selectedMinute: initialState.selectedMinute, // Pass required arg
            now: actionDate,
            calendar: calendar // Pass calendar
        )
        XCTAssertEqual(expectedNewSeconds, 300)

        await store.send(.minutesSelected(newMinutes)) { state in
            state.selectedMinutes = newMinutes
            // Pass all required args for recalculation check
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .minutes,
                selectedMinutes: newMinutes,
                selectedHour: state.selectedHour,
                selectedMinute: state.selectedMinute,
                now: actionDate,
                calendar: calendar // Pass calendar
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = recalculatedSeconds / 60
            XCTAssertEqual(recalculatedSeconds, expectedNewSeconds)
        }
        await store.finish()
    }

    // テスト: 時刻選択時の状態変化と秒数再計算 (.time モード)
    func testHourMinuteSelected() async {
        let initialDate = Date(timeIntervalSince1970: 0) // 例: 09:00 JST
        let actionDate = Date(timeIntervalSince1970: 100)
        let calendar = Calendar.current
        var components = calendar.dateComponents(in: TimeZone(identifier: "Asia/Tokyo")!, from: initialDate)
        components.hour = 9
        components.minute = 0
        let initialTime = calendar.date(from: components)!

        let initialHour = 9
        let initialMinute = 0
        let newHour = 10
        let newMinute = 30

        // 初期状態を作成 (.time)
        let initialState = createInitialState(
            now: initialTime,
            timerMode: .time,
            selectedHour: initialHour,
            selectedMinute: initialMinute
        )
        // Pass all required args
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes, // Pass required arg
            selectedHour: initialHour,
            selectedMinute: initialMinute,
            now: initialTime,
            calendar: calendar // Pass calendar
        )

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(actionDate) // アクション時の時刻
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
            $0.continuousClock = TestClock()
        }

        // 初期状態確認
        XCTAssertEqual(store.state.timerMode, .time)
        XCTAssertEqual(store.state.selectedHour, initialHour)
        XCTAssertEqual(store.state.selectedMinute, initialMinute)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)

        // 新しい時を選択
        // Pass all required args
        let expectedSecondsAfterHour = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes, // Pass required arg
            selectedHour: newHour,
            selectedMinute: initialMinute,
            now: actionDate,
            calendar: calendar // Pass calendar
        )
        await store.send(.hourSelected(newHour)) { state in
            state.selectedHour = newHour
            // Pass all required args for recalculation check
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: state.selectedMinutes, // Pass required arg
                selectedHour: newHour,
                selectedMinute: initialMinute,
                now: actionDate,
                calendar: calendar // Pass calendar
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = recalculatedSeconds / 60
            XCTAssertEqual(recalculatedSeconds, expectedSecondsAfterHour)
        }

        // 新しい分を選択
        // Pass all required args
        let expectedSecondsAfterMinute = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes, // Pass required arg
            selectedHour: newHour,
            selectedMinute: newMinute,
            now: actionDate,
            calendar: calendar // Pass calendar
        )
        await store.send(.minuteSelected(newMinute)) { state in
            state.selectedMinute = newMinute
            // Pass all required args for recalculation check
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: state.selectedMinutes, // Pass required arg
                selectedHour: newHour,
                selectedMinute: newMinute,
                now: actionDate,
                calendar: calendar // Pass calendar
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = recalculatedSeconds / 60
            XCTAssertEqual(recalculatedSeconds, expectedSecondsAfterMinute)
        }
        await store.finish()
    }
}
