import SwiftUI
import ComposableArchitecture

struct CountdownView: View {
    let store: StoreOf<TimerReducer>
    var onCancel: () -> Void
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Spacer()
                
                Text(viewStore.displayTime)
                    .font(.system(size: 40, weight: .semibold, design: .monospaced))
                    .foregroundStyle(viewStore.remainingSeconds < 60 ? .red : .primary)
                    .padding()
                
                Spacer()
                
                Button(action: {
                    viewStore.send(.cancelTimer)
                    onCancel()
                }) {
                    Text("キャンセル")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
            }
            .navigationTitle("カウントダウン")
            .navigationBarBackButtonHidden(true)
        }
    }
} 