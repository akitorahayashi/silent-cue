import Foundation

public enum SCAccessibilityIdentifiers {
    public enum SetTimerView: String {
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

    public enum SettingsView: String {
        case navigationBarTitle = "Settings"
        case vibrationTypeHeader
        case vibrationTypeOptionStandard
        case vibrationTypeOptionStrong
        case vibrationTypeOptionWeak
    }

    public enum CountdownView: String {
        case countdownTimeDisplay
        case cancelTimerButton
    }

    public enum TimerCompletionView: String {
        case timerCompletionView
        case closeTimeCompletionViewButton
        case notifyEndTimeViewVStack
        case timerSummaryViewVStack
    }
}
