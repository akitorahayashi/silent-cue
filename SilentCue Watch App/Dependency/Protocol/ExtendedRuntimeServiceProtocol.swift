import Foundation

protocol ExtendedRuntimeServiceProtocol {
    var completionEvents: AsyncStream<Void> { get }

    func startSession(duration: TimeInterval, targetEndTime: Date?)

    func stopSession()
}
