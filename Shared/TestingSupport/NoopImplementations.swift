import Foundation
@testable import SilentCue_Watch_App // For accessing protocols
import WatchKit // For WKHapticType

// MARK: - No-operation Implementations

/// 何もしない `NotificationServiceProtocol` の実装。
/// 主にプレビューや、テストで通知機能が不要な場合に使用します。
struct NoopNotificationService: NotificationServiceProtocol {
    /// 何も実行しません。
    func requestAuthorization(completion: @escaping (Bool) -> Void) { completion(false) }
    /// 何も実行せず、`false` を返します。
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) { completion(false) }
    /// 何も実行しません。
    func scheduleTimerCompletionNotification(at _: Date, minutes _: Int) {}
    /// 何も実行しません。
    func cancelTimerCompletionNotification() {}

    /// イニシャライザ。
    init() {}
}

/// 何もしない `ExtendedRuntimeServiceProtocol` の実装。
/// 主にプレビューや、テストで拡張ランタイム機能が不要な場合に使用します。
struct NoopExtendedRuntimeService: ExtendedRuntimeServiceProtocol {
    /// 何も実行しません。
    func startSession(duration _: TimeInterval, targetEndTime _: Date?, completionHandler _: (() -> Void)?) {}
    /// 何も実行しません。
    func stopSession() {}
    /// 何も実行せず、`false` を返します。
    func checkAndClearBackgroundCompletionFlag() -> Bool { false }

    /// イニシャライザ。
    init() {}
}

/// 何もしない `HapticsServiceProtocol` の実装。
/// 主にプレビューや、テストで触覚フィードバック機能が不要な場合に使用します。
struct NoopHapticsService: HapticsServiceProtocol {
    /// 何も実行しません。
    func play(_: WKHapticType) async {}

    /// イニシャライザ。
    init() {}
}
