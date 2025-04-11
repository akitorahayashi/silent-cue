import XCTest
@testable import SilentCue_Watch_App

class UserDefaultsManagerTests: XCTestCase {
    
    class MockUserDefaultsManager: UserDefaultsManagerProtocol {
        var storage: [UserDefaultsKeys: Any] = [:]
        
        func object(forKey defaultName: UserDefaultsKeys) -> Any? {
            return storage[defaultName]
        }
        
        func set(_ value: Any?, forKey defaultName: UserDefaultsKeys) {
            storage[defaultName] = value
        }
        
        func remove(forKey defaultName: UserDefaultsKeys) {
            storage.removeValue(forKey: defaultName)
        }
        
        func removeAll() {
            storage.removeAll()
        }
    }
    
    var mockManager: MockUserDefaultsManager!
    
    override func setUp() {
        super.setUp()
        mockManager = MockUserDefaultsManager()
    }
    
    func testSetAndGet() {
        // 文字列の保存と取得
        mockManager.set("テスト値", forKey: .hapticType)
        XCTAssertEqual(mockManager.object(forKey: .hapticType) as? String, "テスト値")
        
        // Bool値の保存と取得
        mockManager.set(true, forKey: .stopVibrationAutomatically)
        XCTAssertEqual(mockManager.object(forKey: .stopVibrationAutomatically) as? Bool, true)
        
        // 上書き
        mockManager.set("新しい値", forKey: .hapticType)
        XCTAssertEqual(mockManager.object(forKey: .hapticType) as? String, "新しい値")
    }
    
    func testRemove() {
        // データを設定
        mockManager.set("テスト値", forKey: .hapticType)
        mockManager.set(true, forKey: .stopVibrationAutomatically)
        
        // 1つのキーを削除
        mockManager.remove(forKey: .hapticType)
        XCTAssertNil(mockManager.object(forKey: .hapticType))
        XCTAssertNotNil(mockManager.object(forKey: .stopVibrationAutomatically))
        
        // すべてのキーを削除
        mockManager.removeAll()
        XCTAssertNil(mockManager.object(forKey: .stopVibrationAutomatically))
    }
    
    func testNilValue() {
        // 未設定の場合はnilが返る
        XCTAssertNil(mockManager.object(forKey: .hapticType))
        
        // 値を設定してからnilを設定
        mockManager.set("テスト値", forKey: .hapticType)
        XCTAssertNotNil(mockManager.object(forKey: .hapticType))
        
        mockManager.set(nil, forKey: .hapticType)
        XCTAssertNil(mockManager.object(forKey: .hapticType))
    }
} 