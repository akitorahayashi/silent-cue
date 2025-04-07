import Foundation

/// 設定画面の状態を管理するクラス
struct SettingsState: Equatable {
    var stopVibrationAutomatically: Bool = true
    var selectedHapticType: HapticType = .default
    var hasLoaded: Bool = false
    var isPreviewingHaptic: Bool = false
} 