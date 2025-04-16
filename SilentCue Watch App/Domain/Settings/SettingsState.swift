import Foundation

/// 設定画面の状態を管理するクラス
struct SettingsState: Equatable {
    var selectedHapticType: HapticType = .standard
    var isSettingsLoaded = false
    var isPreviewingHaptic = false
}
