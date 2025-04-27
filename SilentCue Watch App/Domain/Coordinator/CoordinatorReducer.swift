import CasePaths
import ComposableArchitecture
import SCProtocol // For services
import SCShared // For UserDefaultsKeys
import SwiftUI
import UserNotifications

/// アプリ全体のルートReducer
struct CoordinatorReducer: Reducer {
    typealias State = CoordinatorState
    typealias Action = CoordinatorAction

    // 依存関係
    @Dependency(\.userDefaultsService) var userDefaultsService
    @Dependency(\.notificationService) var notificationService

    var body: some ReducerOf<Self> {
        Scope(state: \.timer, action: \.timer) {
            TimerReducer()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsReducer()
        }
        Scope(state: \.haptics, action: \.haptics) {
            HapticsReducer()
        }

        Reduce { state, action in
            @Dependency(\.extendedRuntimeService) var extendedRuntimeService

            switch action {
                case .onAppear:
                    return .send(.checkFirstLaunch)

                case let .scenePhaseChanged(newPhase):
                    print("Scene Phase Changed: \(newPhase)")
                    return .none

                case let .pathChanged(newPath):
                    state.path = newPath
                    return .none

                case let .pushScreen(destination):
                    state.path.append(destination)
                    return .none

                case .popScreen:
                    let effect = state.haptics.isActive ? Effect<CoordinatorAction>.send(.haptics(.stopHaptic)) : Effect
                        .none
                    if !state.path.isEmpty {
                        state.path.removeLast()
                    }
                    return effect

                case let .settings(.settingsLoaded(hapticType)):
                    return .send(.haptics(.updateHapticSettings(
                        type: hapticType
                    )))

                case .settings(.selectHapticType):
                    return .send(.haptics(.updateHapticSettings(
                        type: state.settings.selectedHapticType
                    )))

                case .timer(.cancelTimer):
                    state.path.removeLast()
                    return .send(.haptics(.stopHaptic))

                case .timer(.dismissCompletionView):
                    state.path.removeAll()
                    return .send(.haptics(.stopHaptic))

                case let .timer(timerAction):
                    if case .internal(.finalizeTimerCompletion) = timerAction {
                        return .merge(
                            .send(.haptics(.startHaptic(state.settings.selectedHapticType))),
                            .send(.pushScreen(.completion))
                        )
                    }
                    return .none

                case .settings, .haptics:
                    return .none

                case .checkFirstLaunch:
                    let isFirst = userDefaultsService.object(forKey: .isFirstLaunch) as? Bool ?? true
                    if isFirst {
                        return .run { send in
                            let status = await notificationService.getAuthorizationStatus()
                            await send(.notificationStatusChecked(status))
                        }
                    } else {
                        return .send(.settings(.loadSettings))
                    }

                case let .notificationStatusChecked(status):
                    if status == .notDetermined {
                        state.shouldShowNotificationAlert = true
                        return .none
                    } else {
                        return .send(.markAsLaunched)
                    }

                case let .setNotificationAlert(isPresented):
                    state.shouldShowNotificationAlert = isPresented
                    return .none

                case .notificationAlertPermitTapped:
                    state.shouldShowNotificationAlert = false
                    return .merge(
                        .run { _ in
                            _ = try? await notificationService.requestAuthorization()
                        },
                        .send(.markAsLaunched)
                    )

                case .notificationAlertDenyTapped:
                    state.shouldShowNotificationAlert = false
                    return .send(.markAsLaunched)

                case .markAsLaunched:
                    return .merge(
                        .run { _ in
                            userDefaultsService.set(false, forKey: .isFirstLaunch)
                        },
                        .send(.settings(.loadSettings))
                    )

                case .internalAction:
                    return .none
            }
        }
    }
}
