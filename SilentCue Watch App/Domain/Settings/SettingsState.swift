import Foundation

/// 設定画面の状態を管理するクラス
struct SettingsState: Equatable {
    var stopVibrationAutomatically = true
    var selectedHapticType: HapticType = .standard
    var hasLoaded = false
    var isPreviewingHaptic = false
}
