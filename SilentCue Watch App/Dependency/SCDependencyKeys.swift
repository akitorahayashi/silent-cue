import Dependencies
import WatchKit
import UserNotifications
@testable import SilentCue_Watch_App

private enum UserDefaultsServiceKey: DependencyKey {
    static let liveValue: UserDefaultsServiceProtocol = LiveUserDefaultsService()

    #if DEBUG
    static let previewValue: UserDefaultsServiceProtocol = PreviewUserDefaultsService()
    #else
    static let previewValue: UserDefaultsServiceProtocol = LiveUserDefaultsService()
    #endif
}

private enum HapticsServiceKey: DependencyKey {
    static let liveValue: HapticsServiceProtocol = LiveHapticsService()

    #if DEBUG
    static let previewValue: HapticsServiceProtocol = PreviewHapticsService()
    #else
    static let previewValue: HapticsServiceProtocol = LiveHapticsService()
    #endif
}

private enum NotificationServiceKey: DependencyKey {
    static let liveValue: NotificationServiceProtocol = LiveNotificationService()

    #if DEBUG
    static let previewValue: NotificationServiceProtocol = PreviewNotificationService()
    #else
    static let previewValue: NotificationServiceProtocol = LiveNotificationService()
    #endif
}

private enum ExtendedRuntimeServiceKey: DependencyKey {
    static let liveValue: ExtendedRuntimeServiceProtocol = LiveExtendedRuntimeService()

    #if DEBUG
    static let previewValue: ExtendedRuntimeServiceProtocol = PreviewExtendedRuntimeService()
    #else
    static let previewValue: ExtendedRuntimeServiceProtocol = LiveExtendedRuntimeService()
    #endif
} 