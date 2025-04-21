import SwiftUI
import CasePaths
import ComposableArchitecture

/// アプリ全体のルートアクション
@CasePathable
enum AppAction: Equatable {
    // 各機能ドメインのアクションをラップ
    case timer(TimerAction)
    case settings(SettingsAction)
    case haptics(HapticsAction)

    // アプリライフサイクル
    case onAppear
    case scenePhaseChanged(ScenePhase)

    // ナビゲーション
    case pathChanged([NavigationDestination])
    case pushScreen(NavigationDestination)
    case popScreen
}
