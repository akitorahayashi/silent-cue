import ComposableArchitecture
import SCShared
import SwiftUI
import UserNotifications

#if DEBUG
    import SCPreview
#endif

@main
struct SilentCueWatchApp: App {
    // アプリ全体のストア
    let store: StoreOf<CoordinatorReducer>

    // バックグラウンド/フォアグラウンド遷移を監視
    @Environment(\.scenePhase) private var scenePhase

    // 通知デリゲート (StateObjectではなく通常のプロパティにする)
    let notificationDelegate: NotificationDelegate

    init() {
        #if DEBUG
            // --- UIテストの場合のみ、依存関係をオーバーライドしてストアを初期化 ---
            if CommandLine.arguments.contains(SCAppEnvironment.LaunchArguments.uiTesting.rawValue) {
                print("--- UI Testing: Initializing Store with overridden dependencies (DEBUG build) ---")
                store = Store(initialState: CoordinatorState()) {
                    CoordinatorReducer()
                } withDependencies: { dependencies in
                    dependencies.userDefaultsService = PreviewUserDefaultsService()
                    dependencies.notificationService = PreviewNotificationService()
                    dependencies.extendedRuntimeService = PreviewExtendedRuntimeService()
                    dependencies.hapticsService = PreviewHapticsService()
                }
            } else {
                // --- 通常のビルドまたはUIテストでない場合、デフォルトの依存関係でストアを初期化 ---
                store = Store(initialState: CoordinatorState()) {
                    CoordinatorReducer()
                }
            }
        #else
            // --- リリースビルドの場合、デフォルトの依存関係でストアを初期化 ---
            store = Store(initialState: CoordinatorState()) {
                CoordinatorReducer()
            }
        #endif

        // NotificationDelegateを初期化し、ストアを渡す
        notificationDelegate = NotificationDelegate(store: store)
        // NotificationCenterのデリゲートを設定
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            // WithViewStore を使用して状態を監視し、アクションを送信する
            WithViewStore(store, observe: { $0 }, content: { viewStore in
                NavigationStack(path: viewStore.binding(
                    get: \.path,
                    send: CoordinatorAction.pathChanged
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
                                    store: store.scope(state: \.timer, action: \.timer)
                                )
                            case .completion:
                                TimerCompletionView(
                                    store: store.scope(state: \.timer, action: \.timer)
                                )
                                .navigationBarBackButtonHidden(true)
                            case .settings:
                                SettingsView(
                                    store: store.scope(state: \.settings, action: \.settings),
                                    hapticsStore: store.scope(
                                        state: \.haptics,
                                        action: \.haptics
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
                }
                .alert("通知について", isPresented: viewStore.binding(
                    get: \.shouldShowNotificationAlert,
                    send: { .setNotificationAlert(isPresented: $0) }
                )) {
                    Button("許可する") {
                        viewStore.send(.notificationAlertPermitTapped)
                    }
                    Button("許可しない", role: .cancel) {
                        viewStore.send(.notificationAlertDenyTapped)
                    }
                } message: {
                    Text("\nタイマー完了時に通知を受け取りますか？\n\n通知を許可すると、アプリが閉じていても完了をお知らせします。\n")
                }
            })
        }
    }
}

/// 通知デリゲートクラス
class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    // アプリのストア (letに変更し、初期化時に受け取る)
    private let store: Store<CoordinatorState, CoordinatorAction>

    // イニシャライザでストアを受け取る
    init(store: Store<CoordinatorState, CoordinatorAction>) {
        self.store = store
        super.init()
        // UNUserNotificationCenter.current().delegate = self // デリゲート設定はAppのinitで行う
    }

    // ストアを設定するメソッドは不要になった
    // func setStore(_ store: Store<CoordinatorState, CoordinatorAction>) {
    //     self.store = store
    // }

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
        print("Timer completion notification received.")
        // 必要に応じてストアにアクションを送信する
        // ViewStore(self.store, observe: { $0 }).send(.someAction)
    }
}
