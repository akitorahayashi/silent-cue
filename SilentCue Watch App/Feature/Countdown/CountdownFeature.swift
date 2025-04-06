import Foundation
import ComposableArchitecture
import WatchKit

struct CountdownFeature: Reducer {
    struct State: Equatable {
        var totalSeconds: Int = 0
        var remainingSeconds: Int = 0
        var isRunning: Bool = false
        var displayTime: String = "00:00"
    }
    
    enum Action: Equatable {
        case startTimer     // タイマーを開始する
        case tick           // 1秒ごとに発火するタイマーの心拍
        case cancelButtonTapped  // キャンセルボタンが押された
        case timerFinished  // タイマーが完了した
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.userDefaultsManager) var userDefaultsManager
    
    private enum CancelID { case timer }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startTimer:
                state.isRunning = true
                
                return .run { [remainingSeconds = state.remainingSeconds] send in
                    // 1秒ごとに発火するタイマーをセットアップ
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
                
                return .run { _ in
                    // UserDefaultsManagerからobjectで取得してキャスト
                    let stopAutomatically = self.userDefaultsManager.object(forKey: .stopVibrationAutomatically) as? Bool ?? true
                    
                    // 振動タイプの取得とデフォルト値ハンドリング
                    let typeRaw = self.userDefaultsManager.object(forKey: .hapticType) as? String
                    let hapticType = typeRaw.flatMap { HapticType(rawValue: $0) } ?? .default
                    
                    // Apple Watch向けのハプティックフィードバック
                    let device = WKInterfaceDevice.current()
                    
                    // WKHapticType型を指定して適切なハプティックフィードバックを再生
                    // この方法はwatchOS 11.2との互換性を保つため、利用可能なメンバーのみを使用
                    let hapticTypeToPlay: WKHapticType
                    switch hapticType {
                    case .default, .notification, .warning:
                        // warningはWKHapticTypeに存在しないので、notificationにマッピング
                        hapticTypeToPlay = .notification
                    case .success:
                        hapticTypeToPlay = .success
                    case .failure:
                        // failureも利用できない場合は.click（または別の利用可能なタイプ）を使用
                        hapticTypeToPlay = .click
                    }
                    
                    // 振動を再生
                    device.play(hapticTypeToPlay)
                    
                    // 自動停止が有効な場合、3秒後にハプティックを停止
                    if stopAutomatically {
                        try await Task.sleep(for: .seconds(3))
                        // watchOSでは実際には継続中のハプティックを停止できませんが、
                        // カスタムの継続的なハプティックパターンがあれば、ここで停止します
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .cancelButtonTapped:
                state.isRunning = false
                
                return .cancel(id: CancelID.timer)
            }
        }
    }
} 