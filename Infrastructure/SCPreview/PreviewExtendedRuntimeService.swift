#if DEBUG

    import Dependencies
    import Foundation
    import SCProtocol
    import WatchKit // For WKExtendedRuntimeSessionState

    // Preview用のExtendedRuntimeService実装
    public class PreviewExtendedRuntimeService: ExtendedRuntimeServiceProtocol {
        // Expose a dummy stream for preview
        public let completionEvents: AsyncStream<Void> = AsyncStream { _ in }
        private var sessionState: WKExtendedRuntimeSessionState = .notStarted

        public init() {}

        public func startSession() async -> Bool {
            // プレビューでは常に成功したと仮定、または特定の状態をシミュレート
            print("PreviewExtendedRuntimeService: Starting session (simulating success).")
            sessionState = .running
            return true
        }

        public func startSession(duration _: TimeInterval, targetEndTime _: Date?) {
            // Handle legacy/alternate signature if necessary
            print("PreviewExtendedRuntimeService: Legacy startSession(duration:targetEndTime:) called.")
            Task { let _ = await startSession() } // Simulate starting via the async method
        }

        public func invalidateSession() {
            print("PreviewExtendedRuntimeService: Invalidating session.")
            sessionState = .invalid
            // Potentially yield completion event if needed for preview testing
        }

        public func stopSession() {
            invalidateSession()
        }

        public func getSessionState() -> Int {
            print("PreviewExtendedRuntimeService: Getting session state: \(sessionState).")
            return sessionState.rawValue
        }
    }

#endif
