import ComposableArchitecture
import SCProtocol

extension DependencyValues {
    // UserDefaultsService
    var userDefaultsService: UserDefaultsServiceProtocol {
        get { self[UserDefaultsServiceKey.self] }
        set { self[UserDefaultsServiceKey.self] = newValue }
    }

    // HapticsService
    var hapticsService: HapticsServiceProtocol {
        get { self[HapticsServiceKey.self] }
        set { self[HapticsServiceKey.self] = newValue }
    }

    // NotificationService
    var notificationService: NotificationServiceProtocol {
        get { self[NotificationServiceKey.self] }
        set { self[NotificationServiceKey.self] = newValue }
    }

    // ExtendedRuntimeService
    var extendedRuntimeService: ExtendedRuntimeServiceProtocol {
        get { self[ExtendedRuntimeServiceKey.self] }
        set { self[ExtendedRuntimeServiceKey.self] = newValue }
    }
}
