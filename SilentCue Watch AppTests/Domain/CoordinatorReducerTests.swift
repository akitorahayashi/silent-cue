import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class CoordinatorReducerTests: XCTestCase {
    func testOnAppearLoadsSettings() async {
        let mockUserDefaults = MockUserDefaultsManager()

        // モックに期待される初期値を設定
        mockUserDefaults.set(HapticType.standard.rawValue, forKey: UserDefaultsKeys.hapticType)

        let store = TestStore(
            initialState: CoordinatorState(),
            reducer: { CoordinatorReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
            }
        )

        // AppAction.onAppear を送信
        await store.send(CoordinatorAction.onAppear)

        // loadSettings アクションを期待
        await store.receive(CoordinatorAction.settings(.loadSettings))

        // settingsLoaded アクションを期待
        await store.receive(CoordinatorAction.settings(.settingsLoaded(
            hapticType: HapticType.standard
        ))) { state in
            state.settings.selectedHapticType = HapticType.standard
            state.settings.isSettingsLoaded = true
        }

        // AppReducer内の機能連携による updateHapticSettings アクションを期待
        // 状態の変更もアサートする
        await store.receive(CoordinatorAction.haptics(.updateHapticSettings(
            type: HapticType.standard
        )))

        // エフェクトが完了したことを確認
        await store.finish()
    }

    func testSettingsLoadedUpdatesHaptics() async {
        let store = TestStore(
            initialState: CoordinatorState(),
            reducer: { CoordinatorReducer() }
        )

        let loadedAction = SettingsAction.settingsLoaded(hapticType: HapticType.weak)
        // アクションを送信し、SettingsReducerスコープからの即時の状態変更をアサート
        await store.send(CoordinatorAction.settings(loadedAction)) { state in
            state.settings.selectedHapticType = HapticType.weak
            state.settings.isSettingsLoaded = true
        }

        // AppReducerの連携による後続のアクションをアサート (状態変更を伴う)
        await store.receive(CoordinatorAction.haptics(.updateHapticSettings(
            type: HapticType.weak
        ))) { state in
            state.haptics.hapticType = HapticType.weak
        }

        // 最終的な状態をアサート (Now handled in the receive block above)
        // store.assert { state in
        //     state.haptics.hapticType = HapticType.weak
        // }

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

        // dismissを送信し、即時の状態変更をアサート
        await store.send(CoordinatorAction.timer(.dismissCompletionView)) { state in
            state.path = []
            state.timer.completionDate = nil
        }

        // 後続のアクションを受信する
        await store.receive(CoordinatorAction.haptics(.stopHaptic))

        // 最終的な状態をアサート
        store.assert { state in
            state.haptics.isActive = false
        }
        await store.finish()
    }
}
