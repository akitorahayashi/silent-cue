import XCTest
@testable import SilentCue_Watch_App
import ComposableArchitecture

@MainActor
final class SettingsReducerTests: XCTestCase {
    
    // テスト用の依存関係
    private func testReducer(
        userDefaultsManager: @escaping () -> UserDefaultsManagerProtocol = { 
            let mock = MockUserDefaultsManager()
            mock.mockReturnValues[.stopVibrationAutomatically] = true
            mock.mockReturnValues[.hapticType] = HapticType.standard.rawValue
            return mock
        }
    ) -> TestStore<SettingsState, SettingsAction> {
        TestStore(
            initialState: SettingsState(),
            reducer: {
                SettingsReducer()
                    .dependency(\.userDefaultsManager, userDefaultsManager())
            }
        )
    }
    
    func testLoadSettings() async {
        let userDefaultsManager = MockUserDefaultsManager()
        userDefaultsManager.mockReturnValues[.stopVibrationAutomatically] = false
        userDefaultsManager.mockReturnValues[.hapticType] = HapticType.strong.rawValue
        
        let store = testReducer(userDefaultsManager: { userDefaultsManager })
        
        await store.send(.loadSettings)
        
        await store.receive(.settingsLoaded(stopVibration: false, hapticType: .strong)) { state in
            state.stopVibrationAutomatically = false
            state.selectedHapticType = .strong
            state.hasLoaded = true
        }
    }
    
    func testToggleStopVibrationAutomatically() async {
        let userDefaultsManager = MockUserDefaultsManager()
        let store = testReducer(userDefaultsManager: { userDefaultsManager })
        
        // 初期値からトグルをテスト
        await store.send(.toggleStopVibrationAutomatically(false)) { state in
            state.stopVibrationAutomatically = false
        }
        
        // 設定の保存アクションが発行される
        await store.receive(.saveSettings)
        
        // 再度トグルのテスト
        await store.send(.toggleStopVibrationAutomatically(true)) { state in
            state.stopVibrationAutomatically = true
        }
        
        await store.receive(.saveSettings)
    }
    
    func testSelectHapticType() async {
        // テストストアの厳密さを完全に無効にする
        let store = TestStore(
            initialState: SettingsState(),
            reducer: {
                SettingsReducer()
                    .dependency(\.userDefaultsManager, MockUserDefaultsManager())
            }
        )
        
        // テスト全体で厳密性を無効化
        store.exhaustivity = .off
        
        // ハプティックタイプを選択
        await store.send(.selectHapticType(.strong))
        
        // 別のハプティックタイプを選択
        await store.send(.selectHapticType(.weak))
    }
    
    func testSaveSettings() async {
        let userDefaultsManager = MockUserDefaultsManager()
        let store = TestStore(
            initialState: SettingsState(),
            reducer: {
                SettingsReducer()
                    .dependency(\.userDefaultsManager, userDefaultsManager)
            }
        )
        
        // テスト全体で厳密性を無効化
        store.exhaustivity = .off
        
        // 設定の初期状態を変更
        await store.send(.toggleStopVibrationAutomatically(false))
        
        // ハプティックタイプを変更
        await store.send(.selectHapticType(.strong))
        
        // UserDefaultsに正しく保存されたか確認
        XCTAssertEqual(userDefaultsManager.mockReturnValues[.hapticType] as? String, HapticType.strong.rawValue)
    }
    
    func testPreviewHapticFeedback() async {
        let store = TestStore(
            initialState: SettingsState(),
            reducer: {
                SettingsReducer()
                    .dependency(\.userDefaultsManager, MockUserDefaultsManager())
            }
        )
        
        // テスト全体で厳密性を無効化
        store.exhaustivity = .off
        
        // プレビュー開始
        await store.send(.previewHapticFeedback(.weak))
        
        // プレビュー完了
        await store.send(.previewHapticCompleted)
    }
}

// 削除: MockUserDefaultsManagerを別ファイルに移動済み 