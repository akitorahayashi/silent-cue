import XCTest
@testable import SilentCue_Watch_App
import WatchKit

class HapticTypeTests: XCTestCase {
    
    func testHapticTypeRawValues() {
        XCTAssertEqual(HapticType.standard.rawValue, "Standard")
        XCTAssertEqual(HapticType.strong.rawValue, "Strong")
        XCTAssertEqual(HapticType.weak.rawValue, "Weak")
    }
    
    func testHapticTypeIdentifier() {
        XCTAssertEqual(HapticType.standard.id, "Standard")
        XCTAssertEqual(HapticType.strong.id, "Strong")
        XCTAssertEqual(HapticType.weak.id, "Weak")
    }
    
    func testHapticTypeWKHapticType() {
        XCTAssertEqual(HapticType.standard.wkHapticType, WKHapticType.success)
        XCTAssertEqual(HapticType.strong.wkHapticType, WKHapticType.retry)
        XCTAssertEqual(HapticType.weak.wkHapticType, WKHapticType.directionUp)
    }
    
    func testHapticTypeInterval() {
        XCTAssertEqual(HapticType.standard.interval, 0.5)
        XCTAssertEqual(HapticType.strong.interval, 0.7)
        XCTAssertEqual(HapticType.weak.interval, 0.9)
    }
    
    func testHapticTypeIntensity() {
        XCTAssertEqual(HapticType.standard.intensity, 0.7)
        XCTAssertEqual(HapticType.strong.intensity, 1.0)
        XCTAssertEqual(HapticType.weak.intensity, 0.3)
    }
    
    func testCaseIterable() {
        let allCases = HapticType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.standard))
        XCTAssertTrue(allCases.contains(.strong))
        XCTAssertTrue(allCases.contains(.weak))
    }
    
    func testEquatable() {
        XCTAssertEqual(HapticType.standard, HapticType.standard)
        XCTAssertNotEqual(HapticType.standard, HapticType.strong)
        XCTAssertNotEqual(HapticType.standard, HapticType.weak)
        XCTAssertNotEqual(HapticType.strong, HapticType.weak)
    }
} 