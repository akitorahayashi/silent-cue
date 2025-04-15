import Foundation

/// ナビゲーションの宛先を示す型
enum NavigationDestination: Hashable {
    case countdown
    case completion
    case settings
    case timerStart // ルート画面
}
