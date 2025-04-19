import ComposableArchitecture
@testable import SilentCue_Watch_App
import WatchKit
import XCTest

@MainActor
final class SettingsReducerTests: XCTestCase {
    // SettingsReducer 用の TestStore ヘルパー
    private func makeTestStore(
        initialState: SettingsState = SettingsState(),
        mockUserDefaults: MockUserDefaultsManager = MockUserDefaultsManager(),
        mockHaptics: MockHapticsService = MockHapticsService(),
        clock: TestClock<Duration> = TestClock()
    ) -> (TestStore<SettingsState, SettingsAction>, MockUserDefaultsManager, MockHapticsService, TestClock<Duration>) {
        let store = TestStore(
            initialState: initialState,
            reducer: { SettingsReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = mockUserDefaults
                dependencies.hapticsService = mockHaptics
                dependencies.continuousClock = clock
            }
        )
        return (store, mockUserDefaults, mockHaptics, clock)
    }

    // テスト: UserDefaults に値が存在しない場合に設定をロードする
    func testLoadSettings_Default() async {
        let (store, mockUserDefaults, _, _) = makeTestStore()
        mockUserDefaults.remove(forKey: .hapticType)
        await store.send(SettingsAction.loadSettings)
        await store.receive(SettingsAction.settingsLoaded(hapticType: .standard)) {
            $0.selectedHapticType = .standard
            $0.isSettingsLoaded = true
        }
        await store.finish()
    }

    // テスト: UserDefaults に値が存在する場合に設定をロードする
    func testLoadSettings_ExistingValue() async {
        let mockUserDefaults = MockUserDefaultsManager()
        mockUserDefaults.set(HapticType.strong.rawValue, forKey: .hapticType)
        let (store, _, _, _) = makeTestStore(mockUserDefaults: mockUserDefaults)
        await store.send(SettingsAction.loadSettings)
        await store.receive(SettingsAction.settingsLoaded(hapticType: .strong)) {
            $0.selectedHapticType = .strong
            $0.isSettingsLoaded = true
        }
        await store.finish()
    }

    // テスト: ハプティクスタイプを選択すると保存がトリガーされ、プレビューが開始される
    func testSelectHapticType_TriggersSaveAndStartsPreview() async {
        let mockUserDefaults = MockUserDefaultsManager()
        let mockHaptics = MockHapticsService()
        let clock = TestClock()
        let (store, _, _, _) = makeTestStore(mockUserDefaults: mockUserDefaults, mockHaptics: mockHaptics, clock: clock)
        let selectedType = HapticType.weak

        // ハプティクスタイプを選択するアクションを送信
        await store.send(SettingsAction.selectHapticType(selectedType)) {
            $0.selectedHapticType = selectedType // 即時の状態更新を期待
        }

        // 保存エフェクトアクションを期待
        await store.receive(SettingsAction.internal(.saveSettingsEffect))
        // 保存エフェクト（短時間で完了する可能性あり）の実行を許可
        await Task.yield()
        XCTAssertEqual(
            mockUserDefaults.object(forKey: .hapticType) as? String,
            selectedType.rawValue,
            "UserDefaults が更新されていること"
        )

        // プレビューが開始されることを期待
        await store.receive(SettingsAction.startHapticPreview(selectedType)) {
            $0.isPreviewingHaptic = true // 状態変化を期待
        }

        // 即時のハプティクス再生をアサート
        XCTAssertEqual(mockHaptics.playCallCount, 1, "開始時にハプティクスが1回再生されること")
        XCTAssertEqual(mockHaptics.lastPlayedHapticType, selectedType.wkHapticType, "正しいハプティクスタイプが再生されること")

        // このテストはプレビューの *開始* に焦点を当てているため、実行中のタイマー/タイムアウトエフェクトはスキップする
        await store.skipInFlightEffects()
        await store.finish()
    }

    // テスト: ハプティクスプレビューのティックとタイムアウトのフロー
    func testHapticPreview_FlowWithTicksAndTimeout() async {
        let clock = TestClock()
        let mockHaptics = MockHapticsService()
        // 既知の間隔を持つタイプを使用
        let hapticType = HapticType.standard // interval = 0.5s
        let interval = hapticType.interval
        let previewTimeout: Duration = .seconds(3) // タイムアウトはリデューサー内でハードコードされている

        // 期待される再生回数を計算: 1回の初期再生 + 'interval'秒ごとのティック（'previewTimeout'まで）
        // Duration から合計秒数を取得（除算）
        let previewTimeoutSeconds = previewTimeout / .seconds(1)
        // 正しい計算: ティック数はタイムアウト *前* に完了した完全な間隔の数
        // 浮動小数点数と境界条件を処理するために小さなイプシロンを使用
        let expectedTickCount =
            Int(floor(
                (previewTimeoutSeconds - 0.0001) /
                    interval
            )) // floor((3.0 - 0.0001) / 0.5) = floor(5.9998) = 5 ティック
        let expectedTotalPlays = expectedTickCount + 1 // 1回の初期再生 + 5回のティック = 合計6回の再生

        let (store, _, _, _) = makeTestStore(mockHaptics: mockHaptics, clock: clock)

        // プレビューを開始
        await store.send(SettingsAction.startHapticPreview(hapticType)) {
            $0.isPreviewingHaptic = true
        }
        XCTAssertEqual(mockHaptics.playCallCount, 1, "初期ハプティクスが即時に再生されること")

        // ティックをシミュレート（修正されたカウントを使用）
        if expectedTickCount > 0 {
            for i in 1 ... expectedTickCount {
                await clock.advance(by: .seconds(interval))
                await store.receive(.hapticPreviewTick)
                XCTAssertEqual(mockHaptics.playCallCount, i + 1, "ティック \(i) でハプティクスが再生されること")
                XCTAssertTrue(store.state.isPreviewingHaptic, "ティック \(i) 後もプレビュー中であること")
            }
        } // else: interval > timeout の場合、ティックは期待されない

        // タイムアウトをトリガーするためにクロックを進める
        // これまでの経過時間 = expectedTickCount * interval
        let timeElapsed = Double(expectedTickCount) * interval
        let remainingTime = previewTimeoutSeconds - timeElapsed
        // remainingTime がゼロまたは負の場合（精度のため）に、少なくともわずかな量を進めることを保証
        let advanceDuration = max(0.001, remainingTime)
        await clock.advance(by: .seconds(advanceDuration))

        // タイムアウトによる停止アクションを受信
        await store.receive(SettingsAction.stopHapticPreview) {
            $0.isPreviewingHaptic = false // プレビューが停止すること
        }
        XCTAssertEqual(mockHaptics.playCallCount, expectedTotalPlays, "タイムアウト後のハプティクス再生回数が合計再生回数と一致すること")

        // さらに時間を進めて、これ以上ティックや再生が発生しないことを確認
        await clock.advance(by: .seconds(interval * 2))
        XCTAssertEqual(mockHaptics.playCallCount, expectedTotalPlays, "タイムアウト停止後にハプティクスが再生されないこと")

        await store.finish() // 全てのエフェクト（タイマー、タイムアウト）が完了/キャンセルされたことを保証
    }

    // テスト: 新しいハプティクスタイプを選択すると、進行中のプレビューがキャンセルされ、新しいプレビューが開始される
    func testSelectHapticType_CancelsOngoingPreviewAndStartsNew() async {
        let clock = TestClock()
        let mockHaptics = MockHapticsService()
        let initialType = HapticType.standard // interval 0.5
        let newType = HapticType.strong // interval 0.3
        var initialState = SettingsState(selectedHapticType: initialType)
        let (store, _, _, _) = makeTestStore(initialState: initialState, mockHaptics: mockHaptics, clock: clock)

        // 最初のプレビューを開始
        await store.send(SettingsAction.startHapticPreview(initialType)) { $0.isPreviewingHaptic = true }
        XCTAssertEqual(mockHaptics.playCallCount, 1, "最初のプレビューが開始されたこと")
        let countAfterInitialStart = mockHaptics.playCallCount

        // 時間をわずかに進めるが、最初の間隔より短く、まだティックが発生しないようにする
        await clock.advance(by: .milliseconds(100))

        // 新しいハプティクスタイプを選択するアクションを送信
        await store.send(SettingsAction.selectHapticType(newType)) {
            $0.selectedHapticType = newType // 即時の状態更新を期待
        }

        // 古いプレビューが即座に停止されることを期待（キャンセルエフェクト）
        await store.receive(SettingsAction.stopHapticPreview) {
            $0.isPreviewingHaptic = false // 状態が非プレビューに更新されること
        }

        // 保存エフェクトアクションを期待
        await store.receive(SettingsAction.internal(.saveSettingsEffect))
        await Task.yield() // 保存エフェクトの実行を許可

        // 新しいプレビューが開始されることを期待
        await store.receive(SettingsAction.startHapticPreview(newType)) {
            $0.isPreviewingHaptic = true // 状態がプレビュー中に戻ること
        }
        // 新しいプレビューが開始されるため、再生回数が増加することを期待
        XCTAssertEqual(mockHaptics.playCallCount, countAfterInitialStart + 1, "新しいプレビュー開始時に再生回数が増加すること")
        XCTAssertEqual(mockHaptics.lastPlayedHapticType, newType.wkHapticType, "正しい新しいハプティクスタイプが再生されること")

        // 新しいプレビューエフェクトが実行中。キャンセル/再起動をテストしたので、これらはスキップする
        await store.skipInFlightEffects()
        await store.finish()
    }

    // テスト: 戻るボタンをタップすると進行中のプレビューがキャンセルされる
    func testBackButtonTapped_CancelsOngoingPreview() async {
        let clock = TestClock()
        let mockHaptics = MockHapticsService()
        let hapticType = HapticType.standard // interval 0.5
        var initialState = SettingsState(selectedHapticType: hapticType)
        let (store, _, _, _) = makeTestStore(initialState: initialState, mockHaptics: mockHaptics, clock: clock)

        // プレビューを開始
        await store.send(SettingsAction.startHapticPreview(hapticType)) { $0.isPreviewingHaptic = true }
        XCTAssertEqual(mockHaptics.playCallCount, 1, "最初のプレビューが開始されたこと")
        let countAfterStart = mockHaptics.playCallCount

        // 時間をわずかに進める（間隔より短く）
        await clock.advance(by: .milliseconds(100))

        // 戻るボタンタップアクションを送信
        await store.send(SettingsAction.backButtonTapped)

        // プレビューが即座に停止されることを期待（キャンセルエフェクト）
        await store.receive(SettingsAction.stopHapticPreview) { $0.isPreviewingHaptic = false }

        // クロックを大幅に進めて、これ以上再生が発生しないことを確認
        await clock.advance(by: .seconds(3))
        XCTAssertEqual(mockHaptics.playCallCount, countAfterStart, "戻るボタンによるキャンセル後にハプティクスが再生されないこと")

        // finish() はキャンセルされたタイマー/タイムアウトエフェクトが本当に消えたことを保証する
        await store.finish()
    }
}
