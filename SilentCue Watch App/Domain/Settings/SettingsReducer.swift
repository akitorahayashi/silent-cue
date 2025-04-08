import Foundation
import ComposableArchitecture
import WatchKit

/// 設定画面の機能を管理するReducer
struct SettingsReducer: Reducer {
    typealias State = SettingsState
    typealias Action = SettingsAction
    
    @Dependency(\.userDefaultsManager) var userDefaultsManager
    
    private enum CancelID { case hapticPreview }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
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
                state.hasLoaded = true
                return .none
                
            case .toggleStopVibrationAutomatically(let value):
                state.stopVibrationAutomatically = value
                return .send(.saveSettings)
                
            case .selectHapticType(let type):
                state.selectedHapticType = type
                // タイプを選択したら自動的にプレビューと設定の保存
                return .merge(
                    .send(.saveSettings),
                    .send(.previewHapticFeedback(type))
                )
                
            case .previewHapticFeedback(let hapticType):
                // 既にプレビュー中なら前のプレビューをキャンセル
                let cancelEffect: Effect<SettingsAction> = state.isPreviewingHaptic 
                    ? .cancel(id: CancelID.hapticPreview)
                    : .none
                
                // 状態を更新し、新しいハプティックフィードバックを再生
                state.selectedHapticType = hapticType
                
                return .merge(
                    cancelEffect,
                    .send(.previewingHapticChanged(true)),
                    .run { send in
                        // Apple Watch向けのハプティックフィードバック
                        let device = WKInterfaceDevice.current()
                        
                        // WKHapticType型を指定して適切なハプティックフィードバックを再生
                        let hapticTypeToPlay: WKHapticType
                        switch hapticType {
                        case .default, .notification:
                            hapticTypeToPlay = .notification
                        case .warning:
                            hapticTypeToPlay = .directionUp
                        case .success:
                            hapticTypeToPlay = .success
                        case .failure:
                            hapticTypeToPlay = .failure
                        }
                        
                        // 振動を再生
                        device.play(hapticTypeToPlay)
                        
                        // 2秒後にプレビュー状態を終了（使いやすさのため短縮）
                        try await Task.sleep(for: .seconds(2))
                        
                        // プレビュー完了アクションを送信
                        await send(.previewHapticCompleted)
                    }
                    .cancellable(id: CancelID.hapticPreview)
                )
                
            case .previewHapticCompleted:
                // プレビュー完了アクションでフラグを更新
                return .send(.previewingHapticChanged(false))
                
            case .previewingHapticChanged(let isPreviewingHaptic):
                state.isPreviewingHaptic = isPreviewingHaptic
                return .none
                
            case .saveSettings:
                let stopAutoValue = state.stopVibrationAutomatically
                let hapticTypeValue = state.selectedHapticType.rawValue
                
                return .run { _ in
                    self.userDefaultsManager.set(stopAutoValue, forKey: .stopVibrationAutomatically)
                    self.userDefaultsManager.set(hapticTypeValue, forKey: .hapticType)
                }
                
            case .backButtonTapped:
                return .none
            }
        }
    }
} 