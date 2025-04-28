import ComposableArchitecture
import SCMock
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class TimerBackgroundHandlingTests: XCTestCase {
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
        notificationService = MockNotificationService()
        extendedRuntimeService = MockExtendedRuntimeService()
        calendar = TimerReducerTestUtil.utcCalendar

        store = TestStore(
            initialState: TimerState(),
            reducer: { TimerReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = self.mockUserDefaults
                dependencies.hapticsService = self.mockHaptics
                dependencies.continuousClock = self.clock
                dependencies.notificationService = self.notificationService
                dependencies.extendedRuntimeService = self.extendedRuntimeService
            }
        )
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

    // バックグラウンドでのタイマー完了シーケンス (.minutes モード)
    func testTimerFinishes_Background() async {
        let fixedNow = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 1 // 60 秒
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
        await store.send(TimerReducer.Action.startTimer) {
            $0.isRunning = true
            $0.startDate = fixedNow
            $0.targetEndDate = fixedNow.addingTimeInterval(TimeInterval(expectedInitialSeconds))
            $0.totalSeconds = expectedInitialSeconds
            $0.timerDurationMinutes = expectedInitialSeconds / 60
            $0.currentRemainingSeconds = expectedInitialSeconds
        }

        // 2. 時間経過をシミュレート (バックグラウンド想定のためティック受信なし)
        store.dependencies.date = DateGenerator.constant(finishDate)

        // 3. バックグラウンド完了イベントをシミュレート
        extendedRuntimeService.triggerCompletion()
        await store.receive(TimerReducer.Action.internal(.backgroundTimerDidComplete))
        await store.receive(TimerReducer.Action.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            $0.completionDate = finishDate
        }

        // クロックを進めてタイマーエフェクトを完了させる
        await clock.advance()

        // エフェクトの完了を確認
        await store.finish()
    }

    // .time モードでのバックグラウンド完了
    func testTimerFinishes_AtTime_Background() async throws {
        let fixedCalendar = calendar! // Use instance variable

        let startComponents = DateComponents(year: 2023, month: 10, day: 26, hour: 12, minute: 30, second: 0)
        guard let fixedStartDate = fixedCalendar.date(from: startComponents) else {
            XCTFail("Failed to create fixed start date using UTC calendar")
            return
        }

        let targetHour = 12
        let targetMinute = 31

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

        guard let finishDate = TimerReducerTestUtil.calculateExpectedTargetEndDateAtTime(
            selectedHour: targetHour,
            selectedMinute: targetMinute,
            now: fixedStartDate,
            calendar: fixedCalendar
        ) else {
            XCTFail("Failed to calculate expected finish date")
            return
        }

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
        await store.send(.startTimer) {
            $0.isRunning = true
            $0.startDate = fixedStartDate

            let calculatedTargetEndDate = TimerReducerTestUtil.calculateExpectedTargetEndDateAtTime(
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: fixedStartDate,
                calendar: fixedCalendar
            )
            let unwrappedTargetEndDate = try XCTUnwrap(
                calculatedTargetEndDate,
                "Target end date should not be nil on start"
            )
            XCTAssertEqual(unwrappedTargetEndDate, finishDate)
            $0.targetEndDate = calculatedTargetEndDate

            let secondsOnStart = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: $0.selectedMinutes,
                selectedHour: targetHour,
                selectedMinute: targetMinute,
                now: fixedStartDate,
                calendar: fixedCalendar
            )
            XCTAssertEqual(secondsOnStart, 60)
            $0.totalSeconds = secondsOnStart
            $0.timerDurationMinutes = secondsOnStart / 60
            $0.currentRemainingSeconds = secondsOnStart
        }

        // 2. 時間経過とバックグラウンド完了をシミュレート
        store.dependencies.date = DateGenerator.constant(finishDate)

        // 3. バックグラウンド完了イベントをトリガー
        extendedRuntimeService.triggerCompletion()
        await store.receive(.internal(.backgroundTimerDidComplete))
        await store.receive(.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            $0.completionDate = finishDate
        }

        // クロックを進めてタイマーエフェクトを完了させる
        await clock.advance()

        // エフェクトの完了を確認
        await store.finish()
    }
} 