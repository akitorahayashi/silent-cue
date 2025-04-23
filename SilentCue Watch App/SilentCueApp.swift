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
        // Storeの初期化を行う
        #if DEBUG
            if CommandLine.arguments.contains(SCAppEnvironment.LaunchArguments.uiTesting.rawValue) {
                // --- UIテスト: ストアの依存関係をオーバーライド ---
                print("--- UI Testing: Initializing Store with overridden dependencies (DEBUG build) ---")
                store = Store(initialState: AppState()) {
                    AppReducer()
                } withDependencies: { dependencies in
                    // UIテスト用に、依存関係をプレビュー用の実装に差し替える
                    // Preview*Service は #if DEBUG でアプリ本体ターゲットに存在するので直接参照可能
                    dependencies.userDefaultsService = PreviewUserDefaultsService()
                    dependencies.notificationService = PreviewNotificationService() // 直接 Preview実装をインスタンス化
                    dependencies.extendedRuntimeService = PreviewExtendedRuntimeService() // 直接 Preview実装をインスタンス化
                    dependencies.hapticsService = PreviewHapticsService() // 直接 Preview実装をインスタンス化
                    dependencies.continuousClock = ImmediateClock() // テストには即時クロックを使用
                }
            } else {
                // --- 通常のデバッグビルド: デフォルトの依存関係でストアを初期化 ---
                store = Store(initialState: AppState()) {
                    AppReducer()
                }
            }
        #else
            // --- リリースビルド: デフォルトの依存関係でストアを初期化 ---
            store = Store(initialState: AppState()) {
                AppReducer()
            }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            // WithViewStore を使用して状態を監視し、アクションを送信する
            WithViewStore(store, observe: { $0 }, content: { viewStore in
                NavigationStack(path: viewStore.binding(
                    get: \.path,
                    send: AppAction.pathChanged // 送信には AppAction を使用
                )) {
                    SetTimerView(
                        store: store.scope(state: \.timer, action: \.timer),
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
                                    // 新しいキーパス構文を使用
                                    store: store.scope(state: \.timer, action: \.timer)
                                )
                            case .completion:
                                TimerCompletionView(
                                    // 新しいキーパス構文を使用
                                    store: store.scope(state: \.timer, action: \.timer)
                                )
                                .navigationBarBackButtonHidden(true)
                                .accessibilityIdentifier(
                                    SCAccessibilityIdentifiers.TimerCompletionView
                                        .timerCompletionView.rawValue
                                )
                            case .settings:
                                SettingsView(
                                    // 新しいキーパス構文を使用
                                    store: store.scope(state: \.settings, action: \.settings),
                                    hapticsStore: store.scope(
                                        state: \.haptics,
                                        action: \.haptics
                                    )
                                )
                            case .timerStart: // 到達しない想定
                                EmptyView()
                        }
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    viewStore.send(.scenePhaseChanged(newPhase))
                }
                .onAppear {
                    viewStore.send(.onAppear)
                    notificationDelegate.setStore(store) // メインストアを渡す
                    checkNotificationStatus()
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
        // guard let store else { return } // 未使用のguardを削除

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
