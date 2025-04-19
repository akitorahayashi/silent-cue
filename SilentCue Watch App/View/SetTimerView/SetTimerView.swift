import ComposableArchitecture
import SwiftUI

// MARK: - メインビュー

struct SetTimerView: View {
    let store: StoreOf<TimerReducer>
    var onSettingsButtonTapped: () -> Void
    var onTimerStart: () -> Void

    // MARK: - Body

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            ScrollView {
                VStack {
                    // モード選択エリア
                    modeSelectionArea(viewStore)

                    Spacer(minLength: 10)

                    // 時間選択エリア
                    timeSelectionArea(viewStore)

                    Spacer(minLength: 16)

                    // 開始ボタン
                    StartButton {
                        viewStore.send(.startTimer)
                        onTimerStart()
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.never)
            .navigationTitle(SCAccessibilityIdentifiers.SetTimerView.navigationBarTitle.rawValue)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onSettingsButtonTapped) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("設定")
                    .accessibilityIdentifier(SCAccessibilityIdentifiers.SetTimerView.openSettingsButton.rawValue)
                    .accessibilityAddTraits(.isButton)
                }
            }
        })
    }

    // MARK: - Private Components

    @ViewBuilder
    private func modeSelectionArea(_ viewStore: ViewStoreOf<TimerReducer>) -> some View {
        HStack(spacing: 2) {
            ForEach(TimerMode.allCases) { mode in
                TimerModeSelectionButton(
                    mode: mode,
                    isSelected: viewStore.timerMode == mode,
                    onTap: {
                        viewStore.send(.timerModeSelected(mode))
                    }
                )
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func timeSelectionArea(_ viewStore: ViewStoreOf<TimerReducer>) -> some View {
        Group {
            if viewStore.timerMode == .minutes {
                // 分選択
                MinutesPicker(selectedMinutes: viewStore.binding(
                    get: \.selectedMinutes,
                    send: TimerAction.minutesSelected
                ))
                .transition(.opacity)
            } else {
                // 時間選択
                HourMinutePicker(
                    selectedHour: viewStore.binding(
                        get: \.selectedHour,
                        send: TimerAction.hourSelected
                    ),
                    selectedMinute: viewStore.binding(
                        get: \.selectedMinute,
                        send: TimerAction.minuteSelected
                    )
                )
                .transition(.opacity)
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.3), value: viewStore.timerMode)
    }
}


#Preview {
    // プレビュー用のデフォルトストアを作成
    let previewStore = Store(
        initialState: TimerReducer.State(),
        reducer: { TimerReducer() }
    )

    // SetTimerView を NavigationView でラップしてツールバーを表示
    NavigationView {
        SetTimerView(
            store: previewStore,
            onSettingsButtonTapped: {
                print("Settings button tapped in preview")
            },
            onTimerStart: {
                print("Start timer button tapped in preview")
            }
        )
    }
} 
