import Foundation

/// ハプティクスの状態を管理する
struct HapticsState: Equatable {
    /// 現在振動中かどうか
    var isActive = false

    /// ハプティック設定
    var hapticType: HapticType = .standard
    var stopAutomatically = true

    /// 振動のプレビュー中かどうか
    var isPreviewingHaptic = false
}
