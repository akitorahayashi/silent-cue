import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class AppReducerTests: XCTestCase {
    func testOnAppearLoadsSettings() async {
        let mockUserDefaults = MockUserDefaultsManager()
        // モックに期待される初期値を設定
        mockUserDefaults.setupInitialValues([
            .stopVibrationAutomatically: true, // 例: true
            .hapticType: HapticType.standard.rawValue, // 例: standard
        ])

        let store = TestStore(
            initialState: AppState(),
            reducer: { AppReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsManager = mockUserDefaults
            }
        )

        await store.send(AppAction.onAppear)

        // まず loadSettings を期待
        await store.receive(AppAction.settings(.loadSettings))

        // 次にエフェクトから settingsLoaded を期待
        await store.receive(AppAction.settings(.settingsLoaded(
            stopVibration: true,
            hapticType: HapticType.standard
        ))) { state in
            state.settings.stopVibrationAutomatically = true
            state.settings.selectedHapticType = HapticType.standard
            state.settings.hasLoaded = true
        }

        // 次にAppReducerの連携によるhaptics更新を期待
        await store.receive(AppAction.haptics(.updateHapticSettings(
            type: HapticType.standard,
            stopAutomatically: true
        )))

        await store.finish()
    }

    func testSettingsLoadedUpdatesHaptics() async {
        let store = TestStore(
            initialState: AppState(),
            reducer: { AppReducer() }
        )

        let loadedAction = SettingsAction.settingsLoaded(stopVibration: false, hapticType: HapticType.weak)
        // アクションを送信し、SettingsReducerスコープからの即時の状態変更をアサート
        await store.send(AppAction.settings(loadedAction)) { state in
            state.settings.stopVibrationAutomatically = false
            state.settings.selectedHapticType = HapticType.weak
            state.settings.hasLoaded = true
        }

        // AppReducerの連携による後続のアクションをアサート
        await store.receive(AppAction.haptics(.updateHapticSettings(
            type: HapticType.weak,
            stopAutomatically: false
        ))) { state in
            state.haptics.hapticType = HapticType.weak
            state.haptics.stopAutomatically = false
        }
        await store.finish()
    }

    func testDismissCompletionViewClearsPathAndStopsHaptic() async {
        let initialState = AppState(
            path: [NavigationDestination.completion],
            haptics: HapticsState(isActive: true)
        )
        var mutableInitialState = initialState
        mutableInitialState.timer.completionDate = Date()

        let store = TestStore(
            initialState: mutableInitialState,
            reducer: { AppReducer() }
        )

        // dismissを送信し、即時の状態変更をアサート
        await store.send(AppAction.timer(.dismissCompletionView)) { state in
            state.path = []
            state.timer.completionDate = nil
        }

        // 後続のアクションをアサート
        await store.receive(AppAction.haptics(.stopHaptic)) { state in
            state.haptics.isActive = false
        }
        await store.finish()
    }
}
