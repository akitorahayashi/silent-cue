import ComposableArchitecture
import SCPreview
import SwiftUI
import UserNotifications

struct TimerCompletionView: View {
    let store: StoreOf<TimerReducer>
    // onDismissクロージャはAppReducerに処理を移譲するため不要
    @Dependency(\.notificationService) var notificationService

    // アニメーション用の状態変数
    @State private var appearAnimation = false

    // 通知許可状態
    @State private var isNotificationAuthorized = false
    @State private var showingNotificationInstructionAlert = false

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            ZStack {
                ScrollView {
                    VStack {
                        NotifyEndTimeView(
                            completionDate: viewStore.completionDate,
                            appearAnimation: $appearAnimation
                        )

                        Spacer(minLength: 13)

                        CloseTimeCompletionViewButton(
                            action: {
                                // TimerReducerにdismissアクションを送信するだけ
                                viewStore.send(.dismissCompletionView)
                            },
                            appearAnimation: $appearAnimation
                        )

                        Spacer(minLength: 18)

                        TimerSummaryView(
                            startDate: viewStore.startDate,
                            timerDurationMinutes: viewStore.timerDurationMinutes,
                            appearAnimation: $appearAnimation
                        )

                        // 通知が許可されていない場合は通知許可ボタンを表示
                        if !isNotificationAuthorized {
                            Spacer(minLength: 20)

                            Button {
                                // まず通知設定方法のアラートを表示
                                showingNotificationInstructionAlert = true

                                // 同時に通知許可もリクエスト（初回のみ表示される）
                                requestNotificationAuthorization()
                            } label: {
                                HStack {
                                    Image(systemName: "bell.badge")
                                    Text("通知を有効にする")
                                }
                                .font(.system(size: 14))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .opacity(appearAnimation ? 1.0 : 0.0)
                            .animation(.easeIn.delay(0.7), value: appearAnimation)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                        }

                        // 下部のスペースを調整
                        Spacer(minLength: 20)
                    }
                    .padding(.bottom)
                }

                // フローティングの閉じるボタンを削除
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                // アニメーションを開始
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appearAnimation = true
                }

                // 通知許可状態を確認
                checkNotificationAuthorizationStatus()
            }
            .alert("通知設定の変更方法", isPresented: $showingNotificationInstructionAlert) {
                Button("OK") {}
            } message: {
                Text("\n1. ホーム画面でアプリのアイコンを長押し\n\n2. 「アプリを削除」を選択\n\n3. アプリを再インストール\n\n4. 初回起動時に通知を許可\n")
                    .multilineTextAlignment(.leading)
            }
        })
    }

    // 通知許可状態を確認
    private func checkNotificationAuthorizationStatus() {
        Task {
            let status = await notificationService.getAuthorizationStatus()
            isNotificationAuthorized =
                (status == .authorized || status == .provisional) // Update based on actual status check logic
        }
    }

    // 通知許可をリクエスト (async/awaitを使用)
    private func requestNotificationAuthorization() {
        Task {
            let granted = await notificationService.requestAuthorization()
            // UI更新はメインスレッドで行う
            await MainActor.run {
                isNotificationAuthorized = granted
            }
            // completion ハンドラは不要になったため削除
        }
    }
}

// #if DEBUG
//    #Preview {
//        // プレビュー用の依存関係インスタンスを作成
//        let previewNotificationServiceAuthorized = PreviewNotificationService()
//        previewNotificationServiceAuthorized.authorizationStatus = .authorized // 状態を設定
//
//        TimerCompletionView(
//            store: Store(
//                // TimerState を引数なしで初期化し、必要なプロパティを設定
//                initialState: TimerState(timerDurationMinutes: 5, startDate: Date() - 300, completionDate: Date())
//            ) {
//                TimerReducer()
//            } withDependencies: { dependencies in
//                dependencies.notificationService = previewNotificationServiceAuthorized // 設定済みのインスタンスを使用
//                dependencies.userDefaultsService = PreviewUserDefaultsService()
//                dependencies.extendedRuntimeService = PreviewExtendedRuntimeService()
//                dependencies.hapticsService = PreviewHapticsService()
//                dependencies.continuousClock = ImmediateClock()
//            }
//        )
//    }
//
//    #Preview("Notification Not Authorized") {
//        // プレビュー用の依存関係インスタンスを作成
//        let previewNotificationServiceDenied = PreviewNotificationService()
//        previewNotificationServiceDenied.authorizationStatus = .denied // 状態を設定
//
//        TimerCompletionView(
//            store: Store(
//                // TimerState を引数なしで初期化し、必要なプロパティを設定
//                initialState: TimerState(timerDurationMinutes: 10, startDate: Date() - 600, completionDate: Date())
//            ) {
//                TimerReducer()
//            } withDependencies: { dependencies in
//                dependencies.notificationService = previewNotificationServiceDenied // 設定済みのインスタンスを使用
//                dependencies.userDefaultsService = PreviewUserDefaultsService()
//                dependencies.extendedRuntimeService = PreviewExtendedRuntimeService()
//                dependencies.hapticsService = PreviewHapticsService()
//                dependencies.continuousClock = ImmediateClock()
//            }
//        )
//    }
// #endif
