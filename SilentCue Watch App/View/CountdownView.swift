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
                    .foregroundStyle(.primary)
                    .padding(.top)
                
                Text("分:秒")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
                
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
        }
    }
} 
