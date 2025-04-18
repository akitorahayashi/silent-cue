import ComposableArchitecture
import SwiftUI

// MARK: - メインビュー

struct SetTimerView: View {
    let store: StoreOf<TimerReducer>
    var onSettingsButtonTapped: () -> Void
    var onTimerStart: () -> Void

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            ScrollView {
                VStack {
                    // モード選択エリア
                    HStack(spacing: 2) {
                        ForEach(TimerMode.allCases) { mode in
                            TimerModeSelectionButton(
                                mode: mode,
                                isSelected: viewStore.timerMode == mode,
                                onTap: {
                                    viewStore.send(.timerModeSelected(mode))
                                }
                            )
                            .accessibilityLabel(mode.rawValue)
                            .accessibilityIdentifier(
                                "TimerModeButton\(mode == .afterMinutes ? "AfterMinutes" : "AtTime")"
                            )
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 10)

                    // 時間選択エリア
                    Group {
                        if viewStore.timerMode == .afterMinutes {
                            // 分選択
                            MinutesPicker(selectedMinutes: viewStore.binding(
                                get: \.selectedMinutes,
                                send: TimerAction.minutesSelected
                            ))
                            .accessibilityIdentifier(SCAccessibilityIdentifiers.SetTimerView.minutesPickerView.rawValue)
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
                            .accessibilityIdentifier(
                                SCAccessibilityIdentifiers.SetTimerView.hourMinutePickerView
                                    .rawValue
                            )
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.3), value: viewStore.timerMode)

                    Spacer(minLength: 16)

                    // 開始ボタン
                    StartButton {
                        viewStore.send(.startTimer)
                        onTimerStart()
                    }
                    .accessibilityLabel("開始")
                    .accessibilityIdentifier(SCAccessibilityIdentifiers.SetTimerView.startTimerButton.rawValue)
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .accessibilityIdentifier(SCAccessibilityIdentifiers.SetTimerView.setTimerScrollView.rawValue)
            .scrollIndicators(.never)
            .navigationTitle(SCAccessibilityIdentifiers.SetTimerView.navigationBarTitle.rawValue)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onSettingsButtonTapped) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("設定")
                    .accessibilityIdentifier(SCAccessibilityIdentifiers.SetTimerView.openSettingsPage.rawValue)
                    .accessibilityAddTraits(.isButton)
                    .padding(.trailing, 5)
                }
            }
        })
    }
}
