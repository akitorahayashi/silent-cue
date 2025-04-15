import Foundation

/// アプリ全体のルート状態
struct AppState: Equatable {
    var path: [NavigationDestination] = [] // NavigationStackのパス
    var timer: TimerState = .init()
    var settings: SettingsState = .init()
    var haptics: HapticsState = .init()

    // ナビゲーションの現在の画面を判断する
    var currentDestination: NavigationDestination? {
        path.last
    }
}
