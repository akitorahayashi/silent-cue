import ComposableArchitecture
import Foundation

/// 設定画面に関連するアクション
enum SettingsAction: Equatable {
    // 設定の読み込み関連
    case loadSettings
    case settingsLoaded(hapticType: HapticType)

    // 設定の変更関連
    case selectHapticType(HapticType)
    case saveSettings

    // ハプティックフィードバック関連
    case previewHapticFeedback(HapticType)
    case previewHapticCompleted
    case previewingHapticChanged(Bool)

    // ナビゲーション関連
    case backButtonTapped
}
