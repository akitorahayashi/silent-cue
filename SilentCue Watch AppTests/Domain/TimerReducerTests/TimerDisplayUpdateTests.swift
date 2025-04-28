import ComposableArchitecture
import SCMock
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class TimerDisplayUpdateTests: XCTestCase {
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
    }

    override func tearDown() {
        mockUserDefaults = nil
        mockHaptics = nil
        clock = nil
        notificationService = nil
        extendedRuntimeService = nil
        calendar = nil
        super.tearDown()
    }

    // 完了画面の dismiss アクション
    func testDismissCompletionView() async {
        let fixedNow = Date(timeIntervalSince1970: 0)
        let completionDate = fixedNow.addingTimeInterval(60)
        let fixedCalendar = calendar!

        let initialState = TimerReducerTestUtil.createInitialState(
            now: fixedNow,
            isRunning: false,
            completionDate: completionDate,
            calendar: fixedCalendar
        )

        let store = TestStore(
            initialState: initialState,
            reducer: { TimerReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = self.mockUserDefaults
                dependencies.hapticsService = self.mockHaptics
                dependencies.continuousClock = self.clock
                dependencies.notificationService = self.notificationService
                dependencies.extendedRuntimeService = self.extendedRuntimeService
                dependencies.calendar = self.calendar
            }
        )

        await store.send(.dismissCompletionView) {
            $0.completionDate = nil
        }
    }

    // バックグラウンド復帰時の表示更新 (.updateTimerDisplay)
    func testUpdateTimerDisplay_WhenRunning() async {
        let fixedStartDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 5
        let expectedInitialSeconds = 300
        let fixedCalendar = calendar!

        let runningState = TimerReducerTestUtil.createInitialState(
            now: fixedStartDate,
            selectedMinutes: selectedMinutes,
            isRunning: true,
            startDate: fixedStartDate,
            targetEndDate: fixedStartDate.addingTimeInterval(TimeInterval(expectedInitialSeconds)),
            calendar: fixedCalendar
        )

        let store = TestStore(
            initialState: runningState,
            reducer: { TimerReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = self.mockUserDefaults
                dependencies.hapticsService = self.mockHaptics
                dependencies.continuousClock = self.clock
                dependencies.notificationService = self.notificationService
                dependencies.extendedRuntimeService = self.extendedRuntimeService
                dependencies.calendar = self.calendar
                dependencies.date = .constant(fixedStartDate.addingTimeInterval(60))
            }
        )

        await store.send(.updateTimerDisplay) { state in
            state.currentRemainingSeconds = 240 // 300 - 60
        }
        await store.finish()
    }

    // タイマー停止中の表示更新は何もしない
    func testUpdateTimerDisplay_WhenNotRunning() async {
        let fixedNow = Date(timeIntervalSince1970: 0)
        let fixedCalendar = calendar!
        let initialState = TimerReducerTestUtil.createInitialState(
            now: fixedNow,
            isRunning: false,
            calendar: fixedCalendar
        )

        let store = TestStore(
            initialState: initialState,
            reducer: { TimerReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = self.mockUserDefaults
                dependencies.hapticsService = self.mockHaptics
                dependencies.continuousClock = self.clock
                dependencies.notificationService = self.notificationService
                dependencies.extendedRuntimeService = self.extendedRuntimeService
                dependencies.calendar = self.calendar
                dependencies.date = .constant(fixedNow.addingTimeInterval(60))
            }
        )

        await store.send(.updateTimerDisplay)
        await store.finish()
    }

    // 表示更新時にタイマーが完了するケース
    func testUpdateTimerDisplay_FinishesTimer() async {
        let fixedStartDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 1
        let expectedInitialSeconds = 60
        let finishDate = fixedStartDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))
        let fixedCalendar = calendar!

        let runningState = TimerReducerTestUtil.createInitialState(
            now: fixedStartDate,
            selectedMinutes: selectedMinutes,
            isRunning: true,
            startDate: fixedStartDate,
            targetEndDate: finishDate,
            calendar: fixedCalendar
        )

        let timeAtUpdate = finishDate

        let store = TestStore(
            initialState: runningState,
            reducer: { TimerReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = self.mockUserDefaults
                dependencies.hapticsService = self.mockHaptics
                dependencies.continuousClock = self.clock
                dependencies.notificationService = self.notificationService
                dependencies.extendedRuntimeService = self.extendedRuntimeService
                dependencies.calendar = self.calendar
                dependencies.date = .constant(timeAtUpdate)
            }
        )

        await store.send(.updateTimerDisplay) { state in
            state.currentRemainingSeconds = 0
        }
        await store.receive(.timerFinished)

        store.dependencies.date = .constant(timeAtUpdate.addingTimeInterval(0))
        await store.receive(.internal(.finalizeTimerCompletion(completionDate: timeAtUpdate))) {
            $0.isRunning = false
            $0.completionDate = timeAtUpdate
        }
        await store.finish()
    }
}
