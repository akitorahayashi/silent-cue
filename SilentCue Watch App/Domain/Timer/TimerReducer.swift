import Foundation
import ComposableArchitecture
import WatchKit

/// タイマー関連のすべての機能を管理するReducer
struct TimerReducer: Reducer {
    typealias State = TimerState
    typealias Action = TimerAction
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.userDefaultsManager) var userDefaultsManager
    
    private enum CancelID { case timer }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // タイマー設定のアクション
            case .timerModeSelected(let mode):
                state.timerMode = mode
                
                // 時刻モードに切り替わった場合、現在時刻を設定
                if mode == .atTime {
                    let now = Date()
                    let calendar = Calendar.current
                    state.selectedHour = calendar.component(.hour, from: now)
                    state.selectedMinute = calendar.component(.minute, from: now)
                }
                
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
                
            // タイマー操作
            case .startTimer:
                // 開始時間と終了時間を設定
                let now = Date()
                state.totalSeconds = state.calculatedTotalSeconds
                state.startDate = now
                state.targetEndDate = now.addingTimeInterval(TimeInterval(state.totalSeconds))
                state.displayTime = SCTimeFormatter.formatSecondsToTimeString(state.remainingSeconds)
                state.isRunning = true
                
                // 完了情報をリセット
                state.completionDate = nil
                state.timerDurationMinutes = state.totalSeconds / 60
                
                // 拡張ランタイムセッションを開始
                ExtendedRuntimeManager.shared.startSession(duration: TimeInterval(state.totalSeconds + 10))
                
                return .run { send in
                    // 設定の読み込み
                    await send(.loadSettings)
                    
                    // 1秒ごとに発火するタイマーをセットアップ
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.tick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .cancelTimer:
                state.isRunning = false
                state.startDate = nil
                state.targetEndDate = nil
                state.completionDate = nil
                
                // 拡張ランタイムセッションを停止
                ExtendedRuntimeManager.shared.stopSession()
                
                return .cancel(id: CancelID.timer)
                
            case .pauseTimer:
                state.isRunning = false
                
                // 一時停止時は残り時間を記録
                let remainingTime = state.remainingSeconds
                state.totalSeconds = remainingTime
                
                return .cancel(id: CancelID.timer)
                
            case .resumeTimer:
                // 再開時は新たに開始時間と終了時間を設定
                let now = Date()
                state.startDate = now
                state.targetEndDate = now.addingTimeInterval(TimeInterval(state.totalSeconds))
                state.isRunning = true
                
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.tick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .tick:
                // 残り時間を計算（計算プロパティになったので直接更新は不要）
                // 表示だけを更新
                state.displayTime = SCTimeFormatter.formatSecondsToTimeString(state.remainingSeconds)
                
                // タイマー完了判定
                if state.remainingSeconds <= 0 {
                    return .send(.timerFinished)
                }
                
                return .none
                
            case .timerFinished:
                state.isRunning = false
                
                // 完了情報を保存
                state.completionDate = Date()
                
                // 拡張ランタイムセッションを停止
                ExtendedRuntimeManager.shared.stopSession()
                
                // 非同期クロージャーで使う値を先に取得（inoutパラメータを直接キャプチャできないため）
                let selectedHapticType = state.selectedHapticType
                let stopVibrationAutomatically = state.stopVibrationAutomatically
                
                return .run { _ in
                    // ハプティックフィードバックを再生
                    let device = WKInterfaceDevice.current()
                    
                    // 設定に応じて振動を制御
                    if stopVibrationAutomatically {
                        // 3秒間繰り返し振動を再生
                        let startTime = Date()
                        let endTime = startTime.addingTimeInterval(3.0)
                        
                        while Date() < endTime {
                            // 選択された振動パターンを再生
                            device.play(selectedHapticType.wkHapticType)
                            
                            // 次の振動までの間隔を待機
                            try await Task.sleep(for: .seconds(selectedHapticType.interval))
                        }
                    } else {
                        // 設定がオフの場合は無限に振動を続ける
                        while true {
                            // 選択された振動パターンを再生
                            device.play(selectedHapticType.wkHapticType)
                            
                            // 次の振動までの間隔を待機
                            try await Task.sleep(for: .seconds(selectedHapticType.interval))
                        }
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .dismissCompletionView:
                // 完了情報をリセット
                state.completionDate = nil
                // 閉じるボタンで振動を停止
                return .cancel(id: CancelID.timer)
                
            // バックグラウンド対応
            case .updateTimerDisplay:
                // バックグラウンドから復帰時に表示を更新
                if state.isRunning {
                    state.displayTime = SCTimeFormatter.formatSecondsToTimeString(state.remainingSeconds)
                    
                    // タイマー完了判定
                    if state.remainingSeconds <= 0 {
                        return .send(.timerFinished)
                    }
                }
                return .none
                
            // その他
            case .loadSettings:
                return .run { send in
                    let stopVibration = self.userDefaultsManager.object(forKey: .stopVibrationAutomatically) as? Bool ?? true
                    let typeRaw = self.userDefaultsManager.object(forKey: .hapticType) as? String
                    let hapticType = typeRaw.flatMap { HapticType(rawValue: $0) } ?? HapticType.standard
                    await send(.settingsLoaded(stopVibration: stopVibration, hapticType: hapticType))
                }
                
            case let .settingsLoaded(stopVibration, hapticType):
                state.stopVibrationAutomatically = stopVibration
                state.selectedHapticType = hapticType
                return .none
            }
        }
    }
} 
