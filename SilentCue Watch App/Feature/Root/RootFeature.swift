import Foundation
import ComposableArchitecture

struct RootFeature: Reducer {
    struct State: Equatable {
        var timerStartState = TimerStartFeature.State()
        var countdownState = CountdownFeature.State()
        var settingsState = SettingsFeature.State()
        
        enum Screen {
            case timerStart
            case countdown
            case settings
        }
        
        var currentScreen: Screen = .timerStart
    }
    
    enum Action: Equatable {
        case timerStart(TimerStartFeature.Action)
        case countdown(CountdownFeature.Action)
        case settings(SettingsFeature.Action)
        case navigateTo(State.Screen)
    }
    
    var body: some ReducerOf<Self> {
        let baseReducer = Reduce<State, Action> { state, action in
            switch action {
            case .navigateTo(let screen):
                state.currentScreen = screen
                return .none
                
            case .timerStart(.startButtonTapped):
                return prepareTimerEffect(state: &state)
                
            case .countdown(.cancelButtonTapped):
                return .send(.navigateTo(.timerStart))
                
            case .timerStart(.settingsButtonTapped):
                return .send(.navigateTo(.settings))
                
            case .settings(.backButtonTapped):
                // 設定画面から戻る - タイマー開始画面に戻る
                return .send(.navigateTo(.timerStart))
                
            case .countdown, .settings, .timerStart:
                return .none
            }
        }
        
        return CombineReducers {
            baseReducer
            Scope(state: \.timerStartState, action: /Action.timerStart) {
                TimerStartFeature()
            }
            Scope(state: \.countdownState, action: /Action.countdown) {
                CountdownFeature()
            }
            Scope(state: \.settingsState, action: /Action.settings) {
                SettingsFeature()
            }
        }
    }
    
    private func prepareTimerEffect(state: inout State) -> Effect<Action> {
        // TimerStartFeatureのtotalSecondsを使用
        let totalSeconds = state.timerStartState.totalSeconds
        
        // カウントダウン画面に必要なデータを設定
        state.countdownState.totalSeconds = totalSeconds
        state.countdownState.remainingSeconds = totalSeconds
        state.countdownState.displayTime = TimeFormatter.formatTime(totalSeconds)
        
        return .run { send in
            await send(.navigateTo(.countdown))
            await send(.countdown(.startTimer))
        }
    }
}

// ローカルな時間フォーマット関数はコメントアウトまたは削除
// TimeFormatter.swiftに定義された名前空間付き関数を代わりに使用する
/* 
func formatTime(_ seconds: Int) -> String {
    if seconds >= 3600 {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    } else if seconds >= 60 {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    } else {
        return String(format: "00:%02d", seconds)
    }
}
*/ 