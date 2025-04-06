import SwiftUI
import ComposableArchitecture

struct CountdownView: View {
    let store: StoreOf<CountdownFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Spacer()
                
                Text(viewStore.displayTime)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(viewStore.remainingSeconds < 60 ? .red : .primary)
                    .padding()
                
                Spacer()
                
                Button("Cancel") {
                    viewStore.send(.cancelButtonTapped)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.bottom)
            }
            .navigationTitle("カウントダウン")
            .navigationBarBackButtonHidden(true) // 戻るボタンを非表示（キャンセルボタンのみを使用）
        }
    }
} 