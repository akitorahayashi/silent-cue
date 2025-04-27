import Foundation
import SCProtocol
import Dependencies
import UserNotifications

// Mock implementation for NotificationServiceProtocol
public class MockNotificationService: NotificationServiceProtocol {
    // Control properties for testing
    public var mockAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    public var requestAuthorizationShouldSucceed: Bool = true
    public var addRequestShouldThrowError: Error? = nil

    // Track calls and data for verification
    public var requestAuthorizationCallCount = 0
    public var getAuthorizationStatusCallCount = 0
    public var addRequestCallCount = 0
    public var removePendingRequestsCallCount = 0
    public var removeAllPendingRequestsCallCount = 0
    public var addedRequests: [(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger)] = []
    public var removedRequestIdentifiers: [String] = []

    public init() {}

    public func requestAuthorization() async -> Bool {
        requestAuthorizationCallCount += 1
        print("MockNotificationService: Requesting authorization (will return \(requestAuthorizationShouldSucceed))")
        if requestAuthorizationShouldSucceed {
            mockAuthorizationStatus = .authorized // Simulate granting authorization
        }
        return requestAuthorizationShouldSucceed
    }

    public func getAuthorizationStatus() async -> UNAuthorizationStatus {
        getAuthorizationStatusCallCount += 1
        print("MockNotificationService: Getting authorization status: \(mockAuthorizationStatus)")
        return mockAuthorizationStatus
    }

    public func add(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger) async throws {
        addRequestCallCount += 1
        if let error = addRequestShouldThrowError {
            print("MockNotificationService: Adding request ID \(identifier) (will throw error)")
            throw error
        }
        print("MockNotificationService: Adding request ID \(identifier)")
        addedRequests.append((identifier, content, trigger))
    }

    public func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removePendingRequestsCallCount += 1
        removedRequestIdentifiers.append(contentsOf: identifiers)
        addedRequests.removeAll { identifiers.contains($0.identifier) }
        print("MockNotificationService: Removing pending requests: IDs \(identifiers)")
    }

    public func removeAllPendingNotificationRequests() {
        removeAllPendingRequestsCallCount += 1
        removedRequestIdentifiers.append(contentsOf: addedRequests.map { $0.identifier })
        addedRequests.removeAll()
        print("MockNotificationService: Removing all pending requests")
    }

    // Reset function for testing
    public func reset() {
        mockAuthorizationStatus = .notDetermined
        requestAuthorizationShouldSucceed = true
        addRequestShouldThrowError = nil
        requestAuthorizationCallCount = 0
        getAuthorizationStatusCallCount = 0
        addRequestCallCount = 0
        removePendingRequestsCallCount = 0
        removeAllPendingRequestsCallCount = 0
        addedRequests.removeAll()
        removedRequestIdentifiers.removeAll()
    }
}
