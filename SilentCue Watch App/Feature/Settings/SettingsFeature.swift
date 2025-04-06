import Foundation
import ComposableArchitecture

struct SettingsFeature: Reducer {
    struct State: Equatable {
        var stopVibrationAutomatically: Bool = true
        var selectedHapticType: HapticType = .default
        var isLightMode: Bool = false
        var hasLoaded: Bool = false
    }
    
    enum Action: Equatable {
        case onAppear
        case toggleStopVibrationAutomatically(Bool)
        case selectHapticType(HapticType)
        case toggleThemeMode(Bool)
        case saveSettings
        case settingsLoaded(stopVibration: Bool, hapticType: HapticType, isLightMode: Bool)
        case backButtonTapped
    }
    
    @Dependency(\.userDefaultsManager) var userDefaultsManager
    
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
                return .send(.saveSettings)
                
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