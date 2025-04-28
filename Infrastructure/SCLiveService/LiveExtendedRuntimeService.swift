import ComposableArchitecture
import Dependencies
import Foundation
import SCProtocol
import WatchKit

public class LiveExtendedRuntimeService: NSObject, WKExtendedRuntimeSessionDelegate, ExtendedRuntimeServiceProtocol {
    private var session: WKExtendedRuntimeSession?
    private var sessionContinuation: CheckedContinuation<Bool, Never>?
    private var expirationHandler: (() -> Void)?

    // Expose completion events as a public AsyncStream
    private let completionStreamContinuation: AsyncStream<Void>.Continuation
    public let completionEvents: AsyncStream<Void>

    override public init() {
        var streamContinuation: AsyncStream<Void>.Continuation?
        completionEvents = AsyncStream { continuation in
            streamContinuation = continuation
        }
        completionStreamContinuation = streamContinuation!
        super.init()
    }

    /// 拡張ランタイムセッションを開始する
    public func startSession(duration _: TimeInterval, targetEndTime _: Date?) {
        Task {
            _ = await startSession()
        }
    }

    /// 拡張ランタイムセッションを開始する
    public func startSession() async -> Bool {
        let newSession = WKExtendedRuntimeSession()

        guard newSession.state == WKExtendedRuntimeSessionState.notStarted else {
            return false
        }
        session = newSession
        session?.delegate = self

        return await withCheckedContinuation { continuation in
            self.sessionContinuation = continuation
            session?.start()
        }
    }

    /// 拡張ランタイムセッションを停止する
    public func invalidateSession() {
        session?.invalidate()
        session = nil
        sessionContinuation = nil // Clean up continuation
        // completionStreamContinuation.finish() // Should this finish here?
    }

    public func stopSession() {
        // Alias for invalidateSession based on potential older protocol versions
        invalidateSession()
    }

    public func getSessionState() -> Int {
        session?.state.rawValue ?? WKExtendedRuntimeSessionState.invalid.rawValue
    }

    // MARK: - WKExtendedRuntimeSessionDelegate

    public func extendedRuntimeSessionDidStart(_: WKExtendedRuntimeSession) {
        sessionContinuation?.resume(returning: true)
        sessionContinuation = nil // Clean up continuation
    }

    public func extendedRuntimeSessionWillExpire(_: WKExtendedRuntimeSession) {
        // Handle expiration if needed, perhaps call the expirationHandler
        expirationHandler?()
    }

    public func extendedRuntimeSession(
        _: WKExtendedRuntimeSession,
        didInvalidateWith _: WKExtendedRuntimeSessionInvalidationReason,
        error _: Error?
    ) {
        sessionContinuation?.resume(returning: false) // Indicate failure or invalidation
        sessionContinuation = nil // Clean up continuation
        session = nil
        completionStreamContinuation.yield(())
        // completionStreamContinuation.finish() // Finish stream on invalidation
    }

    public func extendedRuntimeSession(_: WKExtendedRuntimeSession, ranOutOfBackgroundTimeWith _: TimeInterval) {
        // Handle running out of background time if needed
        // completionStreamContinuation.yield(())
        // completionStreamContinuation.finish() // Maybe finish here too?
    }
}
