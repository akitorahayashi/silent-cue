import SwiftUI
import ComposableArchitecture

struct TimerCompletionView: View {
    let store: StoreOf<TimerReducer>
    let onDismiss: () -> Void
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 16) {
                Spacer()
                
                // 現在時刻
                Text(SCTimeFormatter.formatToHoursAndMinutes(Date()))
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 8) {
                    // 開始時刻
                    if let startDate = viewStore.startDate {
                        HStack {
                            Text("開始時刻:")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(SCTimeFormatter.formatToHoursAndMinutes(startDate))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal)
                    }
                    
                    // 使用時間
                    HStack {
                        Text("タイマー時間:")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(viewStore.timerDurationMinutes)分")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
                .padding(.horizontal)
                
                Spacer()
                
                // 閉じるボタン（TimerStartViewの開始ボタンと同じデザイン）
                Button {
                    viewStore.send(.dismissCompletionView)
                    onDismiss()
                } label: {
                    Text("閉じる")
                        .font(.system(size: 18, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.secondary.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                // タイマーの音を再度再生（必要に応じて）
                if viewStore.completionDate == nil {
                    // 正常に完了していない場合は終了処理を呼ぶ
                    onDismiss()
                }
            }
        }
    }
} 