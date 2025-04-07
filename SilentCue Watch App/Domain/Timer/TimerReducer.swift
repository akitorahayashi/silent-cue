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
                // 設定された時間をカウントダウン状態に適用
                state.totalSeconds = state.calculatedTotalSeconds
                state.remainingSeconds = state.totalSeconds
                state.displayTime = TimeFormatter.formatTime(state.totalSeconds)
                state.isRunning = true
                
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
                return .cancel(id: CancelID.timer)
                
            case .pauseTimer:
                state.isRunning = false
                return .cancel(id: CancelID.timer)
                
            case .resumeTimer:
                state.isRunning = true
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.tick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .tick:
                // 1秒ごとにカウントダウンを更新
                guard state.isRunning, state.remainingSeconds > 0 else { 
                    return .send(.timerFinished)
                }
                
                // 残り秒数を減らして表示を更新
                state.remainingSeconds -= 1
                state.displayTime = TimeFormatter.formatTime(state.remainingSeconds)
                
                if state.remainingSeconds <= 0 {
                    return .send(.timerFinished)
                }
                
                return .none
                
            case .timerFinished:
                state.isRunning = false
                
                // 非同期クロージャーで使う値を先に取得（inoutパラメータを直接キャプチャできないため）
                let selectedHapticType = state.selectedHapticType
                let stopVibrationAutomatically = state.stopVibrationAutomatically
                
                return .run { _ in
                    // ハプティックフィードバックを再生
                    let device = WKInterfaceDevice.current()
                    
                    // WKHapticType型を指定して適切なハプティックフィードバックを再生
                    let hapticTypeToPlay: WKHapticType
                    switch selectedHapticType {
                    case .default, .notification, .warning:
                        hapticTypeToPlay = .notification
                    case .success:
                        hapticTypeToPlay = .success
                    case .failure:
                        hapticTypeToPlay = .click
                    }
                    
                    // 振動を再生
                    device.play(hapticTypeToPlay)
                    
                    // 自動停止が有効な場合、3秒後に停止
                    if stopVibrationAutomatically {
                        try await Task.sleep(for: .seconds(3))
                    }
                }
                .cancellable(id: CancelID.timer)
                
            // その他
            case .loadSettings:
                return .run { send in
                    let stopVibration = self.userDefaultsManager.object(forKey: .stopVibrationAutomatically) as? Bool ?? true
                    let typeRaw = self.userDefaultsManager.object(forKey: .hapticType) as? String
                    let hapticType = typeRaw.flatMap { HapticType(rawValue: $0) } ?? .default
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