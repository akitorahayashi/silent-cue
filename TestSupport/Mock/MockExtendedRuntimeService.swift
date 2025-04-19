import Combine
import Foundation
@testable import SilentCue_Watch_App // Import the main module to access the protocol

/// ExtendedRuntimeServiceProtocol のモック実装
class MockExtendedRuntimeService: ExtendedRuntimeServiceProtocol {
    // MARK: - 呼び出し記録

    var startSessionCallCount = 0
    var startSessionLastParams: (duration: TimeInterval, targetEndTime: Date?, completionHandler: (() -> Void)?)?
    var stopSessionCallCount = 0
    var checkAndClearBackgroundCompletionFlagCallCount = 0

    // MARK: - スタブ設定

    /// checkAndClearBackgroundCompletionFlag の戻り値を設定します。
    var checkAndClearBackgroundCompletionFlagReturnValue = false

    /// startSession の completionHandler を即座に呼び出すかどうかを設定します。
    var shouldCallStartSessionCompletionImmediately = false

    // MARK: - Protocol Conformance

    func startSession(duration: TimeInterval, targetEndTime: Date?, completionHandler: (() -> Void)?) {
        startSessionCallCount += 1
        startSessionLastParams = (duration, targetEndTime, completionHandler)
        if shouldCallStartSessionCompletionImmediately {
            completionHandler?()
        }
    }

    func stopSession() {
        stopSessionCallCount += 1
    }

    func checkAndClearBackgroundCompletionFlag() -> Bool {
        checkAndClearBackgroundCompletionFlagCallCount += 1
        return checkAndClearBackgroundCompletionFlagReturnValue
    }

    // MARK: - テスト用リセット

    func reset() {
        startSessionCallCount = 0
        startSessionLastParams = nil
        stopSessionCallCount = 0
        checkAndClearBackgroundCompletionFlagCallCount = 0
        checkAndClearBackgroundCompletionFlagReturnValue = false
        shouldCallStartSessionCompletionImmediately = false
    }
}
