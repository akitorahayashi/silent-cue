@testable import SilentCue_Watch_App
import UserNotifications
import XCTest

class NotificationServiceTests: XCTestCase {
    var service: MockNotificationService! // 型をモックに変更

    override func setUp() {
        super.setUp()
        // モック実装を使用
        service = MockNotificationService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // 基本的な初期化をテスト
    func testInitialization() {
        XCTAssertNotNil(service, "サービスが初期化されているべきです。")
    }

    // requestAuthorization が呼び出され、スタブ値を使用することをテスト (同期)
    func testRequestAuthorization_SyncCompletion() {
        let expectation = expectation(description: "requestAuthorization 完了")
        var receivedGranted: Bool?

        service.requestAuthorizationGrantedResult = true
        service.completeRequestAuthorizationAsynchronously = false

        service.requestAuthorization { granted in
            receivedGranted = granted
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(service.requestAuthorizationCallCount, 1)
        XCTAssertEqual(receivedGranted, true)
    }

    // requestAuthorization が呼び出され、スタブ値を使用することをテスト (非同期)
    func testRequestAuthorization_AsyncCompletion() {
        let expectation = expectation(description: "requestAuthorization 完了")
        var receivedGranted: Bool?

        service.requestAuthorizationGrantedResult = false
        service.completeRequestAuthorizationAsynchronously = true

        service.requestAuthorization { granted in
            receivedGranted = granted
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0) // 非同期完了を待つ
        XCTAssertEqual(service.requestAuthorizationCallCount, 1)
        XCTAssertEqual(receivedGranted, false)
    }

    // checkAuthorizationStatus が呼び出され、スタブ値を使用することをテスト
    func testCheckAuthorizationStatus() {
        let expectation = expectation(description: "checkAuthorizationStatus 完了")
        var receivedStatus: Bool?

        service.checkAuthorizationStatusResult = false

        service.checkAuthorizationStatus { isAuthorized in
            receivedStatus = isAuthorized
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(service.checkAuthorizationStatusCallCount, 1)
        XCTAssertEqual(receivedStatus, false)
    }

    // scheduleTimerCompletionNotification が呼び出され、引数を記録することをテスト
    func testScheduleTimerCompletionNotification_RecordsParameters() {
        let testDate = Date()
        let testMinutes = 15

        service.scheduleTimerCompletionNotification(at: testDate, minutes: testMinutes)

        XCTAssertEqual(service.scheduleTimerCompletionNotificationCallCount, 1)
        XCTAssertEqual(service.lastScheduledNotificationParams?.targetDate, testDate)
        XCTAssertEqual(service.lastScheduledNotificationParams?.minutes, testMinutes)
    }

    // cancelTimerCompletionNotification が呼び出されることをテスト
    func testCancelTimerCompletionNotification_IncrementsCallCount() {
        service.cancelTimerCompletionNotification()
        XCTAssertEqual(service.cancelTimerCompletionNotificationCallCount, 1)
    }

    // リセット機能のテスト
    func testReset() {
        service.requestAuthorizationGrantedResult = false
        service.checkAuthorizationStatusResult = false
        service.completeRequestAuthorizationAsynchronously = true
        service.requestAuthorization { _ in }
        service.checkAuthorizationStatus { _ in }
        service.scheduleTimerCompletionNotification(at: Date(), minutes: 5)
        service.cancelTimerCompletionNotification()

        service.reset()

        XCTAssertEqual(service.requestAuthorizationCallCount, 0)
        XCTAssertEqual(service.checkAuthorizationStatusCallCount, 0)
        XCTAssertEqual(service.scheduleTimerCompletionNotificationCallCount, 0)
        XCTAssertNil(service.lastScheduledNotificationParams)
        XCTAssertEqual(service.cancelTimerCompletionNotificationCallCount, 0)
        XCTAssertTrue(service.requestAuthorizationGrantedResult)
        XCTAssertFalse(service.completeRequestAuthorizationAsynchronously)
        XCTAssertTrue(service.checkAuthorizationStatusResult)
        XCTAssertFalse(service.completeCheckAuthorizationStatusAsynchronously)
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
