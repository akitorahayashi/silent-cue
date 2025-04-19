@testable import SilentCue_Watch_App
import ComposableArchitecture
import WatchKit
import XCTest

final class SettingsReducerTests: XCTestCase {
    // AppReducer 経由での設定読み込みの統合テスト
    func testLoadSettingsViaAppReducer() async {
        let mockUserDefaults = MockUserDefaultsManager()
        // setupInitialValues の代わりに直接値を設定
        mockUserDefaults.set(HapticType.strong.rawValue, forKey: UserDefaultsKeys.hapticType)

        let store = TestStore(
            initialState: AppState(),
            reducer: { AppReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
            }
        )

        // 正しいスコープで AppAction.settings を送信
        await store.send(.settings(.loadSettings))

        await store.receive(.settings(.settingsLoaded(
            hapticType: HapticType.strong
        ))) { state in
            state.settings.selectedHapticType = HapticType.strong
            state.settings.isSettingsLoaded = true
        }

        // AppReducer 内で連鎖するアクション
        await store.receive(.haptics(.updateHapticSettings(
            type: HapticType.strong
        ))) { state in
            state.haptics.hapticType = HapticType.strong
        }
        await store.finish()
    }

    // AppReducer 経由での触覚タイプ選択の統合テスト
    func testSelectHapticTypeViaAppReducer() async {
        let mockUserDefaults = MockUserDefaultsManager()

        var initialState = AppState()
        initialState.settings.selectedHapticType = HapticType.standard

        let store = TestStore(
            initialState: initialState,
            reducer: { AppReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                // 共有の MockHapticsService を使用
                dependencies.hapticsService = MockHapticsService()
            }
        )

        // 正しいスコープで AppAction.settings を送信
        await store.send(.settings(.selectHapticType(HapticType.weak))) { state in
            state.settings.selectedHapticType = HapticType.weak
        }

        // SettingsReducer 内で selectHapticType によってトリガーされるエフェクトを期待 (スコープ付き)
        await store.receive(.settings(.previewHapticFeedback(.weak))) { state in
            state.settings.isPreviewingHaptic = true
        }
        // AppReducer から連鎖するアクションを期待
        await store.receive(.haptics(.updateHapticSettings(type: .weak))) { state in
            state.haptics.hapticType = .weak
        }
        // Preview completion action
        await store.receive(.settings(.previewHapticCompleted)) { state in
            state.settings.isPreviewingHaptic = false
        }

        // エフェクト完了後に UserDefaults に値が保存されたことをアサート
        XCTAssertEqual(mockUserDefaults.object(forKey: .hapticType) as? String, HapticType.weak.rawValue)

        await store.finish()
    }

    // AppReducer 経由での設定保存の統合テスト (必要であれば別途テスト)
    // func testSaveSettingsViaAppReducer() async { ... }

    // SettingsReducer を直接テスト: 値が存在しない場合の loadSettings
    func testLoadSettings_WhenNoValueExists() async {
        let mockUserDefaults = MockUserDefaultsManager() // 初期値は未設定
        let store = TestStore(initialState: SettingsState()) {
            SettingsReducer() // SettingsReducer を直接テスト
        } withDependencies: { dependencies in
            dependencies.userDefaultsService = mockUserDefaults
        }

        // SettingsAction を直接送信
        await store.send(SettingsAction.loadSettings)

        // SettingsAction を直接期待
        await store.receive(SettingsAction.settingsLoaded(hapticType: HapticType.standard)) {
            $0.selectedHapticType = HapticType.standard
            $0.isSettingsLoaded = true
        }
        // No effects expected from loadSettings itself, so finish immediately
        await store.finish()
    }

    // SettingsReducer を直接テスト: selectHapticType によってトリガーされる saveSettings
    func testSaveSettings() async {
        let mockUserDefaults = MockUserDefaultsManager()
        // 変更を確認するために異なる初期状態で開始
        let store = TestStore(initialState: SettingsState(selectedHapticType: .standard)) {
            SettingsReducer() // SettingsReducer を直接テスト
        } withDependencies: { dependencies in
            dependencies.userDefaultsService = mockUserDefaults
            dependencies.hapticsService = MockHapticsService()
        }

        // SettingsAction を直接送信
        await store.send(SettingsAction.selectHapticType(.weak)) {
            $0.selectedHapticType = .weak // 状態は即座に更新されるべき
        }

        // SettingsReducer 内でトリガーされるエフェクトを期待
        // .saveSettings アクションは送信されないため、エフェクト後にモックを直接確認
        await store.receive(SettingsAction.previewHapticFeedback(.weak)) { $0.isPreviewingHaptic = true }
        await store.receive(SettingsAction.previewHapticCompleted) { $0.isPreviewingHaptic = false }

        // エフェクト完了後に UserDefaults に値が保存されたことをアサート
        XCTAssertEqual(mockUserDefaults.object(forKey: .hapticType) as? String, HapticType.weak.rawValue)

        await store.finish()
    }
}
