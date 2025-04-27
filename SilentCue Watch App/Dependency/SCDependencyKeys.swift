import Dependencies
import WatchKit
import UserNotifications
import ComposableArchitecture
import SCProtocol

import SCLiveService
#if DEBUG
import SCPreview
import SCMock
#endif

// MARK: - Dependency Keys
// #if DEBUG ブロック内では、各サービスのプレビュー用実装を使用します。

enum UserDefaultsServiceKey: DependencyKey {
    static let liveValue: UserDefaultsServiceProtocol = SCLiveService.LiveUserDefaultsService()

    #if DEBUG
    static let testValue: UserDefaultsServiceProtocol = SCMock.MockUserDefaultsManager()
    static let previewValue: UserDefaultsServiceProtocol = SCPreview.PreviewUserDefaultsService()
    #else
    // Releaseビルド時は Test/Preview に Live を使う
    static let testValue: UserDefaultsServiceProtocol = SCLiveService.LiveUserDefaultsService()
    static let previewValue: UserDefaultsServiceProtocol = SCLiveService.LiveUserDefaultsService()
    #endif
}

enum HapticsServiceKey: DependencyKey {
    static let liveValue: HapticsServiceProtocol = SCLiveService.LiveHapticsService()

    #if DEBUG
    static let testValue: HapticsServiceProtocol = SCMock.MockHapticsService()
    static let previewValue: HapticsServiceProtocol = SCPreview.PreviewHapticsService()
    #else
    static let testValue: HapticsServiceProtocol = SCLiveService.LiveHapticsService()
    static let previewValue: HapticsServiceProtocol = SCLiveService.LiveHapticsService()
    #endif
}

enum NotificationServiceKey: DependencyKey {
    static let liveValue: NotificationServiceProtocol = SCLiveService.LiveNotificationService()

    #if DEBUG
    static let testValue: NotificationServiceProtocol = SCMock.MockNotificationService()
    static let previewValue: NotificationServiceProtocol = SCPreview.PreviewNotificationService()
    #else
    static let testValue: NotificationServiceProtocol = SCLiveService.LiveNotificationService()
    static let previewValue: NotificationServiceProtocol = SCLiveService.LiveNotificationService()
    #endif
}

enum ExtendedRuntimeServiceKey: DependencyKey {
    static let liveValue: ExtendedRuntimeServiceProtocol = SCLiveService.LiveExtendedRuntimeService()

    #if DEBUG
    static let testValue: ExtendedRuntimeServiceProtocol = SCMock.MockExtendedRuntimeService()
    static let previewValue: ExtendedRuntimeServiceProtocol = SCPreview.PreviewExtendedRuntimeService()
    #else
    static let testValue: ExtendedRuntimeServiceProtocol = SCLiveService.LiveExtendedRuntimeService()
    static let previewValue: ExtendedRuntimeServiceProtocol = SCLiveService.LiveExtendedRuntimeService()
    #endif
} 
