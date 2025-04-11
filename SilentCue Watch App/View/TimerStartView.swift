import SwiftUI
import ComposableArchitecture

// MARK: - 共通の色とスタイル定義
private extension Color {
    static let controlBackground = Color.secondary.opacity(0.15)
    static let selectedBackground = Color.secondary.opacity(0.3)
    static let controlBorder = Color.primary.opacity(0.2)
    static let selectedBorder = Color.primary.opacity(0.3)
}

private extension View {
    func standardControlStyle(isSelected: Bool = false) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.selectedBackground : Color.controlBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.selectedBorder : Color.controlBorder, lineWidth: 1)
            )
    }
}

struct TimerStartView: View {
    let store: StoreOf<TimerReducer>
    var onSettingsButtonTapped: () -> Void
    var onTimerStart: () -> Void
    
    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            ScrollView {
                VStack(spacing: 16) {
                    // モード選択
                    HStack(spacing: 2) {
                        ForEach(TimerMode.allCases) { mode in
                            Button(action: {
                                viewStore.send(.timerModeSelected(mode))
                            }, label: {
                                Text(mode.rawValue)
                                    .font(.system(size: 14))
                                    .fontWeight(viewStore.timerMode == mode ? .semibold : .regular)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(viewStore.timerMode == mode ? 
                                                  Color.secondary.opacity(0.3) : 
                                                  Color.secondary.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                                    )
                                    .foregroundStyle(Color.primary)
                            })
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 時間選択エリア
                    VStack {
                        if viewStore.timerMode == .afterMinutes {
                            // 分選択
                                Picker("分", selection: viewStore.binding(
                                    get: \.selectedMinutes,
                                    send: TimerAction.minutesSelected
                                )) {
                                    ForEach(1...60, id: \.self) { minute in
                                        Text("\(minute)")
                                            .tag(minute)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 100)
                                .padding(.horizontal, 10)
                        } else {
                                HStack(spacing: 4) {
                                    Picker("時", selection: viewStore.binding(
                                        get: \.selectedHour,
                                        send: TimerAction.hourSelected
                                    )) {
                                        ForEach(0..<24) { hour in
                                            Text("\(hour)")
                                                .tag(hour)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    
                                    Picker("分", selection: viewStore.binding(
                                        get: \.selectedMinute,
                                        send: TimerAction.minuteSelected
                                    )) {
                                        ForEach(0..<60) { minute in
                                            Text(String(format: "%02d", minute))
                                                .tag(minute)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                }
                                .frame(height: 100)
                                .padding(.horizontal, 6)
                        }
                    }
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.2), value: viewStore.timerMode)
                    
                    // 開始ボタン
                    Button(action: {
                        viewStore.send(.startTimer)
                        onTimerStart()
                    }, label: {
                        Text("開始")
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
                    })
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.never)
            .navigationTitle("Silent Cue")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        onSettingsButtonTapped()
                    }, label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.primary.opacity(0.8))
                    })
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                viewStore.send(.loadSettings)
            }
        })
    }
} 
