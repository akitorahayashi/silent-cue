import Foundation

enum SCAccessibilityIdentifiers {
    enum SetTimerView: String {
        case minutesPickerView
        case hourMinutePickerView
        case startTimerButton
        case setTimerScrollView
        case openSettingsPage
        case navigationBarTitle = "Silent Cue"
    }

    enum SettingsView: String {
        case vibrationTypeHeader
        case vibrationTypeOptionStandard
        case vibrationTypeOptionStrong
        case vibrationTypeOptionWeak
        case navigationBarTitle = "Settings"
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
