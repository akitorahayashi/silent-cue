import ComposableArchitecture
import SCPreview
import SCShared
import SwiftUI

struct TimerCompletionView: View {
    let store: StoreOf<TimerReducer>

    // アニメーション用の状態変数
    @State private var appearAnimation = false

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            ZStack {
                ScrollView {
                    VStack {
                        NotifyEndTimeView(
                            completionDate: viewStore.completionDate,
                            appearAnimation: $appearAnimation
                        )
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(SCAccessibilityIdentifiers.TimerCompletionView.notifyEndTimeSection.rawValue)

                        Spacer(minLength: 13)

                        CloseTimeCompletionViewButton(
                            action: {
                                viewStore.send(.dismissCompletionView)
                            },
                            appearAnimation: $appearAnimation
                        )
                        .accessibilityIdentifier(SCAccessibilityIdentifiers.TimerCompletionView.closeTimeCompletionViewButton.rawValue)

                        Spacer(minLength: 18)

                        TimerSummaryView(
                            startDate: viewStore.startDate,
                            timerDurationMinutes: viewStore.timerDurationMinutes,
                            appearAnimation: $appearAnimation
                        )
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(SCAccessibilityIdentifiers.TimerCompletionView.timerSummarySection.rawValue)

                        // 下部のスペースを調整
                        Spacer(minLength: 20)
                    }
                    .padding(.bottom)
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                // アニメーションを開始
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appearAnimation = true
                }
            }
        })
    }
}

#if DEBUG
   #Preview {
       // プレビュー用の依存関係インスタンスを作成
       TimerCompletionView(
           store: Store(
               initialState: TimerState(startDate: Date() - 300, completionDate: Date())
           ) {
               TimerReducer()
           } withDependencies: { dependencies in
               dependencies.userDefaultsService = PreviewUserDefaultsService()
               dependencies.extendedRuntimeService = PreviewExtendedRuntimeService()
               dependencies.hapticsService = PreviewHapticsService()
               dependencies.continuousClock = ImmediateClock()
           }
       )
   }
#endif
