import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class TimerReducerModeTests: XCTestCase {
    // --- 分割されたテスト ---

    // テスト: 初期状態 (.afterMinutes) の秒数計算が正しいか
    func testInitialStateSeconds() async {
        let initialDate = Date(timeIntervalSince1970: 1000)
        let calendar = Calendar.current
        let initialState = TimerReducer.State(testWithNow: initialDate, selectedMinutes: 1)

        // 期待される初期秒数を計算
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .afterMinutes,
            selectedMinutes: 1,
            selectedHour: calendar.component(.hour, from: initialDate),
            selectedMinute: calendar.component(.minute, from: initialDate),
            now: initialDate,
            calendar: calendar
        )
        XCTAssertEqual(expectedInitialSeconds, 60)

        // TestStore をここで初期化
        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            // このテストでは Date 依存関係は重要ではないが、一応設定
            $0.date = DateGenerator.constant(initialDate)
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // 状態検証
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(store.state.currentRemainingSeconds, expectedInitialSeconds)

        // アクションは送らないので finish は不要
        // await store.finish()
    }

    // テスト: .atTime モードに切り替えた際の秒数計算と状態変化が正しいか
    func testSelectAtTimeMode() async {
        let initialDate = Date(timeIntervalSince1970: 1000)
        let actionDate = Date(timeIntervalSince1970: 2000)
        let calendar = Calendar.current
        let initialState = TimerReducer.State(testWithNow: initialDate, selectedMinutes: 1)

        // TestStore をここで初期化
        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(actionDate)
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        let expectedHour = calendar.component(.hour, from: actionDate)
        let expectedMinute = calendar.component(.minute, from: actionDate)
        let expectedAtTimeSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .atTime,
            selectedMinutes: initialState.selectedMinutes, // 使われない
            selectedHour: expectedHour,
            selectedMinute: expectedMinute,
            now: actionDate,
            calendar: calendar
        )

        await store.send(.timerModeSelected(.atTime)) {
            $0.timerMode = .atTime
            $0.selectedHour = expectedHour
            $0.selectedMinute = expectedMinute
            $0.totalSeconds = expectedAtTimeSeconds
            $0.currentRemainingSeconds = expectedAtTimeSeconds
            $0.timerDurationMinutes = expectedAtTimeSeconds / 60
        }

        await store.finish() // エフェクト完了待ち
    }

    // テスト: .atTime モードから .afterMinutes モードに戻した際の秒数計算と状態変化が正しいか
    func testSelectAfterMinutesModeAgain() async {
        let initialDate = Date(timeIntervalSince1970: 1000)
        let actionDate = Date(timeIntervalSince1970: 2000)
        let calendar = Calendar.current
        // .atTime に設定された状態から開始する
        let atTimeHour = calendar.component(.hour, from: actionDate)
        let atTimeMinute = calendar.component(.minute, from: actionDate)
        var initialState = TimerReducer.State(testWithNow: initialDate, selectedMinutes: 5)
        initialState.timerMode = .atTime
        initialState.selectedHour = atTimeHour
        initialState.selectedMinute = atTimeMinute
        initialState.totalSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .atTime, selectedMinutes: 5, selectedHour: atTimeHour, selectedMinute: atTimeMinute, now: actionDate,
            calendar: calendar
        )
        initialState.currentRemainingSeconds = initialState.totalSeconds
        initialState.timerDurationMinutes = initialState.totalSeconds / 60

        // TestStore をここで初期化
        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(actionDate)
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // .afterMinutes に戻すときの期待値を計算 (selectedMinutes=5 で計算)
        let expectedAfterMinutesSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .afterMinutes,
            selectedMinutes: 5,
            selectedHour: atTimeHour,
            selectedMinute: atTimeMinute,
            now: actionDate,
            calendar: calendar
        )
        XCTAssertEqual(expectedAfterMinutesSeconds, 300)

        await store.send(.timerModeSelected(.afterMinutes)) {
            $0.timerMode = .afterMinutes
            $0.totalSeconds = expectedAfterMinutesSeconds
            $0.currentRemainingSeconds = expectedAfterMinutesSeconds
            $0.timerDurationMinutes = expectedAfterMinutesSeconds / 60
        }

        await store.finish() // エフェクト完了待ち
    }
}
