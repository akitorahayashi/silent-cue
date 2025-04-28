import SCMock
@testable import SilentCue_Watch_App
import UserNotifications
import XCTest

final class NotificationServiceTests: XCTestCase {
    var service: MockNotificationService!

    @MainActor // Add MainActor since setup involves UI-related mock setup potentially
    override func setUp() {
        super.setUp()
        service = MockNotificationService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // Test requesting authorization successfully
    func testRequestAuthorization_Success() async {
        service.requestAuthorizationShouldSucceed = true

        let granted = await service.requestAuthorization()

        XCTAssertEqual(service.requestAuthorizationCallCount, 1)
        XCTAssertTrue(granted)
        XCTAssertEqual(service.mockAuthorizationStatus, .authorized) // Check if status updated
    }

    // Test requesting authorization failure
    func testRequestAuthorization_Failure() async {
        service.requestAuthorizationShouldSucceed = false

        let granted = await service.requestAuthorization()

        XCTAssertEqual(service.requestAuthorizationCallCount, 1)
        XCTAssertFalse(granted)
        // Status should remain as it was or become denied, depending on exact mock logic
        // Let's assume it stays notDetermined if it fails before prompting
        XCTAssertEqual(service.mockAuthorizationStatus, .notDetermined)
    }

    // Test checking authorization status when authorized
    func testGetAuthorizationStatus_Authorized() async {
        service.mockAuthorizationStatus = .authorized

        let status = await service.getAuthorizationStatus()

        XCTAssertEqual(service.getAuthorizationStatusCallCount, 1)
        XCTAssertEqual(status, .authorized)
    }

    // Test checking authorization status when denied
    func testGetAuthorizationStatus_Denied() async {
        service.mockAuthorizationStatus = .denied

        let status = await service.getAuthorizationStatus()

        XCTAssertEqual(service.getAuthorizationStatusCallCount, 1)
        XCTAssertEqual(status, .denied)
    }

    // Test scheduling a notification (using the add method)
    func testScheduleNotification_AddsRequest() async throws {
        let identifier = "testTimer"
        let content = UNMutableNotificationContent()
        content.title = "Test"
        content.body = "Test Body"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)

        try await service.add(identifier: identifier, content: content, trigger: trigger)

        XCTAssertEqual(service.addRequestCallCount, 1)
        XCTAssertEqual(service.addedRequests.count, 1)
        XCTAssertEqual(service.addedRequests.first?.identifier, identifier)
        XCTAssertEqual(service.addedRequests.first?.content.title, "Test")
        XCTAssertNotNil(service.addedRequests.first?.trigger as? UNTimeIntervalNotificationTrigger)
    }

    // Test scheduling a notification when adding should throw an error
    func testScheduleNotification_ThrowsError() async {
        let identifier = "testErrorTimer"
        let content = UNMutableNotificationContent()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let expectedError = NSError(domain: "TestError", code: 123, userInfo: nil)
        service.addRequestShouldThrowError = expectedError

        do {
            try await service.add(identifier: identifier, content: content, trigger: trigger)
            XCTFail("Expected add method to throw an error, but it did not.")
        } catch {
            XCTAssertEqual(service.addRequestCallCount, 1)
            XCTAssertEqual(error as NSError, expectedError)
            XCTAssertTrue(service.addedRequests.isEmpty)
        }
    }

    // Test cancelling a specific notification
    func testCancelSpecificNotification_RemovesRequest() async throws {
        // Add a request first
        let identifier1 = "timer1"
        let identifier2 = "timer2"
        let content = UNMutableNotificationContent()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        try await service.add(identifier: identifier1, content: content, trigger: trigger)
        try await service.add(identifier: identifier2, content: content, trigger: trigger)
        XCTAssertEqual(service.addedRequests.count, 2)

        service.removePendingNotificationRequests(withIdentifiers: [identifier1])

        XCTAssertEqual(service.removePendingRequestsCallCount, 1)
        XCTAssertEqual(service.removedRequestIdentifiers, [identifier1])
        XCTAssertEqual(service.addedRequests.count, 1)
        XCTAssertEqual(service.addedRequests.first?.identifier, identifier2)
    }

    // Test cancelling all notifications
    func testCancelAllNotifications_RemovesAllRequests() async throws {
        // Add some requests first
        let identifier1 = "timer1"
        let identifier2 = "timer2"
        let content = UNMutableNotificationContent()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        try await service.add(identifier: identifier1, content: content, trigger: trigger)
        try await service.add(identifier: identifier2, content: content, trigger: trigger)
        XCTAssertEqual(service.addedRequests.count, 2)

        service.removeAllPendingNotificationRequests()

        XCTAssertEqual(service.removeAllPendingRequestsCallCount, 1)
        // Check if removed identifiers contains the ones added (order might vary)
        XCTAssertTrue(service.removedRequestIdentifiers.contains(identifier1))
        XCTAssertTrue(service.removedRequestIdentifiers.contains(identifier2))
        XCTAssertTrue(service.addedRequests.isEmpty)
    }

    // Test if the mock state resets correctly
    @MainActor // Ensure reset happens on main actor if it interacts with properties potentially accessed from main
    func testReset() async throws {
        // Setup some state
        service.mockAuthorizationStatus = .denied
        service.requestAuthorizationShouldSucceed = false
        service.addRequestShouldThrowError = NSError(domain: "Test", code: 1)
        _ = await service.requestAuthorization()
        _ = await service.getAuthorizationStatus()
        try? await service.add(
            identifier: "t1",
            content: .init(),
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        service.removePendingNotificationRequests(withIdentifiers: ["t1"])
        service.removeAllPendingNotificationRequests() // Call remove all as well

        // Reset
        service.reset()

        // Verify initial state
        XCTAssertEqual(service.requestAuthorizationCallCount, 0)
        XCTAssertEqual(service.getAuthorizationStatusCallCount, 0)
        XCTAssertEqual(service.addRequestCallCount, 0)
        XCTAssertEqual(service.removePendingRequestsCallCount, 0)
        XCTAssertEqual(service.removeAllPendingRequestsCallCount, 0)
        XCTAssertTrue(service.addedRequests.isEmpty)
        XCTAssertTrue(service.removedRequestIdentifiers.isEmpty)
        XCTAssertEqual(service.mockAuthorizationStatus, .notDetermined)
        XCTAssertTrue(service.requestAuthorizationShouldSucceed)
        XCTAssertNil(service.addRequestShouldThrowError)
    }
}

/*
 // モック構造の例
 class MockUNUserNotificationCenter {
     var authorizationRequested = false
     var requestedOptions: UNAuthorizationOptions? = nil
     var settingsToReturn: UNNotificationSettings = /* モック設定を提供 */
     var addedRequests: [UNNotificationRequest] = []
     var removedIdentifiers: [String] = []

     func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
         authorizationRequested = true
         requestedOptions = options
         // 応答をシミュレート
         DispatchQueue.main.async {
             completionHandler(true, nil) // または false、またはエラー付き
         }
     }

     func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void) {
         DispatchQueue.main.async {
             completionHandler(settingsToReturn)
         }
     }

     func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
         addedRequests.append(request)
         DispatchQueue.main.async {
             completionHandler?(nil) // 成功またはエラーをシミュレート
         }
     }

     func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
         removedIdentifiers.append(contentsOf: identifiers)
     }

     // 必要に応じて他の UNUserNotificationCenter メソッドをモックします
 }
 */
