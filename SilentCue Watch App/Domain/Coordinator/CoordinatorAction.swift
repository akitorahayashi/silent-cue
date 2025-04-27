import CasePaths
import ComposableArchitecture
import SwiftUI

@CasePathable
enum CoordinatorAction: Equatable {
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
