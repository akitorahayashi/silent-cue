import ComposableArchitecture
import SwiftUI

struct TimerCompletionView: View {
    let store: StoreOf<TimerReducer>
    // onDismissクロージャはAppReducerに処理を移譲するため不要

    // アニメーション用の状態変数
    @State private var appearAnimation = false

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            ZStack {
                ScrollView {
                    VStack {
                        CloseButtonView(
                            action: {
                                // TimerReducerにdismissアクションを送信するだけ
                                viewStore.send(.dismissCompletionView)
                            },
                            appearAnimation: $appearAnimation
                        )

                        Spacer(minLength: 16)

                        CompletionDetailsView(
                            completionDate: viewStore.completionDate,
                            appearAnimation: $appearAnimation
                        )

                        Spacer(minLength: 16)

                        TimerSummaryView(
                            startDate: viewStore.startDate,
                            timerDurationMinutes: viewStore.timerDurationMinutes,
                            appearAnimation: $appearAnimation
                        )

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

                // タイマー完了状態の確認ロジックは不要 (Reducerが管理)
            }
        })
    }
}
