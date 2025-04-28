import ComposableArchitecture
import SCMock
import SCShared
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class CoordinatorReducerTests: XCTestCase {
    var store: TestStore<CoordinatorState, CoordinatorAction>!

    override func setUp() {
        super.setUp()
        store = TestStore(
            initialState: CoordinatorState(),
            reducer: { CoordinatorReducer() },
            withDependencies: {
                $0.userDefaultsService = MockUserDefaultsManager()
                $0.notificationService = MockNotificationService()
                $0.hapticsService = MockHapticsService()
                $0.date = .constant(Date(timeIntervalSince1970: 0))
            }
        )
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    func testOnAppearLoadsSettings() async {
        let mockUserDefaults = MockUserDefaultsManager()
        mockUserDefaults.set(HapticType.standard.rawValue, forKey: UserDefaultsKeys.hapticType)
        mockUserDefaults.set(false, forKey: UserDefaultsKeys.isFirstLaunch)

        // このテスト固有の依存関係を上書き
        store.dependencies.userDefaultsService = mockUserDefaults
        store.dependencies.notificationService = MockNotificationService()

        // 状態をリセット (必要であれば)
        store = TestStore(
            initialState: CoordinatorState(),
            reducer: { CoordinatorReducer() },
            withDependencies: { $0 = store.dependencies }
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
        // setUp で初期化されたストアを使用
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
        var initialState = CoordinatorState()
        initialState.timer.completionDate = Date()

        // このテスト用に特定の初期状態でストアを再初期化
        store = TestStore(
            initialState: initialState,
            reducer: { CoordinatorReducer() },
            withDependencies: { $0 = store.dependencies }
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
