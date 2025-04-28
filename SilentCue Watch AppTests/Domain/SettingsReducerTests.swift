import ComposableArchitecture
import SCMock
import SCShared
@testable import SilentCue_Watch_App
import WatchKit
import XCTest

@MainActor
final class SettingsReducerTests: XCTestCase {
    var store: TestStore<SettingsState, SettingsAction>!
    var mockUserDefaults: MockUserDefaultsManager!
    var mockHaptics: MockHapticsService!
    var clock: TestClock<Duration>!

    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaultsManager()
        mockHaptics = MockHapticsService()
        clock = TestClock<Duration>()
        store = TestStore(
            initialState: SettingsState(),
            reducer: { SettingsReducer() },
            withDependencies: { dependencies in
                dependencies.userDefaultsService = self.mockUserDefaults
                dependencies.hapticsService = self.mockHaptics
                dependencies.continuousClock = self.clock
            }
        )
    }

    override func tearDown() {
        store = nil
        mockUserDefaults = nil
        mockHaptics = nil
        clock = nil
        super.tearDown()
    }

    // UserDefaults に値が存在しない場合に設定をロードする
    func testLoadSettings_Default() async {
        mockUserDefaults.remove(forKey: .hapticType)
        await store.send(SettingsAction.loadSettings)
        await store.receive(SettingsAction.settingsLoaded(hapticType: HapticType.standard)) {
            $0.selectedHapticType = HapticType.standard
            $0.isSettingsLoaded = true
        }
        await store.finish()
    }

    // UserDefaults に値が存在する場合に設定をロードする
    func testLoadSettings_ExistingValue() async {
        mockUserDefaults.set(HapticType.strong.rawValue, forKey: .hapticType)
        await store.send(SettingsAction.loadSettings)
        await store.receive(SettingsAction.settingsLoaded(hapticType: HapticType.strong)) {
            $0.selectedHapticType = HapticType.strong
            $0.isSettingsLoaded = true
        }
        await store.finish()
    }

    // ハプティクスタイプを選択すると保存がトリガーされ、プレビューが開始される
    func testSelectHapticType_TriggersSaveAndStartsPreview() async {
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

        await store.skipInFlightEffects()
        await store.finish()
    }

    // ハプティクスプレビューのティックとタイムアウトのフロー
    func testHapticPreview_FlowWithTicksAndTimeout() async {
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

        if expectedTickCount > 0 {
            for tickIndex in 1 ... expectedTickCount {
                await clock.advance(by: .seconds(interval))
                await store.receive(SettingsAction.hapticPreviewTick)
                await Task.yield()
                XCTAssertEqual(mockHaptics.playCallCount, tickIndex + 1, "ティック \(tickIndex) でハプティクスが再生されること")
                XCTAssertTrue(store.state.isPreviewingHaptic)
            }
        }

        let timeElapsed = Double(expectedTickCount) * interval
        let remainingNanoseconds = previewTimeout.components
            .attoseconds + (previewTimeout.components.seconds * 1_000_000_000_000_000_000) -
            Int64(timeElapsed * 1_000_000_000_000_000_000)
        let remainingDuration = Duration(secondsComponent: 0, attosecondsComponent: remainingNanoseconds)

        await clock.advance(by: remainingDuration + .nanoseconds(1))

        await store.receive(SettingsAction.stopHapticPreview) {
            $0.isPreviewingHaptic = false
        }
        await Task.yield()
        XCTAssertEqual(mockHaptics.playCallCount, expectedTotalPlays, "タイムアウト後のハプティクス再生回数が合計再生回数と一致すること")

        await clock.advance(by: .seconds(interval * 2))
        await Task.yield()
        XCTAssertEqual(mockHaptics.playCallCount, expectedTotalPlays, "タイムアウト停止後にハプティクスが再生されないこと")

        await store.finish()
    }

    // 新しいハプティクスタイプを選択すると、進行中のプレビューがキャンセルされ、新しいプレビューが開始される
    func testSelectHapticType_CancelsOngoingPreviewAndStartsNew() async {
        let initialType = HapticType.standard
        store = TestStore(
            initialState: SettingsState(selectedHapticType: initialType),
            reducer: { SettingsReducer() },
            withDependencies: { $0 = self.store.dependencies }
        )

        await store.send(SettingsAction.startHapticPreview(initialType)) {
            $0.isPreviewingHaptic = true
        }
        await Task.yield()
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
        XCTAssertEqual(
            mockUserDefaults.object(forKey: .hapticType) as? String,
            newType.rawValue,
            "UserDefaults が更新されていること"
        )

        await store.receive(SettingsAction.startHapticPreview(newType)) {
            $0.isPreviewingHaptic = true
        }
        await Task.yield()
        XCTAssertEqual(mockHaptics.playCallCount, countAfterInitialStart + 1, "新しいプレビュー開始時に再生回数が増加すること")
        XCTAssertEqual(mockHaptics.lastPlayedHapticType, newType.wkHapticType, "正しい新しいハプティクスタイプが再生されること")

        await store.skipInFlightEffects()
        await store.finish()
    }

    // 戻るボタンをタップすると進行中のプレビューがキャンセルされる
    func testBackButtonTapped_CancelsOngoingPreview() async {
        let hapticType = HapticType.standard
        store = TestStore(
            initialState: SettingsState(selectedHapticType: hapticType),
            reducer: { SettingsReducer() },
            withDependencies: { $0 = self.store.dependencies }
        )

        await store.send(SettingsAction.startHapticPreview(hapticType)) {
            $0.isPreviewingHaptic = true
        }
        await Task.yield()
        let countAfterStart = mockHaptics.playCallCount

        await clock.advance(by: .milliseconds(100))

        await store.send(SettingsAction.backButtonTapped)

        await store.receive(SettingsAction.stopHapticPreview) {
            $0.isPreviewingHaptic = false
        }
        await Task.yield()
        XCTAssertEqual(mockHaptics.playCallCount, countAfterStart, "戻るタップ後にハプティクス再生回数が増加しないこと")

        await store.finish()
    }
}
