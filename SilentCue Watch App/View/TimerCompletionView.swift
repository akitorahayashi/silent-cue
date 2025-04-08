import SwiftUI
import ComposableArchitecture

struct TimerCompletionView: View {
    let store: StoreOf<TimerReducer>
    let onDismiss: () -> Void
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                // 背景コンテナ（タップ可能領域）
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewStore.send(.dismissCompletionView)
                        onDismiss()
                    }
                
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
                    
                    Text("タップして閉じる")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                }
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