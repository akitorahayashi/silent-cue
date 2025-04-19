import ComposableArchitecture
@testable import SilentCue_Watch_App
import WatchKit
import XCTest

@MainActor
final class SettingsReducerTests: XCTestCase {
    // Test AppReducer integration for load settings
    func testLoadSettingsViaAppReducer() async {
        let mockUserDefaults = MockUserDefaultsManager()
        // Use direct set instead of setupInitialValues
        mockUserDefaults.set(HapticType.strong.rawValue, forKey: UserDefaultsKeys.hapticType)

        let store = TestStore(
            initialState: AppState(),
            reducer: { AppReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
            }
        )

        // Send AppAction.settings with correct scope
        await store.send(.settings(.loadSettings))

        await store.receive(.settings(.settingsLoaded(
            hapticType: HapticType.strong
        ))) { state in
            state.settings.selectedHapticType = HapticType.strong
            state.settings.isSettingsLoaded = true
        }

        // Action chained within AppReducer
        await store.receive(.haptics(.updateHapticSettings(
            type: HapticType.strong
        ))) { state in
            state.haptics.hapticType = HapticType.strong
        }
        await store.finish()
    }

    // Test AppReducer integration for select haptic type
    func testSelectHapticTypeViaAppReducer() async {
        let mockUserDefaults = MockUserDefaultsManager()

        var initialState = AppState()
        initialState.settings.selectedHapticType = HapticType.standard

        let store = TestStore(
            initialState: initialState,
            reducer: { AppReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                // Use shared MockHapticsService
                dependencies.hapticsService = MockHapticsService()
            }
        )

        // Send AppAction.settings with correct scope
        await store.send(.settings(.selectHapticType(HapticType.weak))) { state in
            state.settings.selectedHapticType = HapticType.weak
        }

        // Expect chained actions from AppReducer
        await store.receive(.haptics(.updateHapticSettings(type: .weak))) { state in
            state.haptics.hapticType = .weak
        }
        // Expect effects triggered by selectHapticType within SettingsReducer (now scoped)
        await store.receive(.settings(.saveSettings))
        await store.receive(.settings(.previewHapticFeedback(.weak))) { state in
            state.settings.isPreviewingHaptic = true
        }
        await store.receive(.settings(.previewHapticCompleted)) { state in
            state.settings.isPreviewingHaptic = false
        }

        await store.finish()
    }

    // Test AppReducer integration for save settings (if needed as separate test)
    // func testSaveSettingsViaAppReducer() async { ... }

    // Test SettingsReducer directly: loadSettings with no value
    func testLoadSettings_WhenNoValueExists() async {
        let mockUserDefaults = MockUserDefaultsManager() // No initial value set
        let store = TestStore(initialState: SettingsState()) {
            SettingsReducer() // Test SettingsReducer directly
        } withDependencies: { dependencies in
            dependencies.userDefaultsService = mockUserDefaults
        }

        // Send SettingsAction directly
        await store.send(.loadSettings)

        // Expect SettingsAction directly
        await store.receive(.settingsLoaded(hapticType: HapticType.standard)) { // Use full HapticType path
            $0.selectedHapticType = HapticType.standard
            $0.isSettingsLoaded = true
        }
    }

    // Test SettingsReducer directly: saveSettings triggered by selectHapticType
    func testSaveSettings() async {
        let mockUserDefaults = MockUserDefaultsManager()
        let store = TestStore(initialState: SettingsState(selectedHapticType: .weak)) {
            SettingsReducer() // Test SettingsReducer directly
        } withDependencies: { dependencies in
            dependencies.userDefaultsService = mockUserDefaults
            dependencies.hapticsService = MockHapticsService()
        }

        // Send SettingsAction directly
        await store.send(.selectHapticType(HapticType.weak)) // Use full HapticType path

        // Check mock state directly
        XCTAssertEqual(mockUserDefaults.object(forKey: .hapticType) as? String, HapticType.weak.rawValue)

        // Expect effects triggered within SettingsReducer
        await store.receive(.saveSettings)
        await store.receive(.previewHapticFeedback(HapticType.weak)) { $0.isPreviewingHaptic = true } // Use full HapticType path
        await store.receive(.previewHapticCompleted) { $0.isPreviewingHaptic = false }

        await store.finish()
    }
}