import ComposableArchitecture
import SwiftUI
import UserNotifications

@main
struct SilentCueWatchApp: App {
    // アプリ全体のストア
    let store: StoreOf<AppReducer>

    // 依存関係
    @Dependency(\.userDefaultsService) var userDefaultsService
    @Dependency(\.notificationService) var notificationService

    // バックグラウンド/フォアグラウンド遷移を監視
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var notificationDelegate = NotificationDelegate()
    @State private var showNotificationExplanationAlert = false

    init() {
        // Storeの初期化
        #if DEBUG
            if CommandLine.arguments.contains(SCAppEnvironment.LaunchArguments.uiTesting.rawValue) {
                // --- UIテスト: ストアの依存関係をオーバーライド ---
                print("--- UI Testing: Initializing Store with overridden dependencies (DEBUG build) ---")
                store = Store(initialState: AppState()) {
                    AppReducer()
                } withDependencies: { // このストアインスタンスに特化した依存関係をオーバーライド
                    // Use PreviewUserDefaultsService for UI tests
                    $0.userDefaultsService = PreviewUserDefaultsService()

                    // UIテストに必要な他のオーバーライドを追加 (必要に応じて Preview...Service を作成):
                    // $0.notificationService = PreviewNotificationService()
                    // $0.extendedRuntimeService = PreviewExtendedRuntimeService()
                    // $0.hapticsService = PreviewHapticsService()
                    // $0.continuousClock = ImmediateClock() // テストには即時クロックを使用
                }
            } else {
                // --- 通常のデバッグビルド: デフォルトの依存関係でストアを初期化 ---
                store = Store(initialState: AppState()) {
                    AppReducer() // 設定されたライブ/プレビュー/テスト値を使用
                }
            }
        #else
            // --- リリースビルド: デフォルトの依存関係でストアを初期化 ---
            store = Store(initialState: AppState()) {
                AppReducer() // ライブ値を使用
            }
        #endif
        // --- アプリレベルの依存関係 (@Dependency プロパティ) はデフォルトの解決を使用 ---
        // 上記のストアのオーバーライドは主にリデューサに影響します。
        // UIテスト中に isFirstLaunch のようなアプリメソッドがモックを必要とする場合、
        // 代替アプローチを検討するか、DEBUG で MockUserDefaultsManager がグローバルに動作することを確認してください。
    }

    var body: some Scene {
        WindowGroup {
            WithViewStore(store, observe: { $0 }, content: { viewStore in
                NavigationStack(path: viewStore.binding(
                    get: \.path,
                    send: AppAction.pathChanged
                )) {
                    SetTimerView(
                        store: store.scope(
                            state: \.timer,
                            action: AppAction.timer
                        ),
                        onSettingsButtonTapped: {
                            viewStore.send(.pushScreen(.settings))
                        },
                        onTimerStart: {
                            viewStore.send(.pushScreen(.countdown))
                        }
                    )
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        switch destination {
                            case .countdown:
                                CountdownView(
                                    store: store.scope(
                                        state: \.timer,
                                        action: AppAction.timer
                                    )
                                )
                            case .completion:
                                TimerCompletionView(
                                    store: store.scope(
                                        state: \.timer,
                                        action: AppAction.timer
                                    )
                                )
                                .navigationBarBackButtonHidden(true)
                                .accessibilityIdentifier(
                                    SCAccessibilityIdentifiers.TimerCompletionView
                                        .timerCompletionView.rawValue
                                )
                            case .settings:
                                SettingsView(
                                    store: store.scope(
                                        state: \.settings,
                                        action: AppAction.settings
                                    ),
                                    hapticsStore: store.scope(
                                        state: \.haptics,
                                        action: AppAction.haptics
                                    )
                                )
                            case .timerStart:
                                EmptyView()
                        }
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    viewStore.send(.scenePhaseChanged(newPhase))
                }
                .onAppear {
                    viewStore.send(.onAppear)
                    notificationDelegate.setStore(store)
                    checkNotificationStatus() // Check if this needs conditional execution
                }
                .alert("通知について", isPresented: $showNotificationExplanationAlert) {
                    Button("許可する") {
                        requestNotificationPermission()
                        markAsLaunched()
                    }
                    Button("許可しない", role: .cancel) {
                        markAsLaunched()
                    }
                } message: {
                    Text("\nタイマー完了時に通知を受け取りますか？\n\n通知を許可すると、アプリが閉じていても完了をお知らせします。\n")
                }
            })
        }
    }

    // 通知許可状態を確認し、必要に応じて説明アラートを表示
    private func checkNotificationStatus() {
        // 初回起動かどうかを確認
        if isFirstLaunch() {
            notificationService.checkAuthorizationStatus { isAuthorized in
                // まだ通知許可の選択をしていない場合
                if !isAuthorized {
                    // 説明アラートを表示
                    DispatchQueue.main.async {
                        showNotificationExplanationAlert = true
                    }
                } else {
                    // すでに許可されている場合も初回起動フラグを更新
                    markAsLaunched()
                }
            }
        }
    }

    // 初回起動かどうかを確認
    private func isFirstLaunch() -> Bool {
        // isFirstLaunchの値を取得、デフォルトはtrue
        userDefaultsService.object(forKey: .isFirstLaunch) as? Bool ?? true
    }

    // 初回起動フラグをfalseに設定
    private func markAsLaunched() {
        // userDefaultsService を使用するように変更
        userDefaultsService.set(false, forKey: .isFirstLaunch)
    }

    // 通知許可をリクエストする
    private func requestNotificationPermission() {
        notificationService.requestAuthorization { granted in
            print("通知許可: \(granted)")
        }
    }
}

/// 通知デリゲートクラス
class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    // アプリのストア
    private var store: Store<AppState, AppAction>?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // ストアを設定
    func setStore(_ store: Store<AppState, AppAction>) {
        self.store = store
    }

    // フォアグラウンドでも通知を表示
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // 通知アクションの処理
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 通知のカテゴリに基づいて処理
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        if categoryIdentifier == "TIMER_COMPLETED_CATEGORY" {
            // タイマー完了画面へ遷移
            handleTimerCompletionNotification()
        }

        completionHandler()
    }

    // タイマー完了通知の処理
    private func handleTimerCompletionNotification() {
        guard let store else { return }

        // タイマー完了アクションは不要 (Reducer内で処理される)
        // store.send(.timer(.backgroundTimerFinished))

        // 画面遷移も AppReducer が担当
        // store.send(.pushScreen(.completion))

        // 通知から起動した場合の特定の処理があればここに記述
        print("Timer completion notification received.")
        // 必要であれば、完了状態を再確認するアクションなどを送ることも検討
        // store.send(.timer(.updateTimerDisplay)) // 例: 状態を最新にする
    }
}
