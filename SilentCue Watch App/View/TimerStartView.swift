import SwiftUI
import ComposableArchitecture

struct TimerStartView: View {
    let store: StoreOf<TimerReducer>
    
    // コールバック関数を追加
    var onSettingsButtonTapped: () -> Void
    var onTimerStart: () -> Void
    
    // 環境変数からカラースキーム情報を取得
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 8) {
                    // Extract mode selector to separate view
                    ModeSelectionView(viewStore: viewStore)
                    
                    // Extract time input controls to separate views
                    if viewStore.timerMode == .afterMinutes {
                        MinutesInputView(viewStore: viewStore)
                    } else {
                        TimeInputView(viewStore: viewStore)
                    }
                    
                    // Extract start button to separate view
                    StartButtonView(viewStore: viewStore, onTimerStart: onTimerStart)
                }
                .padding(.top, 10)
            }
            .scrollIndicators(.never)
            .navigationTitle("Silent Cue")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // 設定画面への遷移にコールバックを使用
                        onSettingsButtonTapped()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                // 画面表示時に設定を読み込む
                viewStore.send(.loadSettings)
            }
        }
    }
}

// MARK: - Extracted Views
struct ModeSelectionView: View {
    let viewStore: ViewStoreOf<TimerReducer>
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(TimerMode.allCases) { mode in
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
                                .fill(viewStore.timerMode == mode ? 
                                      Color.accentColor : 
                                      Color.secondary.opacity(0.2))
                        )
                        .foregroundStyle(viewStore.timerMode == mode ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}

struct MinutesInputView: View {
    let viewStore: ViewStoreOf<TimerReducer>
    
    var body: some View {
        VStack(spacing: 8) {
            Text("分")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker("分", selection: viewStore.binding(
                get: \.selectedMinutes,
                send: TimerAction.minutesSelected
            )) {
                ForEach(1...60, id: \.self) { minute in
                    Text("\(minute)")
                        .tag(minute)
                        .font(.system(size: 16))
                }
            }
            .labelsHidden()
            .frame(height: 100)
            .containerShape(RoundedRectangle(cornerRadius: 8))
            .pickerStyle(.wheel)
            .compositingGroup()
            .clipped()
            .padding(.horizontal, 20)
        }
        .padding(.top, 10)
    }
}

struct TimeInputView: View {
    let viewStore: ViewStoreOf<TimerReducer>
    
    var body: some View {
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
                    send: TimerAction.hourSelected
                )) {
                    ForEach(0..<24) { hour in
                        Text("\(hour)")
                            .tag(hour)
                            .font(.system(size: 16))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .pickerStyle(.wheel)
                .compositingGroup()
                .clipped()
                
                Picker("分", selection: viewStore.binding(
                    get: \.selectedMinute,
                    send: TimerAction.minuteSelected
                )) {
                    ForEach(0..<60) { minute in
                        Text(String(format: "%02d", minute))
                            .tag(minute)
                            .font(.system(size: 16))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .pickerStyle(.wheel)
                .compositingGroup()
                .clipped()
            }
            .frame(height: 100)
            .padding(.horizontal, 10)
        }
        .padding(.top, 10)
    }
}

struct StartButtonView: View {
    let viewStore: ViewStoreOf<TimerReducer>
    let onTimerStart: () -> Void
    
    var body: some View {
        Button {
            // タイマーを開始して画面遷移
            viewStore.send(.startTimer)
            onTimerStart()
        } label: {
            Text("タイマー開始")
                .font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.top, 16)
    }
} 
