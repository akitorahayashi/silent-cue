import SwiftUI
import ComposableArchitecture

struct CountdownView: View {
    let store: StoreOf<TimerReducer>
    var onCancel: () -> Void
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
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
                }) {
                    Text("キャンセル")
                        .foregroundStyle(.primary)
                        .font(.system(size: 16))
                }
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
            .onChange(of: Date.now.timeIntervalSince1970, { oldValue, newValue in
                if viewStore.isRunning {
                    viewStore.send(.updateTimerDisplay)
                }
            })
        }
    }
} 
