import ComposableArchitecture
import SwiftUI

struct TimerCompletionView: View {
    let store: StoreOf<TimerReducer>
    let onDismiss: () -> Void

    // アニメーション用の状態変数
    @State private var appearAnimation = false

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            ZStack {
                ScrollView {
                    VStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewStore.send(.dismissCompletionView)
                                onDismiss()
                            }
                        }, label: {
                            Text("閉じる")
                                .font(.system(size: 16, weight: .medium))
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
                        })
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .opacity(appearAnimation ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4), value: appearAnimation)

                        Spacer(minLength: 16)

                        // ベルアイコンと終了時刻を中央に配置
                        VStack {
                            Image(systemName: "bell.and.waves.left.and.right")
                                .font(.system(size: 40))
                                .foregroundStyle(.primary)

                            Spacer(minLength: 8)

                            // キャプション
                            Text("終了時刻")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)

                            if let completionDate = viewStore.completionDate {
                                Text(SCTimeFormatter.formatToHoursAndMinutes(completionDate))
                                    .font(.system(size: 24, weight: .medium, design: .rounded))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .opacity(appearAnimation ? 1.0 : 0.0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeInOut(duration: 0.5).delay(0.2), value: appearAnimation)

                        Spacer(minLength: 16)

                        VStack {
                            // 開始時刻
                            if let startDate = viewStore.startDate {
                                VStack(spacing: 4) {
                                    HStack {
                                        Text("開始時刻")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }

                                    HStack {
                                        Text(SCTimeFormatter.formatToHoursAndMinutes(startDate))
                                            .font(.system(size: 18, weight: .medium, design: .rounded))
                                            .foregroundStyle(.primary)
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)

                                Divider()
                                    .background(Color.primary.opacity(0.1))
                                    .padding(.horizontal, 8)
                            }

                            // 使用時間
                            VStack(spacing: 4) {
                                HStack {
                                    Text("タイマー時間")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }

                                HStack {
                                    Text("\(viewStore.timerDurationMinutes)分")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.07))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .opacity(appearAnimation ? 1.0 : 0.0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeInOut(duration: 0.5).delay(0.3), value: appearAnimation)

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

                // タイマーの音を再度再生（必要に応じて）
                if viewStore.completionDate == nil {
                    // 正常に完了していない場合は終了処理を呼ぶ
                    onDismiss()
                }
            }
        })
    }
}
