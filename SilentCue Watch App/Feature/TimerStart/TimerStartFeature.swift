import Foundation
import ComposableArchitecture

struct TimerStartFeature: Reducer {
    // タイマーモード
    enum TimerMode: String, Equatable, CaseIterable, Identifiable {
        case afterMinutes = "分後"  // 何分後に鳴らすか
        case atTime = "時刻"      // 何時に鳴らすか
        
        var id: String { self.rawValue }
    }
    
    struct State: Equatable {
        // 現在選択されているタイマーモード
        var timerMode: TimerMode = .afterMinutes
        
        // 「何分後」モードの設定
        var selectedMinutes: Int = 5
        
        // 「何時に」モードの設定
        var selectedHour: Int = Calendar.current.component(.hour, from: Date())
        var selectedMinute: Int = (Calendar.current.component(.minute, from: Date()) + 5) % 60
        
        // 選択された時間から計算された合計秒数
        var totalSeconds: Int {
            switch timerMode {
            case .afterMinutes:
                return selectedMinutes * 60
            case .atTime:
                let now = Date()
                let calendar = Calendar.current
                let hour = selectedHour
                let minute = selectedMinute
                
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
                dateComponents.hour = hour
                dateComponents.minute = minute
                dateComponents.second = 0
                
                guard let targetDate = calendar.date(from: dateComponents) else {
                    return 0
                }
                
                // 選択された時刻が現在時刻より前の場合は翌日とみなす
                if targetDate < now {
                    guard let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: targetDate) else {
                        return 0
                    }
                    return Int(tomorrowDate.timeIntervalSince(now))
                }
                
                return Int(targetDate.timeIntervalSince(now))
            }
        }
        
        init() {
            // 現在時刻を取得して初期値として設定
            let now = Date()
            let calendar = Calendar.current
            
            self.selectedHour = calendar.component(.hour, from: now)
            // 現在時刻から5分後を初期値に設定（60分を超える場合は次の時間に調整）
            let currentMinute = calendar.component(.minute, from: now)
            self.selectedMinute = (currentMinute + 5) % 60
            
            // 分が繰り上がる場合は時間も調整
            if currentMinute + 5 >= 60 {
                self.selectedHour = (self.selectedHour + 1) % 24
            }
        }
    }
    
    enum Action: Equatable {
        case timerModeSelected(TimerMode)
        case minutesSelected(Int)  // 「何分後」モード用
        case hourSelected(Int)     // 「何時に」モード用
        case minuteSelected(Int)   // 「何時に」モード用
        case startButtonTapped
        case settingsButtonTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .timerModeSelected(let mode):
                state.timerMode = mode
                return .none
                
            case .minutesSelected(let minutes):
                state.selectedMinutes = minutes
                return .none
                
            case .hourSelected(let hour):
                state.selectedHour = hour
                return .none
                
            case .minuteSelected(let minute):
                state.selectedMinute = minute
                return .none
                
            case .startButtonTapped, .settingsButtonTapped:
                return .none
            }
        }
    }
} 