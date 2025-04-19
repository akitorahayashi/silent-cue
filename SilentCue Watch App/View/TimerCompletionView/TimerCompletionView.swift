import ComposableArchitecture
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
        // Use the injected dependency
        notificationService.checkAuthorizationStatus { isAuthorized in
            isNotificationAuthorized = isAuthorized
        }
    }

    // 通知許可をリクエスト
    private func requestNotificationAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        // Use the injected dependency
        notificationService.requestAuthorization { granted in
            isNotificationAuthorized = granted
            completion(granted)
        }
    }
}

// MARK: - Preview

#Preview {
    TimerCompletionView(
        store: Store(
            // TimerStateを直接初期化 (ビューに必要な最小限の状態を設定)
            initialState: TimerReducer.State(
                now: Date(), // TimerStateのinitに必要
                isRunning: false,
                // TimerCompletionView が表示に使う completionDate を設定
                completionDate: Date()
                // 他のプロパティ(selectedMinutesなど)はTimerStateのデフォルトを使用
            )
        ) {
            // TimerReducerを直接使用
            TimerReducer()
                // 依存関係を直接Reducerに注入
                .dependency(\.notificationService, PreviewNotificationService())
            // ★ AppStateやスコープは使用しない
        }
    )
}
