import SCMock
@testable import SilentCue_Watch_App
import WatchKit
import XCTest

final class HapticsServiceTests: XCTestCase {
    var service: MockHapticsService!

    override func setUp() {
        super.setUp()
        service = MockHapticsService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // ハプティクス再生時にタイプが記録され、呼び出し回数が増加するか
    func testPlayHaptic_RecordsTypeAndIncrementsCount() {
        let hapticType1: WKHapticType = .success
        let hapticType2: WKHapticType = .failure

        // 最初の呼び出し
        service.play(hapticType1.rawValue)
        XCTAssertEqual(service.playCallCount, 1)
        XCTAssertEqual(service.lastPlayedHapticType, hapticType1)
        XCTAssertEqual(service.playedHapticTypes, [hapticType1.rawValue])

        // ２回目の呼び出し
        service.play(hapticType2.rawValue)
        XCTAssertEqual(service.playCallCount, 2)
        XCTAssertEqual(service.lastPlayedHapticType, hapticType2)
        XCTAssertEqual(service.playedHapticTypes, [hapticType1.rawValue, hapticType2.rawValue])
    }

    // モックの状態がリセットされるか
    func testReset() async {
        service.play(WKHapticType.start.rawValue)
        service.play(WKHapticType.stop.rawValue)

        service.reset()

        XCTAssertEqual(service.playCallCount, 0)
        XCTAssertNil(service.lastPlayedHapticType)
        XCTAssertTrue(service.playedHapticTypes.isEmpty)
    }
}
