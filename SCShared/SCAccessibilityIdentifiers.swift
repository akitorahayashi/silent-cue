import Foundation

public enum SCAccessibilityIdentifiers {
    public enum SetTimerView: String {
        case openSettingsButton
        case navigationBarTitle = "Silent Cue"
        case minutesModeButton
        case timeModeButton
        case minutesOnlyPicker
        case hourPicker
        case minutePicker
        case startTimerButton
    }

    public enum SettingsView: String {
        case navigationBarTitle = "Settings"
        case backButton
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
        case notifyEndTimeSection
        case closeTimeCompletionViewButton
        case timerSummarySection
    }
}
