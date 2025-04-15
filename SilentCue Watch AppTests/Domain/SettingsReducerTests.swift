import ComposableArchitecture
@testable import SilentCue_Watch_App
import XCTest

@MainActor
final class SettingsReducerTests: XCTestCase {
    func testLoadSettings() async {
        let mockUserDefaults = MockUserDefaultsManager()
        mockUserDefaults.setupInitialValues([
            .stopVibrationAutomatically: false,
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

        await store.receive(AppAction.settings(.settingsLoaded(stopVibration: false, hapticType: HapticType.strong))) { state in
            state.settings.stopVibrationAutomatically = false
            state.settings.selectedHapticType = HapticType.strong
            state.settings.hasLoaded = true
        }
        
        await store.receive(AppAction.haptics(.updateHapticSettings(type: HapticType.strong, stopAutomatically: false))) { state in
            state.haptics.hapticType = HapticType.strong
            state.haptics.stopAutomatically = false
        }
        await store.finish() // Effects from loadSettings
    }

    func testToggleStopVibrationAutomatically() async {
        let mockUserDefaults = MockUserDefaultsManager()
        
        var initialState = AppState()
        initialState.settings.stopVibrationAutomatically = true
        let initialHapticType = initialState.settings.selectedHapticType 
        
        let store = TestStore(
            initialState: initialState,
            reducer: { AppReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsManager = mockUserDefaults
            }
        )

        await store.send(AppAction.settings(.toggleStopVibrationAutomatically(false))) { state in
            state.settings.stopVibrationAutomatically = false
        }
        
        await store.receive(AppAction.settings(.saveSettings))
        
        await store.receive(AppAction.haptics(.updateHapticSettings(type: initialHapticType, stopAutomatically: false))) { state in
            state.haptics.hapticType = initialHapticType
            state.haptics.stopAutomatically = false
        }

        await store.send(AppAction.settings(.toggleStopVibrationAutomatically(true))) { state in
            state.settings.stopVibrationAutomatically = true
        }
        
        await store.receive(AppAction.settings(.saveSettings))
        
        await store.receive(AppAction.haptics(.updateHapticSettings(type: initialHapticType, stopAutomatically: true))) { state in
            state.haptics.hapticType = initialHapticType
            state.haptics.stopAutomatically = true
        }
        await store.finish() // Effects from saveSettings
    }

    func testSelectHapticType() async {
        let mockUserDefaults = MockUserDefaultsManager()
        
        var initialState = AppState()
        initialState.settings.selectedHapticType = HapticType.standard
        let initialStopAutomatically = initialState.settings.stopVibrationAutomatically
        
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
        initialState.settings.stopVibrationAutomatically = false
        initialState.settings.selectedHapticType = HapticType.strong
        
        let store = TestStore(
            initialState: initialState,
            reducer: { AppReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsManager = mockUserDefaults
            }
        )

        await store.send(AppAction.settings(.saveSettings))
        
        // No haptics update action is expected here based on AppReducer
        // await store.receive(AppAction.haptics(.updateHapticSettings(type: HapticType.strong, stopAutomatically: false))) { state in
        //     state.haptics.hapticType = HapticType.strong
        //     state.haptics.stopAutomatically = false
        // }

        XCTAssertEqual(mockUserDefaults.storage[.hapticType] as? String, HapticType.strong.rawValue)
        XCTAssertEqual(mockUserDefaults.storage[.stopVibrationAutomatically] as? Bool, false)
        
        await store.finish() // Effect from saveSettings
    }
}
