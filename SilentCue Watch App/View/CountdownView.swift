import SwiftUI
import ComposableArchitecture

struct CountdownView: View {
    let store: StoreOf<TimerReducer>
    var onCancel: () -> Void
    var onTimerFinished: () -> Void
    
    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            VStack {
                Spacer()
                
                Text(viewStore.remainingSeconds >= 3600 ? "時間  :  分" : "分  :  秒")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    
                Text(viewStore.displayTime)
                    .font(.system(size: 40, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: {
                    viewStore.send(.cancelTimer)
                    onCancel()
                }, label: {
                    Text("キャンセル")
                        .foregroundStyle(.primary)
                        .font(.system(size: 16))
                })
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                viewStore.send(.loadSettings)
                if viewStore.isRunning {
                    viewStore.send(.updateTimerDisplay)
                }
            }
            .onChange(of: Date.now.timeIntervalSince1970) { _, _ in
                if viewStore.isRunning {
                    viewStore.send(.updateTimerDisplay)
                }
            }
            .onChange(of: viewStore.isRunning) { oldValue, newValue in
                // タイマーが完了した場合（実行中→停止、かつ完了日時が設定されている）
                if oldValue && !newValue && viewStore.completionDate != nil {
                    // 完了画面への遷移を伝える
                    onTimerFinished()
                }
            }
        })
    }
} 
