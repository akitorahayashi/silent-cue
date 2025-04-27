import Foundation
import Dependencies

public protocol ExtendedRuntimeServiceProtocol {
    var completionEvents: AsyncStream<Void> { get }

    func startSession(duration: TimeInterval, targetEndTime: Date?)

    func stopSession()

    func startSession() async -> Bool
    func invalidateSession()
    func getSessionState() -> Int // WKExtendedRuntimeSessionState is Int
}
