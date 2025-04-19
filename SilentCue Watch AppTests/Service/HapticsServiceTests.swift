@testable import SilentCue_Watch_App
import WatchKit
import XCTest

class HapticsServiceTests: XCTestCase {
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

    // モックの状態がリセットされるか
    func testReset() async {
        await service.play(.start)
        await service.play(.stop)

        service.reset()

        XCTAssertEqual(service.playCallCount, 0)
        XCTAssertNil(service.lastPlayedHapticType)
        XCTAssertTrue(service.playedHapticTypes.isEmpty)
    }
}
