import ComposableArchitecture
import SCMock
import SCShared
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class CoordinatorReducerTests: XCTestCase {
    func testOnAppearLoadsSettings() async {
        let mockUserDefaults = MockUserDefaultsManager()

        // モックに期待される初期値を設定
        mockUserDefaults.set(HapticType.standard.rawValue, forKey: UserDefaultsKeys.hapticType)
        // このテストは初回起動ではないシナリオを想定するため、 isFirstLaunch を false に設定
        mockUserDefaults.set(false, forKey: UserDefaultsKeys.isFirstLaunch)

        let store = TestStore(
            initialState: CoordinatorState(),
            reducer: { CoordinatorReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
            }
        )

        // AppAction.onAppear を送信
        await store.send(CoordinatorAction.onAppear)

        // onAppear はまず checkFirstLaunch をトリガーする
        await store.receive(.checkFirstLaunch)

        // isFirstLaunch=false なので、次に loadSettings アクションを期待
        await store.receive(.settings(.loadSettings))

        // settingsLoaded アクションとその状態変更を期待
        await store.receive(CoordinatorAction.settings(.settingsLoaded(
            hapticType: HapticType.standard
        ))) { state in
            state.settings.selectedHapticType = HapticType.standard
            state.settings.isSettingsLoaded = true
        }

        // settingsLoaded によって引き起こされる updateHapticSettings アクションを期待
        // この時点では HapticsState.hapticType は既に .standard (デフォルト値) なので状態変更は発生しない
        await store.receive(.haptics(.updateHapticSettings(type: .standard)))

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
