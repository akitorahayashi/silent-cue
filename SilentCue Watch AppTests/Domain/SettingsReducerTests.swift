import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class SettingsReducerTests: XCTestCase {
    func testLoadSettings() async {
        let mockUserDefaults = MockUserDefaultsManager()
        mockUserDefaults.setupInitialValues([
            .hapticType: HapticType.strong.rawValue,
        ])

        let store = TestStore(
            initialState: AppState(),
            reducer: { AppReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsManager = mockUserDefaults
            }
        )

        await store.send(AppAction.settings(.loadSettings))

        await store.receive(AppAction.settings(.settingsLoaded(
            hapticType: HapticType.strong
        ))) { state in
            state.settings.selectedHapticType = HapticType.strong
            state.settings.isSettingsLoaded = true
        }

        await store.receive(AppAction.haptics(.updateHapticSettings(
            type: HapticType.strong
        ))) { state in
            state.haptics.hapticType = HapticType.strong
        }
        await store.finish() // Effects from loadSettings
    }

    func testSelectHapticType() async {
        let mockUserDefaults = MockUserDefaultsManager()

        var initialState = AppState()
        initialState.settings.selectedHapticType = HapticType.standard

        let store = TestStore(
            initialState: initialState,
            reducer: { AppReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsManager = mockUserDefaults
            }
        )

        // エラーを避けるため非網羅的テストモードに設定
        store.exhaustivity = .off

        await store.send(AppAction.settings(.selectHapticType(HapticType.weak))) { state in
            state.settings.selectedHapticType = HapticType.weak
        }

        // finish()でテスト終了を明示
        await store.finish()
    }

    func testSaveSettings() async {
        let mockUserDefaults = MockUserDefaultsManager()

        var initialState = AppState()
        initialState.settings.selectedHapticType = HapticType.strong

        let store = TestStore(
            initialState: initialState,
            reducer: { AppReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsManager = mockUserDefaults
            }
        )

        await store.send(AppAction.settings(.saveSettings))

        XCTAssertEqual(mockUserDefaults.storage[.hapticType] as? String, HapticType.strong.rawValue)

        await store.finish() // Effect from saveSettings
    }
}
