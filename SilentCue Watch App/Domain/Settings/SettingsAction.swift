import Foundation
import CasePaths
import ComposableArchitecture

/// 設定画面に関連するアクション
@CasePathable
enum SettingsAction: Equatable {
    // 設定の読み込み関連
    case loadSettings
    case settingsLoaded(stopVibration: Bool, hapticType: HapticType, isLightMode: Bool)
    
    // 設定の変更関連
    case toggleStopVibrationAutomatically(Bool)
    case selectHapticType(HapticType)
    case toggleThemeMode(Bool)
    case saveSettings
    
    // ハプティックフィードバック関連
    case previewHapticFeedback(HapticType)
    case previewHapticCompleted
    case previewingHapticChanged(Bool)
    
    // ナビゲーション関連
    case backButtonTapped
} 