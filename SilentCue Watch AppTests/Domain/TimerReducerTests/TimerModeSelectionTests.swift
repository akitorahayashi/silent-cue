import ComposableArchitecture
import SCMock
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class TimerModeSelectionTests: XCTestCase {
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

    func testTimerModeSelection() async {
        let fixedInitialDate = Date(timeIntervalSince1970: 1000)
        let fixedActionDate = Date(timeIntervalSince1970: 2000)
        let fixedCalendar = calendar!

        let initialState = TimerReducerTestUtil.createInitialState(
            now: fixedInitialDate,
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
                // Dependency for the actions below
                dependencies.date = .constant(fixedActionDate)
            }
        )

        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: fixedInitialDate,
            calendar: fixedCalendar
        )

        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 60)

        let expectedHour = fixedCalendar.component(.hour, from: fixedActionDate)
        let expectedMinute = fixedCalendar.component(.minute, from: fixedActionDate)
        let expectedAtTimeSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: expectedHour,
            selectedMinute: expectedMinute,
            now: fixedActionDate,
            calendar: fixedCalendar
        )

        await store.send(TimerReducer.Action.timerModeSelected(.time)) {
            $0.timerMode = .time
            $0.selectedHour = expectedHour
            $0.selectedMinute = expectedMinute
            $0.totalSeconds = expectedAtTimeSeconds
            $0.currentRemainingSeconds = expectedAtTimeSeconds
            $0.timerDurationMinutes = max(1, (expectedAtTimeSeconds + 59) / 60)
        }

        let currentState = store.state
        let expectedAfterMinutesSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .minutes,
            selectedMinutes: currentState.selectedMinutes,
            selectedHour: currentState.selectedHour,
            selectedMinute: currentState.selectedMinute,
            now: fixedActionDate,
            calendar: fixedCalendar
        )

        await store.send(TimerReducer.Action.timerModeSelected(.minutes)) {
            $0.timerMode = .minutes
            $0.totalSeconds = expectedAfterMinutesSeconds
            $0.currentRemainingSeconds = expectedAfterMinutesSeconds
            $0.timerDurationMinutes = max(1, (expectedAfterMinutesSeconds + 59) / 60)
            XCTAssertEqual(expectedAfterMinutesSeconds, 60)
        }
        await store.finish()
    }

    func testMinutesSelected() async {
        let fixedInitialDate = Date(timeIntervalSince1970: 0)
        let fixedActionDate = Date(timeIntervalSince1970: 100)
        let initialMinutes = 1
        let newMinutes = 5
        let fixedCalendar = calendar!

        let initialState = TimerReducerTestUtil.createInitialState(
            now: fixedInitialDate,
            selectedMinutes: initialMinutes,
            timerMode: .minutes,
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
                // Dependency for the action below
                dependencies.date = .constant(fixedActionDate)
            }
        )

        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .minutes,
            selectedMinutes: initialMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: fixedInitialDate,
            calendar: fixedCalendar
        )

        XCTAssertEqual(store.state.selectedMinutes, initialMinutes)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 60)

        let expectedNewSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .minutes,
            selectedMinutes: newMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: fixedActionDate,
            calendar: fixedCalendar
        )
        XCTAssertEqual(expectedNewSeconds, 300)

        await store.send(.minutesSelected(newMinutes)) { state in
            state.selectedMinutes = newMinutes
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .minutes,
                selectedMinutes: newMinutes,
                selectedHour: state.selectedHour,
                selectedMinute: state.selectedMinute,
                now: fixedActionDate,
                calendar: fixedCalendar
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = max(1, (recalculatedSeconds + 59) / 60)
            XCTAssertEqual(recalculatedSeconds, expectedNewSeconds)
        }
        await store.finish()
    }

    func testHourMinuteSelected() async {
        let fixedCalendar = calendar!

        let components = DateComponents(year: 2023, month: 10, day: 27, hour: 9, minute: 0, second: 0)
        guard let fixedInitialDate = fixedCalendar.date(from: components) else {
            XCTFail("Failed to create fixed initial date using UTC calendar")
            return
        }

        let fixedActionDate = fixedInitialDate.addingTimeInterval(100)

        let initialHour = 9
        let initialMinute = 0
        let newHour = 10
        let newMinute = 30

        let initialState = TimerReducerTestUtil.createInitialState(
            now: fixedInitialDate,
            timerMode: .time,
            selectedHour: initialHour,
            selectedMinute: initialMinute,
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
                // Dependency for the actions below
                dependencies.date = .constant(fixedActionDate)
            }
        )

        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialHour,
            selectedMinute: initialMinute,
            now: fixedInitialDate,
            calendar: fixedCalendar
        )

        XCTAssertEqual(store.state.timerMode, .time)
        XCTAssertEqual(store.state.selectedHour, initialHour)
        XCTAssertEqual(store.state.selectedMinute, initialMinute)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)

        let expectedSecondsAfterHour = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: newHour,
            selectedMinute: initialMinute,
            now: fixedActionDate,
            calendar: fixedCalendar
        )
        await store.send(.hourSelected(newHour)) { state in
            state.selectedHour = newHour
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: state.selectedMinutes,
                selectedHour: newHour,
                selectedMinute: initialMinute,
                now: fixedActionDate,
                calendar: fixedCalendar
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = max(1, (recalculatedSeconds + 59) / 60)
            XCTAssertEqual(recalculatedSeconds, expectedSecondsAfterHour)
        }

        let expectedSecondsAfterMinute = TimeCalculation.calculateTotalSeconds(
            mode: .time,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: newHour,
            selectedMinute: newMinute,
            now: fixedActionDate,
            calendar: fixedCalendar
        )
        await store.send(.minuteSelected(newMinute)) { state in
            state.selectedMinute = newMinute
            let recalculatedSeconds = TimeCalculation.calculateTotalSeconds(
                mode: .time,
                selectedMinutes: state.selectedMinutes,
                selectedHour: newHour,
                selectedMinute: newMinute,
                now: fixedActionDate,
                calendar: fixedCalendar
            )
            state.totalSeconds = recalculatedSeconds
            state.currentRemainingSeconds = recalculatedSeconds
            state.timerDurationMinutes = max(1, (recalculatedSeconds + 59) / 60)
            XCTAssertEqual(recalculatedSeconds, expectedSecondsAfterMinute)
        }

        await store.finish()
    }
} 
