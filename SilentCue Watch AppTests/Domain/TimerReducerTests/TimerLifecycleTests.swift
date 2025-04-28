import ComposableArchitecture
import SCMock
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class TimerLifecycleTests: XCTestCase {
    var store: TestStore<TimerState, TimerAction>!
    var mockUserDefaults: MockUserDefaultsManager!
    var mockHaptics: MockHapticsService!
    var clock: TestClock<Duration>!
    var notificationService: MockNotificationService!
    var extendedRuntimeService: MockExtendedRuntimeService!
    var calendar: Calendar!

    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaultsManager()
        mockHaptics = MockHapticsService()
        clock = TestClock<Duration>()
        store = TestStore(
            initialState: TimerState(),
            reducer: { TimerReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = self.mockUserDefaults
                dependencies.hapticsService = self.mockHaptics
                dependencies.continuousClock = self.clock
            }
        )
        notificationService = MockNotificationService()
        extendedRuntimeService = MockExtendedRuntimeService()
        calendar = TimerReducerTestUtil.utcCalendar
    }

    override func tearDown() {
        store = nil
        mockUserDefaults = nil
        mockHaptics = nil
        clock = nil
        notificationService = nil
        extendedRuntimeService = nil
        calendar = nil
        super.tearDown()
    }

    // フォアグラウンドでのタイマー完了
    func testTimerFinishes_Foreground() async {
        let fixedNow = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 1
        let fixedCalendar = calendar! // Use instance variable

        let initialState = TimerReducerTestUtil.createInitialState(
            now: fixedNow,
            selectedMinutes: selectedMinutes,
            calendar: fixedCalendar
        )
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: fixedNow,
            calendar: fixedCalendar
        )

        let finishDate = fixedNow.addingTimeInterval(TimeInterval(expectedInitialSeconds))

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedNow)
            $0.continuousClock = self.clock // Use instance variable
            $0.notificationService = self.notificationService // Use instance variable
            $0.extendedRuntimeService = self.extendedRuntimeService // Use instance variable
            $0.calendar = fixedCalendar
        }

        // 1. タイマーを開始
        await store.send(TimerReducer.Action.startTimer) { /* 状態変更 */
            $0.isRunning = true
            $0.startDate = fixedNow
            $0.targetEndDate = fixedNow.addingTimeInterval(TimeInterval(expectedInitialSeconds))
            $0.totalSeconds = expectedInitialSeconds
            $0.timerDurationMinutes = expectedInitialSeconds / 60
            $0.currentRemainingSeconds = expectedInitialSeconds
        }

        // 2. クロックを終了直前まで進める
        await clock.advance(by: .seconds(expectedInitialSeconds - 1))
        for i in 1 ... (expectedInitialSeconds - 1) {
            await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, 1)

        // 3. クロックを終了時刻まで進める
        store.dependencies.date = DateGenerator.constant(finishDate)
        await clock.advance(by: .seconds(1))
        await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = 0 }
        await store.receive(TimerReducer.Action.timerFinished)
        await store.receive(TimerReducer.Action.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            $0.completionDate = finishDate
            $0.currentRemainingSeconds = 0
            let completedSeconds = Int(finishDate.timeIntervalSince($0.startDate!))
            $0.totalSeconds = completedSeconds
            $0.timerDurationMinutes = max(1, (completedSeconds + 59) / 60)
        }
        await store.finish()
    }

    // タイマー開始、ティック、キャンセルの一連の流れ
    func testStartTickAndCancelTimer() async {
        let fixedNow = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 2
        let fixedCalendar = calendar! // Use instance variable

        let initialState = TimerReducerTestUtil.createInitialState(
            now: fixedNow,
            selectedMinutes: selectedMinutes,
            calendar: fixedCalendar
        )
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: fixedNow,
            calendar: fixedCalendar
        )

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedNow)
            $0.continuousClock = self.clock // Use instance variable
            $0.notificationService = self.notificationService // Use instance variable
            $0.extendedRuntimeService = self.extendedRuntimeService // Use instance variable
            $0.calendar = fixedCalendar
        }

        XCTAssertFalse(store.state.isRunning)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 120)

        await store.send(TimerReducer.Action.startTimer) { /* 状態変更 */
            $0.isRunning = true
            $0.startDate = fixedNow
            $0.targetEndDate = fixedNow.addingTimeInterval(TimeInterval(expectedInitialSeconds))
            $0.totalSeconds = expectedInitialSeconds
            $0.timerDurationMinutes = expectedInitialSeconds / 60
            $0.currentRemainingSeconds = expectedInitialSeconds
        }

        await clock.advance(by: .seconds(1))
        await store.receive(TimerReducer.Action.tick) { /* 状態変更 */
            $0.currentRemainingSeconds = expectedInitialSeconds - 1
        }

        await clock.advance(by: .seconds(9))
        for i in 1 ... 9 {
            await store
                .receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - 1 - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, expectedInitialSeconds - 10)

        let cancelDate = fixedNow.addingTimeInterval(10)
        store.dependencies.date = DateGenerator.constant(cancelDate)
        let expectedCancelSeconds = TimeCalculation.calculateTotalSeconds(
            mode: store.state.timerMode,
            selectedMinutes: store.state.selectedMinutes,
            selectedHour: store.state.selectedHour,
            selectedMinute: store.state.selectedMinute,
            now: cancelDate,
            calendar: fixedCalendar
        )
        XCTAssertEqual(expectedCancelSeconds, 120)

        await store.send(TimerReducer.Action.cancelTimer) { /* 状態変更 */
            $0.isRunning = false
            $0.startDate = nil
            $0.targetEndDate = nil
            $0.completionDate = nil

            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: store.state.timerMode,
                selectedMinutes: $0.selectedMinutes,
                selectedHour: $0.selectedHour,
                selectedMinute: $0.selectedMinute,
                now: cancelDate,
                calendar: fixedCalendar
            )
            XCTAssertEqual(recalculatedSeconds, 120)
            $0.totalSeconds = recalculatedSeconds
            $0.timerDurationMinutes = max(1, (recalculatedSeconds + 59) / 60)
            $0.currentRemainingSeconds = recalculatedSeconds
        }

        await store.finish()
    }

    // .time モードでのフォアグラウンド完了
    func testTimerFinishes_AtTime_Foreground() async throws {
        let fixedCalendar = calendar! // Use instance variable

        var components = DateComponents(year: 2023, month: 10, day: 26, hour: 10, minute: 0, second: 0)
        guard let fixedStartDate = fixedCalendar.date(from: components) else {
            XCTFail("Failed to create fixed start date using UTC calendar")
            return
        }

        let targetHour = 10
        let targetMinute = 1

        let expectedTargetEndDate = TimerReducerTestUtil.calculateExpectedTargetEndDateAtTime(
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: fixedStartDate,
            calendar: fixedCalendar
        )
        guard let finishDate = expectedTargetEndDate else {
            XCTFail("Failed to calculate expected target end date")
            return
        }

        let initialState = TimerReducerTestUtil.createInitialState(
            now: fixedStartDate,
            timerMode: .time,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            calendar: fixedCalendar
        )
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: fixedStartDate,
            calendar: fixedCalendar
        )
        XCTAssertEqual(expectedInitialSeconds, 60)

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedStartDate)
            $0.continuousClock = self.clock // Use instance variable
            $0.notificationService = self.notificationService // Use instance variable
            $0.extendedRuntimeService = self.extendedRuntimeService // Use instance variable
            $0.calendar = fixedCalendar
        }

        // 1. タイマーを開始
        await store.send(TimerReducer.Action.startTimer) { state in
            state.isRunning = true
            state.startDate = fixedStartDate
            state.targetEndDate = finishDate

            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: initialState.selectedMinutes,
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: fixedStartDate,
                calendar: fixedCalendar
            )
            state.totalSeconds = secondsOnStart
            state.timerDurationMinutes = max(1, (secondsOnStart + 59) / 60)
            state.currentRemainingSeconds = secondsOnStart
        }

        // 2. クロックを終了直前まで進める
        let duration = finishDate.timeIntervalSince(fixedStartDate)
        XCTAssertEqual(duration, 60)
        await clock.advance(by: .seconds(duration - 1))
        for i in 1 ... Int(duration - 1) {
            await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, 1)

        // 3. クロックを終了時刻まで進める
        store.dependencies.date = DateGenerator.constant(finishDate)
        await clock.advance(by: .seconds(1))
        await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = 0 }
        await store.receive(TimerReducer.Action.timerFinished)
        await store.receive(TimerReducer.Action.internal(.finalizeTimerCompletion(completionDate: finishDate))) { state in
            state.isRunning = false
            state.completionDate = finishDate
            state.currentRemainingSeconds = 0
            let completedSeconds = Int(finishDate.timeIntervalSince(state.startDate!))
            state.totalSeconds = completedSeconds
            state.timerDurationMinutes = max(1, (completedSeconds + 59) / 60)
        }
        await store.finish()
    }

    // タイマー開始とキャンセルの単純なテスト (.time モード)
    func testStartAndCancelTimer_AtTime() async {
        let fixedCalendar = calendar! // Use instance variable

        var components = DateComponents(year: 2023, month: 1, day: 1, hour: 14, minute: 0, second: 0)
        guard let fixedStartDate = fixedCalendar.date(from: components) else {
            XCTFail("Failed to create fixed start date using UTC calendar")
            return
        }

        let targetHour = 14
        let targetMinute = 5

        let expectedTargetEndDate = TimerReducerTestUtil.calculateExpectedTargetEndDateAtTime(
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: fixedStartDate,
            calendar: fixedCalendar
        )
        guard let finishDate = expectedTargetEndDate else {
            XCTFail("Failed to calculate expected target end date")
            return
        }

        let initialState = TimerReducerTestUtil.createInitialState(
            now: fixedStartDate,
            timerMode: .time,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            calendar: fixedCalendar
        )
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: fixedStartDate,
            calendar: fixedCalendar
        )
        XCTAssertEqual(expectedInitialSeconds, 300)

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(fixedStartDate)
            $0.continuousClock = self.clock // Use instance variable
            $0.notificationService = self.notificationService // Use instance variable
            $0.extendedRuntimeService = self.extendedRuntimeService // Use instance variable
            $0.calendar = fixedCalendar
        }

        await store.send(TimerReducer.Action.startTimer) { state in
            state.isRunning = true
            state.startDate = fixedStartDate
            state.targetEndDate = finishDate

            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: state.selectedMinutes,
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: fixedStartDate,
                calendar: fixedCalendar
            )
            state.totalSeconds = secondsOnStart
            state.timerDurationMinutes = max(1, (secondsOnStart + 59) / 60)
            state.currentRemainingSeconds = secondsOnStart
        }

        await clock.advance(by: .seconds(10))
        for i in 1 ... 10 {
            await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, 290)

        let cancelDate = fixedStartDate.addingTimeInterval(10)
        store.dependencies.date = DateGenerator.constant(cancelDate)

        await store.send(TimerReducer.Action.cancelTimer) { state in
            state.isRunning = false
            state.startDate = nil
            state.targetEndDate = nil
            state.completionDate = nil

            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: state.selectedMinutes,
                selectedHour: state.selectedHour,
                selectedMinute: state.selectedMinute,
                now: cancelDate,
                calendar: fixedCalendar
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = max(1, (recalculatedSeconds + 59) / 60)
        }

        await store.finish()
    }
}
