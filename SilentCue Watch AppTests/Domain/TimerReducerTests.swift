@testable import SilentCue_Watch_App
import ComposableArchitecture
import XCTest

@MainActor
final class TimerReducerTests: XCTestCase {
    // No longer need testCalendar property

    // --- REMOVED Default Test Dependencies for Calculator/Managers --- 

    // Helper to create initial state (simplified)
    private func createInitialState(
        now: Date,
        selectedMinutes: Int = 1,
        timerMode: TimerMode = .afterMinutes,
        isRunning: Bool = false,
        startDate: Date? = nil,
        targetEndDate: Date? = nil,
        completionDate: Date? = nil
    ) -> TimerReducer.State {
        TimerReducer.State(
            timerMode: timerMode,
            selectedMinutes: selectedMinutes,
            now: now,
            isRunning: isRunning,
            startDate: startDate,
            targetEndDate: targetEndDate,
            completionDate: completionDate
        )
    }

    // --- Tests --- 

    func testTimerModeSelection() async {
        let initialDate = Date(timeIntervalSince1970: 1000)
        let actionDate = Date(timeIntervalSince1970: 2000)
        let calendar = Calendar.current // Use Calendar.current for consistency

        // Create initial state
        let initialState = createInitialState(now: initialDate)

        // Calculate expected initial total seconds using the UTILITY function
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: initialDate,
            calendar: calendar // Pass consistent calendar
        )

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(actionDate)
            // Inject Mocks from TestSupport
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // Initial state assertion
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 60)

        // Select .atTime
        let expectedHour = calendar.component(.hour, from: actionDate)
        let expectedMinute = calendar.component(.minute, from: actionDate)
        // Calculate expected total seconds using the UTILITY function
        let expectedAtTimeSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .atTime,
            selectedMinutes: initialState.selectedMinutes, // This value doesn't matter for .atTime
            selectedHour: expectedHour,
            selectedMinute: expectedMinute,
            now: actionDate,
            calendar: calendar
        )

        await store.send(TimerReducer.Action.timerModeSelected(.atTime)) { /* state changes */
            $0.timerMode = .atTime
            $0.selectedHour = expectedHour
            $0.selectedMinute = expectedMinute
            // totalSeconds/currentRemainingSeconds/duration calculated by reducer calling TimeCalculation
            $0.totalSeconds = expectedAtTimeSeconds
            $0.currentRemainingSeconds = expectedAtTimeSeconds
            $0.timerDurationMinutes = expectedAtTimeSeconds / 60
        }

        // Select .afterMinutes again
        // Calculate expected seconds using UTILITY function
        let currentState = store.state // Get state after .atTime switch
        let expectedAfterMinutesSeconds = TimeCalculation.calculateTotalSeconds(
            mode: .afterMinutes,
            selectedMinutes: currentState.selectedMinutes, // Should be 1
            selectedHour: currentState.selectedHour,
            selectedMinute: currentState.selectedMinute,
            now: actionDate,
            calendar: calendar
        )

        await store.send(TimerReducer.Action.timerModeSelected(.afterMinutes)) { /* state changes */
            $0.timerMode = .afterMinutes
            $0.totalSeconds = expectedAfterMinutesSeconds
            $0.currentRemainingSeconds = expectedAfterMinutesSeconds
            $0.timerDurationMinutes = expectedAfterMinutesSeconds / 60
            XCTAssertEqual(expectedAfterMinutesSeconds, 60)
        }
    }

    func testStartTickAndCancelTimer() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 2

        // Create initial state
        let initialState = createInitialState(now: startDate, selectedMinutes: selectedMinutes)
        // Calculate expected seconds using UTILITY function
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: startDate
        )

        let clock = TestClock()
        // Instantiate Mocks from TestSupport
        let notificationService = MockNotificationService()
        let extendedRuntimeService = MockExtendedRuntimeService()

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(startDate)
            $0.continuousClock = clock
            // Inject the mock instances
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
        }

        // Initial state check
        XCTAssertFalse(store.state.isRunning)
        XCTAssertEqual(store.state.totalSeconds, expectedInitialSeconds)
        XCTAssertEqual(expectedInitialSeconds, 120)

        // Start timer
        await store.send(TimerReducer.Action.startTimer) { /* state changes */
            $0.isRunning = true
            $0.startDate = startDate
            $0.targetEndDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))
            // recalculate happens, result is same
            $0.totalSeconds = expectedInitialSeconds
            $0.timerDurationMinutes = expectedInitialSeconds / 60
            $0.currentRemainingSeconds = expectedInitialSeconds
        }

        // Advance clock by 1 second
        await clock.advance(by: .seconds(1))
        await store.receive(TimerReducer.Action.tick) { /* state changes */
            $0.currentRemainingSeconds = expectedInitialSeconds - 1
        }

        // Advance clock further
        await clock.advance(by: .seconds(9))
        for i in 1...9 { 
            await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - 1 - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, expectedInitialSeconds - 10)

        // Cancel timer
        let cancelDate = startDate.addingTimeInterval(10)
        store.dependencies.date = DateGenerator.constant(cancelDate)
        // Recalculate expected seconds using UTILITY at cancel time
        let expectedCancelSeconds = TimeCalculation.calculateTotalSeconds(
            mode: store.state.timerMode, // Still .afterMinutes
            selectedMinutes: store.state.selectedMinutes, // Still 2
            selectedHour: store.state.selectedHour,
            selectedMinute: store.state.selectedMinute,
            now: cancelDate
        )
        XCTAssertEqual(expectedCancelSeconds, 120) // Should still calculate to 120

        await store.send(TimerReducer.Action.cancelTimer) { /* state changes */
            $0.isRunning = false
            $0.startDate = nil
            $0.targetEndDate = nil
            // Recalculate happens using cancelDate via utility
            $0.totalSeconds = expectedCancelSeconds
            $0.timerDurationMinutes = expectedCancelSeconds / 60
            $0.currentRemainingSeconds = expectedCancelSeconds // Reset
        }
        await store.finish()
    }

    func testTimerFinishes_Foreground() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 1

        let initialState = createInitialState(now: startDate, selectedMinutes: selectedMinutes)
        // Use Utility for initial seconds calculation
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: startDate
        )

        let clock = TestClock()
        // Instantiate Mocks from TestSupport
        let notificationService = MockNotificationService()
        let extendedRuntimeService = MockExtendedRuntimeService()
        let finishDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(startDate)
            $0.continuousClock = clock
            // Inject the mock instances
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
        }

        // 1. Start the timer
        await store.send(TimerReducer.Action.startTimer) { /* state changes */
            $0.isRunning = true
            $0.startDate = startDate
            $0.targetEndDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))
            // Recalculate happens, result is same
            $0.totalSeconds = expectedInitialSeconds
            $0.timerDurationMinutes = expectedInitialSeconds / 60
            $0.currentRemainingSeconds = expectedInitialSeconds
        }

        // 2. Advance clock almost to the end
        await clock.advance(by: .seconds(expectedInitialSeconds - 1))
        for i in 1...(expectedInitialSeconds - 1) { 
            await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = expectedInitialSeconds - i }
        }
        XCTAssertEqual(store.state.currentRemainingSeconds, 1)

        // 3. Advance clock to the finish time
        store.dependencies.date = DateGenerator.constant(finishDate) // Set date for finalize
        await clock.advance(by: .seconds(1))
        await store.receive(TimerReducer.Action.tick) { $0.currentRemainingSeconds = 0 }
        await store.receive(TimerReducer.Action.timerFinished)
        await store.receive(TimerReducer.Action.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            $0.completionDate = finishDate
        }
        await store.finish()
    }

    func testTimerFinishes_Background() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let selectedMinutes = 1 // 60 seconds

        let initialState = createInitialState(now: startDate, selectedMinutes: selectedMinutes)
        let expectedInitialSeconds = TimeCalculation.calculateTotalSeconds(
            mode: initialState.timerMode,
            selectedMinutes: initialState.selectedMinutes,
            selectedHour: initialState.selectedHour,
            selectedMinute: initialState.selectedMinute,
            now: startDate
        )

        let clock = TestClock()
        // Mock ExtendedRuntimeService needs a way to signal completion
        let extendedRuntimeService = MockExtendedRuntimeService() // Initialize without arguments
        let notificationService = MockNotificationService()
        let finishDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))

        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(startDate)
            $0.continuousClock = clock
            $0.notificationService = notificationService
            $0.extendedRuntimeService = extendedRuntimeService
        }

        // 1. Start the timer
        await store.send(TimerReducer.Action.startTimer) {
            $0.isRunning = true
            $0.startDate = startDate
            $0.targetEndDate = startDate.addingTimeInterval(TimeInterval(expectedInitialSeconds))
            $0.totalSeconds = expectedInitialSeconds
            $0.timerDurationMinutes = expectedInitialSeconds / 60
            $0.currentRemainingSeconds = expectedInitialSeconds
        }

        // 2. Simulate time passing (but no ticks received as app is in background)
        // We advance the clock conceptually, but don't expect .tick actions
        // The background completion event will be the trigger
        // Advance date dependency to simulate the time of completion
        store.dependencies.date = DateGenerator.constant(finishDate)

        // 3. Simulate background completion event
        extendedRuntimeService.triggerCompletion() // Use the mock's helper method
        await store.receive(TimerReducer.Action.internal(.backgroundTimerDidComplete)) // Reducer handles background event
        // Should cancel the tick timer and finalize
        await store.receive(TimerReducer.Action.internal(.finalizeTimerCompletion(completionDate: finishDate))) {
            $0.isRunning = false
            $0.completionDate = finishDate
        }

        // Ensure effects are finished/cancelled
        await store.finish()
    }

    func testDismissCompletionView() async {
        let startDate = Date(timeIntervalSince1970: 0)
        let completionDate = Date(timeIntervalSince1970: 60)

        // Start with a state where the timer has already completed
        let initialState = createInitialState(
            now: startDate,
            isRunning: false, // Not running
            completionDate: completionDate // Has completion date
        )

        // Dependencies aren't strictly needed for this action but setup for completeness
        let store = TestStore(initialState: initialState) {
            TimerReducer()
        } withDependencies: {
            $0.date = DateGenerator.constant(completionDate.addingTimeInterval(1)) // Time after completion
            $0.continuousClock = TestClock()
            $0.notificationService = MockNotificationService()
            $0.extendedRuntimeService = MockExtendedRuntimeService()
        }

        // Send dismiss action
        await store.send(TimerReducer.Action.dismissCompletionView) {
            $0.completionDate = nil // Expect completionDate to be cleared
        }

        // Ensure any potential lingering effects are cancelled (handled by reducer logic)
        await store.finish()
    }

    // TODO: Add tests for backgroundTimerDidComplete scenarios
}
