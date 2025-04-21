import Combine
import Foundation
@testable import SilentCue_Watch_App

class MockExtendedRuntimeService: ExtendedRuntimeServiceProtocol {
    // Completion Stream
    private var completionContinuation: AsyncStream<Void>.Continuation?
    private(set) lazy var completionEvents: AsyncStream<Void> = AsyncStream { continuation in
        self.completionContinuation = continuation
    }

    // 呼び出し記録
    var startSessionCallCount = 0
    var startSessionLastParams: (duration: TimeInterval, targetEndTime: Date?)?
    var stopSessionCallCount = 0
    var checkAndClearBackgroundCompletionFlagCallCount = 0

    // スタブ設定
    /// checkAndClearBackgroundCompletionFlag の戻り値を設定します。
    var checkAndClearBackgroundCompletionFlagReturnValue = false

    // Protocol Conformance
    func startSession(duration: TimeInterval, targetEndTime: Date?) {
        startSessionCallCount += 1
        startSessionLastParams = (duration, targetEndTime)
    }

    func stopSession() {
        stopSessionCallCount += 1
    }

    /// テストから完了イベントを発行
    func triggerCompletion() {
        completionContinuation?.yield(())
        // 通常、完了したらストリームは終了する
        completionContinuation?.finish()
        completionContinuation = nil // 再利用を防ぐ
    }

    func reset() {
        startSessionCallCount = 0
        startSessionLastParams = nil
        stopSessionCallCount = 0
        checkAndClearBackgroundCompletionFlagCallCount = 0
        checkAndClearBackgroundCompletionFlagReturnValue = false

        // ストリームの継続を終了させ、nilにする
        completionContinuation?.finish()
        completionContinuation = nil
        // ストリーム自体を再生成 (次にアクセスされたときに新しい continuation が作られる)
        completionEvents = AsyncStream { continuation in
            self.completionContinuation = continuation
        }
    }
}
