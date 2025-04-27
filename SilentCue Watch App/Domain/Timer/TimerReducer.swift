import ComposableArchitecture
import Foundation
import UserNotifications

/// タイマー関連のすべての機能を管理するReducer
struct TimerReducer: Reducer {
    typealias State = TimerState
    typealias Action = TimerAction

    enum InternalAction {
        case backgroundTimerDidComplete
        case finalizeTimerCompletion(completionDate: Date)
    }

    private enum CancelID { case timer, background }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.notificationService) var notificationService
    @Dependency(\.extendedRuntimeService) var extendedRuntimeService
    @Dependency(\.date) var date

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case let .timerModeSelected(mode):
                    return handleTimerModeSelected(&state, mode: mode)

                case let .minutesSelected(minutes):
                    return handleMinutesSelected(&state, minutes: minutes)

                case let .hourSelected(hour):
                    return handleHourSelected(&state, hour: hour)

                case let .minuteSelected(minute):
                    return handleMinuteSelected(&state, minute: minute)

                case .startTimer:
                    return handleStartTimer(&state)

                case .cancelTimer:
                    return handleCancelTimer(&state)

                case .tick:
                    return handleTick(&state)

                case .timerFinished:
                    return handleTimerFinished(&state)

                case .dismissCompletionView:
                    return handleDismissCompletionView(&state)

                case .updateTimerDisplay:
                    return handleUpdateTimerDisplay(&state)

                case let .internal(internalAction):
                    switch internalAction {
                        case .backgroundTimerDidComplete:
                            return handleBackgroundTimerDidComplete(&state)
                        case let .finalizeTimerCompletion(completionDate):
                            return handleFinalizeTimerCompletion(&state, completionDate: completionDate)
                    }
            }
        }
    }

    private func handleTimerModeSelected(_ state: inout State, mode: TimerMode) -> Effect<Action> {
        state.timerMode = mode
        if mode == .time {
            let now = date()
            let calendar = Calendar.current
            state.selectedHour = calendar.component(.hour, from: now)
            state.selectedMinute = calendar.component(.minute, from: now)
        }
        recalculateTimerProperties(&state)
        return .none
    }

    private func handleMinutesSelected(_ state: inout State, minutes: Int) -> Effect<Action> {
        state.selectedMinutes = minutes
        recalculateTimerProperties(&state)
        return .none
    }

    private func handleHourSelected(_ state: inout State, hour: Int) -> Effect<Action> {
        state.selectedHour = hour
        recalculateTimerProperties(&state)
        return .none
    }

    private func handleMinuteSelected(_ state: inout State, minute: Int) -> Effect<Action> {
        state.selectedMinute = minute
        recalculateTimerProperties(&state)
        return .none
    }

    private func handleStartTimer(_ state: inout State) -> Effect<Action> {
        guard !state.isRunning else { return .none }
        recalculateTimerProperties(&state)

        let now = date()
        state.startDate = now
        state.isRunning = true
        state.completionDate = nil

        let targetEndDate: Date?
        if state.timerMode == .minutes {
            targetEndDate = now.addingTimeInterval(Double(state.totalSeconds))
        } else {
            targetEndDate = TimeCalculation.calculateTargetEndDate(
                selectedHour: state.selectedHour,
                selectedMinute: state.selectedMinute,
                now: now,
                calendar: Calendar.current
            )
        }

        state.targetEndDate = targetEndDate

        let totalSeconds = state.totalSeconds
        let unwrappedTargetEndDateForEffect = targetEndDate ?? now.addingTimeInterval(Double(totalSeconds))

        let tickerEffect = Effect<Action>.run { send in
            for await _ in clock.timer(interval: .seconds(1)) {
                await send(.tick)
            }
        }
        .cancellable(id: CancelID.timer)

        let backgroundEffect = Effect<Action>.run { [unwrappedTargetEndDateForEffect, totalSeconds, timerDurationMinutes = state.timerDurationMinutes] send in
            extendedRuntimeService.startSession(
                duration: TimeInterval(totalSeconds + 10),
                targetEndTime: unwrappedTargetEndDateForEffect
            )
            let content = UNMutableNotificationContent()
            content.title = "タイマー完了"
            content.body = "\(timerDurationMinutes)分のタイマーが完了しました"
            content.sound = .default

            let triggerComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: unwrappedTargetEndDateForEffect
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let identifier = "TIMER_COMPLETED_NOTIFICATION"

            await Task {
                do {
                    try await notificationService.add(identifier: identifier, content: content, trigger: trigger)
                } catch {
                    print("通知スケジュールエラー: \(error)")
                }
            }.value
            for await _ in extendedRuntimeService.completionEvents {
                await send(.internal(.backgroundTimerDidComplete))
            }
        }
        .cancellable(id: CancelID.background)

        return .merge(tickerEffect, backgroundEffect)
    }

    private func handleCancelTimer(_ state: inout State) -> Effect<Action> {
        let wasRunning = state.isRunning
        state.isRunning = false
        state.startDate = nil
        state.targetEndDate = nil
        state.completionDate = nil
        recalculateTimerProperties(&state)

        guard wasRunning else { return .none }

        extendedRuntimeService.stopSession()
        let identifier = "TIMER_COMPLETED_NOTIFICATION"
        notificationService.removePendingNotificationRequests(withIdentifiers: [identifier])

        return .merge(
            .cancel(id: CancelID.timer),
            .cancel(id: CancelID.background)
        )
    }

    private func handleTick(_ state: inout State) -> Effect<Action> {
        guard state.isRunning else {
            return .merge(.cancel(id: CancelID.timer), .cancel(id: CancelID.background))
        }
        state.currentRemainingSeconds = max(0, state.currentRemainingSeconds - 1)
        if state.currentRemainingSeconds <= 0 {
            return .send(.timerFinished)
        }
        return .none
    }

    private func handleTimerFinished(_: inout State) -> Effect<Action> {
        let identifier = "TIMER_COMPLETED_NOTIFICATION"
        notificationService.removePendingNotificationRequests(withIdentifiers: [identifier])

        return .concatenate(
            .cancel(id: CancelID.background),
            .send(.internal(.finalizeTimerCompletion(completionDate: date())))
        )
    }

    private func handleUpdateTimerDisplay(_ state: inout State) -> Effect<Action> {
        if !state.isRunning { return .none }

        if let targetEnd = state.targetEndDate {
            let now = date()
            state.currentRemainingSeconds = max(0, Int(ceil(targetEnd.timeIntervalSince(now))))
        } else {
            state.currentRemainingSeconds = 0
        }

        if state.currentRemainingSeconds <= 0 {
            return .send(.timerFinished)
        }
        return .none
    }

    private func handleBackgroundTimerDidComplete(_: inout State) -> Effect<Action> {
        .concatenate(
            .cancel(id: CancelID.timer),
            .send(.internal(.finalizeTimerCompletion(completionDate: date())))
        )
    }

    private func handleFinalizeTimerCompletion(_ state: inout State, completionDate: Date) -> Effect<Action> {
        guard state.isRunning else { return .none }
        state.isRunning = false
        state.completionDate = completionDate

        extendedRuntimeService.stopSession()
        return .merge(
            .cancel(id: CancelID.timer),
            .cancel(id: CancelID.background)
        )
    }

    private func handleDismissCompletionView(_ state: inout State) -> Effect<Action> {
        state.completionDate = nil
        return .merge(
            .cancel(id: CancelID.timer),
            .cancel(id: CancelID.background)
        )
    }

    private func recalculateTimerProperties(_ state: inout State) {
        let now = date()
        state.totalSeconds = TimeCalculation.calculateTotalSeconds(
            mode: state.timerMode,
            selectedMinutes: state.selectedMinutes,
            selectedHour: state.selectedHour,
            selectedMinute: state.selectedMinute,
            now: now
        )
        if !state.isRunning {
            state.currentRemainingSeconds = state.totalSeconds
        }
        state.timerDurationMinutes = state.totalSeconds / 60
    }
}
