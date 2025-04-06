import SwiftUI
import ComposableArchitecture

struct TimerStartView: View {
    let store: StoreOf<TimerStartFeature>
    
    // 環境変数からカラースキーム情報を取得
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 16) {
                    // モード選択をカスタムボタンとして実装
                    HStack(spacing: 2) {
                        ForEach(TimerStartFeature.TimerMode.allCases) { mode in
                            Button {
                                viewStore.send(.timerModeSelected(mode))
                            } label: {
                                Text(mode.rawValue)
                                    .font(.system(size: 14))
                                    .fontWeight(viewStore.timerMode == mode ? .semibold : .regular)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(viewStore.timerMode == mode ? Color.blue : Color.gray.opacity(0.2))
                                    )
                                    .foregroundStyle(viewStore.timerMode == mode ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 入力コントロール
                    if viewStore.timerMode == .afterMinutes {
                        VStack(spacing: 8) {
                            Text("分")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Picker("分", selection: viewStore.binding(
                                get: \.selectedMinutes,
                                send: TimerStartFeature.Action.minutesSelected
                            )) {
                                ForEach(1...60, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .labelsHidden()
                            .frame(height: 120)
                            .containerShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.top, 10)
                    } else {
                        VStack(spacing: 8) {
                            HStack {
                                Text("時")
                                Spacer()
                                Text("分")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 50)
                            
                            HStack(spacing: 0) {
                                Picker("時", selection: viewStore.binding(
                                    get: \.selectedHour,
                                    send: TimerStartFeature.Action.hourSelected
                                )) {
                                    ForEach(0..<24) { hour in
                                        Text("\(hour)").tag(hour)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                
                                Picker("分", selection: viewStore.binding(
                                    get: \.selectedMinute,
                                    send: TimerStartFeature.Action.minuteSelected
                                )) {
                                    ForEach(0..<60) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                            }
                            .frame(height: 120)
                        }
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                    
                    // 開始ボタン
                    Button {
                        viewStore.send(.startButtonTapped)
                    } label: {
                        Text("タイマー開始")
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.large)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .padding(.top, 10)
            }
            .navigationTitle("Silent Cue")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewStore.send(.settingsButtonTapped)
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}