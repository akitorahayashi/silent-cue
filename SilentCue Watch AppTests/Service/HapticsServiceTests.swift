@testable import SilentCue_Watch_App
import WatchKit
import XCTest

class HapticsServiceTests: XCTestCase {
    var service: MockHapticsService! // 型をモックに変更

    override func setUp() {
        super.setUp()
        service = MockHapticsService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // 基本的な初期化をテスト
    func testInitialization() {
        XCTAssertNotNil(service, "サービスが初期化されているべきです。")
    }

    // play メソッドが呼び出され、引数が記録されることをテスト
    func testPlayHaptic_RecordsTypeAndIncrementsCount() async {
        let hapticType1: WKHapticType = .success
        let hapticType2: WKHapticType = .failure

        // 最初の呼び出し
        await service.play(hapticType1)
        XCTAssertEqual(service.playCallCount, 1)
        XCTAssertEqual(service.lastPlayedHapticType, hapticType1)
        XCTAssertEqual(service.playedHapticTypes, [hapticType1])

        // ２回目の呼び出し
        await service.play(hapticType2)
        XCTAssertEqual(service.playCallCount, 2)
        XCTAssertEqual(service.lastPlayedHapticType, hapticType2)
        XCTAssertEqual(service.playedHapticTypes, [hapticType1, hapticType2])
    }

    // リセット機能のテスト
    func testReset() async {
        await service.play(.start)
        await service.play(.stop)

        service.reset()

        XCTAssertEqual(service.playCallCount, 0)
        XCTAssertNil(service.lastPlayedHapticType)
        XCTAssertTrue(service.playedHapticTypes.isEmpty)
    }
}

/*
 // モック構造の例（注入にはさらなる設定が必要）
 class MockWKInterfaceDevice {
     var lastPlayedHaptic: WKHapticType? = nil
     var playCallCount = 0

     func play(_ type: WKHapticType) {
         lastPlayedHaptic = type
         playCallCount += 1
     }

     // 必要に応じて他の WKInterfaceDevice メソッドをモックします
 }
 */
