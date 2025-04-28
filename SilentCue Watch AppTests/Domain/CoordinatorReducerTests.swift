import ComposableArchitecture
import SCMock
import SCShared
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class CoordinatorReducerTests: XCTestCase {
    func testOnAppearLoadsSettings() async {
        let mockUserDefaults = MockUserDefaultsManager()

        mockUserDefaults.set(HapticType.standard.rawValue, forKey: UserDefaultsKeys.hapticType)
        mockUserDefaults.set(false, forKey: UserDefaultsKeys.isFirstLaunch)

        let store = TestStore(
            initialState: CoordinatorState(),
            reducer: { CoordinatorReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                dependencies.notificationService = MockNotificationService()
            }
        )

        await store.send(CoordinatorAction.onAppear)

        await store.receive(.settings(.loadSettings))

        await store.receive(CoordinatorAction.settings(.settingsLoaded(
            hapticType: HapticType.standard
        ))) { state in
            state.settings.selectedHapticType = HapticType.standard
            state.settings.isSettingsLoaded = true
        }

        await store.receive(.haptics(.updateHapticSettings(type: .standard)))

        await store.finish()
    }

    func testSettingsLoadedUpdatesHaptics() async {
        let store = TestStore(
            initialState: CoordinatorState(),
            reducer: { CoordinatorReducer() }
        )

        let loadedAction = SettingsAction.settingsLoaded(hapticType: HapticType.weak)
        await store.send(CoordinatorAction.settings(loadedAction)) { state in
            state.settings.selectedHapticType = HapticType.weak
            state.settings.isSettingsLoaded = true
        }

        await store.receive(CoordinatorAction.haptics(.updateHapticSettings(
            type: HapticType.weak
        ))) { state in
            state.haptics.hapticType = HapticType.weak
        }

        await store.finish()
    }

    func testDismissCompletionViewClearsPathAndStopsHaptic() async {
        let initialState = CoordinatorState()
        var mutableInitialState = initialState
        mutableInitialState.timer.completionDate = Date()

        let store = TestStore(
            initialState: mutableInitialState,
            reducer: { CoordinatorReducer() }
        )

        await store.send(CoordinatorAction.timer(.dismissCompletionView)) { state in
            state.path = []
            state.timer.completionDate = nil
        }

        await store.receive(CoordinatorAction.haptics(.stopHaptic))

        store.assert { state in
            state.haptics.isActive = false
        }
        await store.finish()
    }
}
