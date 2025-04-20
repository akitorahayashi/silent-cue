import Foundation

enum SCAccessibilityIdentifiers {
    enum SetTimerView: String {
        case openSettingsButton
        case navigationBarTitle = "Silent Cue"
        case minutesModeButton
        case timeModeButton
        case minutesPickerView
        case hourMinutePickerView
        case hourPickerWheel
        case minutePickerWheel
        case startTimerButton
    }

    enum SettingsView: String {
        case navigationBarTitle = "Settings"
        case vibrationTypeHeader
        case vibrationTypeOptionStandard
        case vibrationTypeOptionStrong
        case vibrationTypeOptionWeak
    }

    enum CountdownView: String {
        case timeFormatLabel
        case countdownTimeDisplay
        case cancelTimerButton
    }

    enum TimerCompletionView: String {
        case timerCompletionView
        case closeTimeCompletionViewButton
        case notifyEndTimeViewVStack
        case timerSummaryViewVStack
    }
}
