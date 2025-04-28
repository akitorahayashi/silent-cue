import CasePaths
import ComposableArchitecture
import SwiftUI
import UserNotifications // For UNAuthorizationStatus

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

    // 初回起動と通知許可フロー
    case checkFirstLaunch
    case markAsLaunched
    case notificationAlertPermitTapped
    case notificationAlertDenyTapped
    case setNotificationAlert(isPresented: Bool)

    // 内部アクション
    case notificationStatusChecked(UNAuthorizationStatus)
    case internalAction
}
