import ComposableArchitecture
import SCMock
@testable import SilentCue_Watch_App
import WatchKit
import XCTest

@MainActor
final class SettingsReducerTests: XCTestCase {
    // TestDependencies 構造体は削除

    // テスト: UserDefaults に値が存在しない場合に設定をロードする
    func testLoadSettings_Default() async {
        // TestStore と依存関係をここで初期化
        let mockUserDefaults = MockUserDefaultsManager()
        let mockHaptics = MockHapticsService()
        let clock = TestClock()
        let store = TestStore(
            initialState: SettingsState(),
            reducer: { SettingsReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                dependencies.hapticsService = mockHaptics
                dependencies.continuousClock = clock
            }
        )

        mockUserDefaults.remove(forKey: .hapticType)
        await store.send(SettingsAction.loadSettings)
        await store.receive(SettingsAction.settingsLoaded(hapticType: HapticType.standard)) {
            $0.selectedHapticType = HapticType.standard
            $0.isSettingsLoaded = true
        }
        await store.finish()
    }

    // テスト: UserDefaults に値が存在する場合に設定をロードする
    func testLoadSettings_ExistingValue() async {
        // TestStore と依存関係をここで初期化
        let mockUserDefaults = MockUserDefaultsManager()
        let mockHaptics = MockHapticsService()
        let clock = TestClock()
        let store = TestStore(
            initialState: SettingsState(),
            reducer: { SettingsReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                dependencies.hapticsService = mockHaptics
                dependencies.continuousClock = clock
            }
        )

        mockUserDefaults.set(HapticType.strong.rawValue, forKey: .hapticType)
        await store.send(SettingsAction.loadSettings)
        await store.receive(SettingsAction.settingsLoaded(hapticType: HapticType.strong)) {
            $0.selectedHapticType = HapticType.strong
            $0.isSettingsLoaded = true
        }
        await store.finish()
    }

    // テスト: ハプティクスタイプを選択すると保存がトリガーされ、プレビューが開始される
    func testSelectHapticType_TriggersSaveAndStartsPreview() async {
        // TestStore と依存関係をここで初期化
        let mockUserDefaults = MockUserDefaultsManager()
        let mockHaptics = MockHapticsService()
        let clock = TestClock()
        let store = TestStore(
            initialState: SettingsState(),
            reducer: { SettingsReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                dependencies.hapticsService = mockHaptics
                dependencies.continuousClock = clock
            }
        )

        let selectedType = HapticType.weak
        await store.send(SettingsAction.selectHapticType(selectedType)) {
            $0.selectedHapticType = selectedType // 即時の状態更新を期待
        }

        await store.receive(SettingsAction.internal(.saveSettingsEffect))
        await Task.yield()
        XCTAssertEqual(
            mockUserDefaults.object(forKey: .hapticType) as? String,
            selectedType.rawValue,
            "UserDefaults が更新されていること"
        )

        await store.receive(SettingsAction.startHapticPreview(selectedType)) {
            $0.isPreviewingHaptic = true // 状態変化を期待
        }

        XCTAssertEqual(mockHaptics.playCallCount, 1, "開始時にハプティクスが1回再生されること")
        XCTAssertEqual(mockHaptics.lastPlayedHapticType, selectedType.wkHapticType, "正しいハプティクスタイプが再生されること")

        await store.skipInFlightEffects()
        await store.finish()
    }

    // テスト: ハプティクスプレビューのティックとタイムアウトのフロー
    func testHapticPreview_FlowWithTicksAndTimeout() async {
        // TestStore と依存関係をここで初期化
        let mockUserDefaults = MockUserDefaultsManager()
        let mockHaptics = MockHapticsService()
        let clock = TestClock()
        let store = TestStore(
            initialState: SettingsState(),
            reducer: { SettingsReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                dependencies.hapticsService = mockHaptics
                dependencies.continuousClock = clock
            }
        )

        let hapticType = HapticType.standard
        let interval = hapticType.interval
        let previewTimeout: Duration = .seconds(3)
        let previewTimeoutSeconds = previewTimeout / .seconds(1)
        let expectedTickCount =
            Int(floor((previewTimeoutSeconds - 0.0001) / interval))
        let expectedTotalPlays = expectedTickCount + 1

        await store.send(SettingsAction.startHapticPreview(hapticType)) {
            $0.isPreviewingHaptic = true
        }
        XCTAssertEqual(mockHaptics.playCallCount, 1, "初期ハプティクスが即時に再生されること")

        if expectedTickCount > 0 {
            for tickCount in 1 ... expectedTickCount {
                await clock.advance(by: .seconds(interval))
                await store.receive(SettingsAction.hapticPreviewTick)
                XCTAssertEqual(mockHaptics.playCallCount, tickCount + 1, "ティック \(tickCount) でハプティクスが再生されること")
                XCTAssertTrue(store.state.isPreviewingHaptic, "ティック \(tickCount) 後もプレビュー中であること")
            }
        }

        let timeElapsed = Double(expectedTickCount) * interval
        let remainingTime = previewTimeoutSeconds - timeElapsed
        let advanceDuration = max(0.001, remainingTime)
        await clock.advance(by: .seconds(advanceDuration))

        await store.receive(SettingsAction.stopHapticPreview) {
            $0.isPreviewingHaptic = false
        }
        XCTAssertEqual(mockHaptics.playCallCount, expectedTotalPlays, "タイムアウト後のハプティクス再生回数が合計再生回数と一致すること")

        await clock.advance(by: .seconds(interval * 2))
        XCTAssertEqual(mockHaptics.playCallCount, expectedTotalPlays, "タイムアウト停止後にハプティクスが再生されないこと")

        await store.finish()
    }

    // テスト: 新しいハプティクスタイプを選択すると、進行中のプレビューがキャンセルされ、新しいプレビューが開始される
    func testSelectHapticType_CancelsOngoingPreviewAndStartsNew() async {
        let initialType = HapticType.standard
        let initialState = SettingsState(selectedHapticType: initialType)

        // TestStore と依存関係をここで初期化
        let mockUserDefaults = MockUserDefaultsManager()
        let mockHaptics = MockHapticsService()
        let clock = TestClock()
        let store = TestStore(
            initialState: initialState, // テスト固有の初期状態
            reducer: { SettingsReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                dependencies.hapticsService = mockHaptics
                dependencies.continuousClock = clock
            }
        )

        await store.send(SettingsAction.startHapticPreview(initialType)) { $0.isPreviewingHaptic = true }
        XCTAssertEqual(mockHaptics.playCallCount, 1, "最初のプレビューが開始されたこと")
        let countAfterInitialStart = mockHaptics.playCallCount

        await clock.advance(by: .milliseconds(100))

        let newType = HapticType.strong
        await store.send(SettingsAction.selectHapticType(newType)) {
            $0.selectedHapticType = newType
        }

        await store.receive(SettingsAction.stopHapticPreview) {
            $0.isPreviewingHaptic = false
        }

        await store.receive(SettingsAction.internal(.saveSettingsEffect))
        await Task.yield()

        await store.receive(SettingsAction.startHapticPreview(newType)) {
            $0.isPreviewingHaptic = true
        }
        XCTAssertEqual(mockHaptics.playCallCount, countAfterInitialStart + 1, "新しいプレビュー開始時に再生回数が増加すること")
        XCTAssertEqual(mockHaptics.lastPlayedHapticType, newType.wkHapticType, "正しい新しいハプティクスタイプが再生されること")

        await store.skipInFlightEffects()
        await store.finish()
    }

    // テスト: 戻るボタンをタップすると進行中のプレビューがキャンセルされる
    func testBackButtonTapped_CancelsOngoingPreview() async {
        let hapticType = HapticType.standard
        let initialState = SettingsState(selectedHapticType: hapticType)

        // TestStore と依存関係をここで初期化
        let mockUserDefaults = MockUserDefaultsManager()
        let mockHaptics = MockHapticsService()
        let clock = TestClock()
        let store = TestStore(
            initialState: initialState, // テスト固有の初期状態
            reducer: { SettingsReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                dependencies.hapticsService = mockHaptics
                dependencies.continuousClock = clock
            }
        )

        await store.send(SettingsAction.startHapticPreview(hapticType)) { $0.isPreviewingHaptic = true }
        XCTAssertEqual(mockHaptics.playCallCount, 1, "最初のプレビューが開始されたこと")
        let countAfterStart = mockHaptics.playCallCount

        await clock.advance(by: .milliseconds(100))

        await store.send(SettingsAction.backButtonTapped)

        await store.receive(SettingsAction.stopHapticPreview) { $0.isPreviewingHaptic = false }

        await clock.advance(by: .seconds(3))
        XCTAssertEqual(mockHaptics.playCallCount, countAfterStart, "戻るボタンによるキャンセル後にハプティクスが再生されないこと")

        await store.finish()
    }
}
