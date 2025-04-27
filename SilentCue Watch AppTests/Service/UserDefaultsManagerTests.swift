import SCMock
import SCShared
@testable import SilentCue_Watch_App
import XCTest

final class UserDefaultsManagerTests: XCTestCase {
    var mockUserDefaultsManager: MockUserDefaultsManager!

    override func setUp() {
        super.setUp()
        mockUserDefaultsManager = MockUserDefaultsManager()
    }

    override func tearDown() {
        mockUserDefaultsManager.removeAll()
        mockUserDefaultsManager = nil
        super.tearDown()
    }

    // 様々な型の値の設定と取得を検証
    func testSetAndGetObject() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        let valueBool = true
        mockUserDefaultsManager.set(valueBool, forKey: keyBool)
        XCTAssertEqual(mockUserDefaultsManager.object(forKey: keyBool) as? Bool, valueBool)

        let keyString = UserDefaultsKeys.hapticType
        let valueString = "strong"
        mockUserDefaultsManager.set(valueString, forKey: keyString)
        XCTAssertEqual(mockUserDefaultsManager.object(forKey: keyString) as? String, valueString)

        // Mock固有のメソッドで内部状態を確認する
        let internalStorage = mockUserDefaultsManager.getAllValues()
        XCTAssertEqual(internalStorage[keyBool.rawValue] as? Bool, valueBool)
        XCTAssertEqual(internalStorage[keyString.rawValue] as? String, valueString)
    }

    // 指定したキーの値の削除を検証
    func testRemoveObject() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        let keyString = UserDefaultsKeys.hapticType
        mockUserDefaultsManager.set(true, forKey: keyBool)
        mockUserDefaultsManager.set("testHaptic", forKey: keyString)

        mockUserDefaultsManager.remove(forKey: keyBool)
        XCTAssertNil(mockUserDefaultsManager.object(forKey: keyBool))
        XCTAssertNotNil(mockUserDefaultsManager.object(forKey: keyString)) // Stringはまだ存在
        XCTAssertNil(mockUserDefaultsManager.getAllValues()[keyBool.rawValue])

        mockUserDefaultsManager.remove(forKey: keyString)
        XCTAssertNil(mockUserDefaultsManager.object(forKey: keyString))
        XCTAssertTrue(mockUserDefaultsManager.getAllValues().isEmpty) // 両方削除されたので空のはず
    }

    // 全てのキーと値の削除を検証
    func testRemoveAll() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        let keyString = UserDefaultsKeys.hapticType
        mockUserDefaultsManager.set(true, forKey: keyBool)
        mockUserDefaultsManager.set("testHaptic", forKey: keyString)

        XCTAssertFalse(mockUserDefaultsManager.getAllValues().isEmpty) // 値があることを確認
        mockUserDefaultsManager.removeAll()

        XCTAssertNil(mockUserDefaultsManager.object(forKey: keyBool))
        XCTAssertNil(mockUserDefaultsManager.object(forKey: keyString))
        XCTAssertTrue(mockUserDefaultsManager.getAllValues().isEmpty) // removeAll で空になることを確認
    }

    // 値に nil を設定するとキーが削除されるか検証
    func testSetNilRemovesObject() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        mockUserDefaultsManager.set(true, forKey: keyBool)
        XCTAssertNotNil(mockUserDefaultsManager.object(forKey: keyBool))

        // nilを設定するとオブジェクトが削除されるはず
        mockUserDefaultsManager.set(nil, forKey: keyBool)
        XCTAssertNil(mockUserDefaultsManager.object(forKey: keyBool))
        XCTAssertNil(mockUserDefaultsManager.getAllValues()[keyBool.rawValue])
    }

    // 存在しないキーの値を取得すると nil が返るか検証
    func testGetObjectNotFound() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        XCTAssertNil(mockUserDefaultsManager.object(forKey: keyBool))
    }
}
