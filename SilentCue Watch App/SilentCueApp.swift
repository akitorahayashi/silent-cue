import ComposableArchitecture
import SwiftUI
import UserNotifications

@main
struct SilentCueWatchApp: App {
    // AppScreen enum は NavigationDestination.swift に移動

    // アプリ全体のストア
    let store = Store(initialState: AppState()) {
        AppReducer()
    }

    // @State private var navPath = NavigationPath() // AppStateで管理

    // バックグラウンド/フォアグラウンド遷移を監視
    @Environment(\.scenePhase) private var scenePhase

    // アプリデリゲート
    @StateObject private var notificationDelegate = NotificationDelegate()

    // 通知説明アラート表示フラグ
    @State private var showNotificationExplanationAlert = false

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
                    checkNotificationStatus() // 通常フローでのみ実行したい場合、条件分岐が必要かも
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
            NotificationManager.shared.checkAuthorizationStatus { isAuthorized in
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
        UserDefaultsManager.shared.object(forKey: .isFirstLaunch) as? Bool ?? true
    }

    // 初回起動フラグをfalseに設定
    private func markAsLaunched() {
        UserDefaultsManager.shared.set(false, forKey: .isFirstLaunch)
    }

    // 通知許可をリクエストする
    private func requestNotificationPermission() {
        NotificationManager.shared.requestAuthorization { granted in
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

        // タイマー完了アクションを送信
        store.send(.timer(.backgroundTimerFinished))

        // タイマー完了画面へ遷移
        store.send(.pushScreen(.completion))

        // 通知から起動した場合は振動を開始しない
    }
}
