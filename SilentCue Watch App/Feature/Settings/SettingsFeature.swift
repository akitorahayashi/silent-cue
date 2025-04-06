import Foundation
import ComposableArchitecture
import WatchKit

struct SettingsFeature: Reducer {
    struct State: Equatable {
        var stopVibrationAutomatically: Bool = true
        var selectedHapticType: HapticType = .default
        var isLightMode: Bool = false
        var hasLoaded: Bool = false
        var isPreviewingHaptic: Bool = false
    }
    
    enum Action: Equatable {
        case onAppear
        case toggleStopVibrationAutomatically(Bool)
        case selectHapticType(HapticType)
        case toggleThemeMode(Bool)
        case previewHapticFeedback(HapticType)
        case saveSettings
        case settingsLoaded(stopVibration: Bool, hapticType: HapticType, isLightMode: Bool)
        case backButtonTapped
    }
    
    @Dependency(\.userDefaultsManager) var userDefaultsManager
    
    private enum CancelID { case hapticPreview }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let stopVibration = self.userDefaultsManager.object(forKey: .stopVibrationAutomatically) as? Bool ?? true
                    let typeRaw = self.userDefaultsManager.object(forKey: .hapticType) as? String
                    let hapticType = typeRaw.flatMap { HapticType(rawValue: $0) } ?? .default
                    let isLightMode = self.userDefaultsManager.object(forKey: .appTheme) as? Bool ?? false
                    await send(.settingsLoaded(stopVibration: stopVibration, hapticType: hapticType, isLightMode: isLightMode))
                }
                
            case let .settingsLoaded(stopVibration, hapticType, isLightMode):
                state.stopVibrationAutomatically = stopVibration
                state.selectedHapticType = hapticType
                state.isLightMode = isLightMode
                state.hasLoaded = true
                return .none
                
            case .toggleStopVibrationAutomatically(let value):
                state.stopVibrationAutomatically = value
                return .send(.saveSettings)
                
            case .selectHapticType(let type):
                state.selectedHapticType = type
                // タイプを選択したら自動的にプレビュー
                return .merge(
                    .send(.saveSettings),
                    .send(.previewHapticFeedback(type))
                )
                
            case .previewHapticFeedback(let hapticType):
                // 既にプレビュー中ならキャンセル
                if state.isPreviewingHaptic {
                    return .cancel(id: CancelID.hapticPreview)
                }
                
                state.isPreviewingHaptic = true
                
                return .run { send in
                    // Apple Watch向けのハプティックフィードバック
                    let device = WKInterfaceDevice.current()
                    
                    // WKHapticType型を指定して適切なハプティックフィードバックを再生
                    let hapticTypeToPlay: WKHapticType
                    switch hapticType {
                    case .default, .notification, .warning:
                        hapticTypeToPlay = .notification
                    case .success:
                        hapticTypeToPlay = .success
                    case .failure:
                        hapticTypeToPlay = .click
                    }
                    
                    // 振動を再生
                    device.play(hapticTypeToPlay)
                    
                    // 3秒後にプレビュー状態を終了
                    try await Task.sleep(for: .seconds(3))
                    
                    state.isPreviewingHaptic = false
                }
                .cancellable(id: CancelID.hapticPreview)
                
            case .toggleThemeMode(let isLightMode):
                state.isLightMode = isLightMode
                return .send(.saveSettings)
                
            case .saveSettings:
                let stopAutoValue = state.stopVibrationAutomatically
                let hapticTypeValue = state.selectedHapticType.rawValue
                let isLightModeValue = state.isLightMode
                
                return .run { _ in
                    self.userDefaultsManager.set(stopAutoValue, forKey: .stopVibrationAutomatically)
                    self.userDefaultsManager.set(hapticTypeValue, forKey: .hapticType)
                    self.userDefaultsManager.set(isLightModeValue, forKey: .appTheme)
                }
                
            case .backButtonTapped:
                return .none
            }
        }
    }
}