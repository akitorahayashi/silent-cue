import ComposableArchitecture
import SCMock
import SCShared
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
            $0.selectedHapticType = selectedType
        }

        await store.receive(SettingsAction.internal(.saveSettingsEffect))
        await Task.yield()
        XCTAssertEqual(
            mockUserDefaults.object(forKey: .hapticType) as? String,
            selectedType.rawValue,
            "UserDefaults が更新されていること"
        )

        await store.receive(SettingsAction.startHapticPreview(selectedType)) {
            $0.isPreviewingHaptic = true
        }

        await Task.yield()
        XCTAssertEqual(mockHaptics.playCallCount, 1, "開始時にハプティクスが1回再生されること")
        XCTAssertEqual(mockHaptics.lastPlayedHapticType, selectedType.wkHapticType, "正しいハプティクスタイプが再生されること")

        // プレビューに関連する実行中のエフェクトをスキップ
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
        let previewTimeoutSeconds = Double(previewTimeout.components.seconds) +
            Double(previewTimeout.components.attoseconds) / 1_000_000_000_000_000_000.0
        let expectedTickCount = Int(floor((previewTimeoutSeconds - 0.000001) / interval))
        let expectedTotalPlays = expectedTickCount + 1

        await store.send(SettingsAction.startHapticPreview(hapticType)) {
            $0.isPreviewingHaptic = true
        }
        await Task.yield()
        XCTAssertEqual(mockHaptics.playCallCount, 1, "初期ハプティクスが即時に再生されること")

        // Tick の処理
        if expectedTickCount > 0 {
            for tickIndex in 1 ... expectedTickCount {
                await clock.advance(by: .seconds(interval))
                await store.receive(SettingsAction.hapticPreviewTick)
                await Task.yield()
                XCTAssertEqual(mockHaptics.playCallCount, tickIndex + 1, "ティック \\(tickIndex) でハプティクスが再生されること")
                XCTAssertTrue(store.state.isPreviewingHaptic)
            }
        }

        // タイムアウトまでの残り時間を計算して進める
        let timeElapsed = Double(expectedTickCount) * interval
        let remainingNanoseconds = previewTimeout.components
            .attoseconds + (previewTimeout.components.seconds * 1_000_000_000_000_000_000) -
            Int64(timeElapsed * 1_000_000_000_000_000_000)
        let remainingDuration = Duration(secondsComponent: 0, attosecondsComponent: remainingNanoseconds)

        // タイムアウトする瞬間まで進める (わずかに進める)
        await clock.advance(by: remainingDuration + .nanoseconds(1))

        // タイムアウト効果により stopHapticPreview を期待
        await store.receive(SettingsAction.stopHapticPreview) {
            $0.isPreviewingHaptic = false
        }
        await Task.yield()
        XCTAssertEqual(mockHaptics.playCallCount, expectedTotalPlays, "タイムアウト後のハプティクス再生回数が合計再生回数と一致すること")

        // タイムアウト後、さらに時間が経過しても再生されないことを確認
        await clock.advance(by: .seconds(interval * 2))
        await Task.yield()
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
            initialState: initialState,
            reducer: { SettingsReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                dependencies.hapticsService = mockHaptics
                dependencies.continuousClock = clock
            }
        )

        // 最初のプレビューを開始
        await store.send(SettingsAction.startHapticPreview(initialType)) {
            $0.isPreviewingHaptic = true
        }
        await Task.yield()
        XCTAssertEqual(mockHaptics.playCallCount, 1, "最初のプレビューが開始されたこと")
        let countAfterInitialStart = mockHaptics.playCallCount

        await clock.advance(by: .milliseconds(100))

        // 新しいタイプを選択
        let newType = HapticType.strong
        await store.send(SettingsAction.selectHapticType(newType)) {
            $0.selectedHapticType = newType
            // isPreviewingHaptic の設定は下の stopHapticPreview receive で行われる
        }

        // Reducer の .merge で送信される順序でアクションを期待
        // 1. 古いプレビューを停止
        await store.receive(SettingsAction.stopHapticPreview) {
            $0.isPreviewingHaptic = false
        }

        // 2. 新しい設定を保存
        await store.receive(SettingsAction.internal(.saveSettingsEffect))
        await Task.yield()
        XCTAssertEqual(
            mockUserDefaults.object(forKey: .hapticType) as? String,
            newType.rawValue,
            "UserDefaults が更新されていること"
        )

        // 3. 新しいプレビューを開始
        await store.receive(SettingsAction.startHapticPreview(newType)) {
            $0.isPreviewingHaptic = true
        }
        await Task.yield()
        XCTAssertEqual(mockHaptics.playCallCount, countAfterInitialStart + 1, "新しいプレビュー開始時に再生回数が増加すること")
        XCTAssertEqual(mockHaptics.lastPlayedHapticType, newType.wkHapticType, "正しい新しいハプティクスタイプが再生されること")

        // 新しいプレビューに関連する実行中のエフェクトをスキップ
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
            initialState: initialState,
            reducer: { SettingsReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                dependencies.hapticsService = mockHaptics
                dependencies.continuousClock = clock
            }
        )

        await store.send(SettingsAction.startHapticPreview(hapticType)) {
            $0.isPreviewingHaptic = true
        }
        await Task.yield()
        XCTAssertEqual(mockHaptics.playCallCount, 1, "最初のプレビューが開始されたこと")
        let countAfterStart = mockHaptics.playCallCount

        await clock.advance(by: .milliseconds(100))

        // 戻るボタンをタップ
        await store.send(SettingsAction.backButtonTapped)

        // backButtonTapped により stopHapticPreview を期待
        await store.receive(SettingsAction.stopHapticPreview) { $0.isPreviewingHaptic = false }

        // キャンセル後、時間が経過しても再生されないことを確認
        await clock.advance(by: .seconds(3))
        await Task.yield()
        XCTAssertEqual(mockHaptics.playCallCount, countAfterStart, "戻るボタンによるキャンセル後にハプティクスが再生されないこと")

        await store.finish()
    }
}
