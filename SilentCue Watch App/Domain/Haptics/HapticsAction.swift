import ComposableArchitecture
import Foundation

/// ハプティックスに関連するすべてのアクション
enum HapticsAction: Equatable {
    // 振動の制御
    case startHaptic(HapticType)
    case stopHaptic

    // 設定
    case updateHapticSettings(type: HapticType)
}
