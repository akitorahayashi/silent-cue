@testable import SilentCue_Watch_App
import XCTest

// Test class renamed
class UserDefaultsServiceTests: XCTestCase {
    var userDefaultsService: UserDefaultsServiceProtocol! // Update type and name

    override func setUp() {
        super.setUp()
        // Instantiate the live service implementation
        userDefaultsService = LiveUserDefaultsService() // Use new class name
        // Clean up UserDefaults before each test
        userDefaultsService.removeAll()
    }

    override func tearDown() {
        // Clean up UserDefaults after each test
        userDefaultsService.removeAll()
        userDefaultsService = nil // Update name
        super.tearDown()
    }

    // MARK: - Test Cases

    func testSetAndGetObject() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        let valueBool = true
        userDefaultsService.set(valueBool, forKey: keyBool) // Update usage
        XCTAssertEqual(userDefaultsService.object(forKey: keyBool) as? Bool, valueBool) // Update usage

        let keyString = UserDefaultsKeys.hapticType
        let valueString = "strong"
        userDefaultsService.set(valueString, forKey: keyString) // Update usage
        XCTAssertEqual(userDefaultsService.object(forKey: keyString) as? String, valueString) // Update usage
    }

    func testRemoveObject() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        let keyString = UserDefaultsKeys.hapticType
        userDefaultsService.set(true, forKey: keyBool) // Update usage
        userDefaultsService.set("testHaptic", forKey: keyString) // Update usage

        userDefaultsService.remove(forKey: keyBool) // Update usage
        XCTAssertNil(userDefaultsService.object(forKey: keyBool)) // Update usage
        XCTAssertNotNil(userDefaultsService.object(forKey: keyString)) // Update usage

        userDefaultsService.remove(forKey: keyString) // Update usage
        XCTAssertNil(userDefaultsService.object(forKey: keyString)) // Update usage
    }

    func testRemoveAll() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        let keyString = UserDefaultsKeys.hapticType
        userDefaultsService.set(true, forKey: keyBool) // Update usage
        userDefaultsService.set("testHaptic", forKey: keyString) // Update usage

        userDefaultsService.removeAll() // Update usage

        for item in UserDefaultsKeys.allCases {
            XCTAssertNil(userDefaultsService.object(forKey: item)) // Update usage
        }
    }

    func testSetNilRemovesObject() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        userDefaultsService.set(true, forKey: keyBool) // Update usage
        XCTAssertNotNil(userDefaultsService.object(forKey: keyBool)) // Update usage

        // Setting nil should remove the object
        userDefaultsService.set(nil, forKey: keyBool) // Update usage
        XCTAssertNil(userDefaultsService.object(forKey: keyBool)) // Update usage
    }

    func testGetObjectNotFound() {
        let keyBool = UserDefaultsKeys.isFirstLaunch
        XCTAssertNil(userDefaultsService.object(forKey: keyBool)) // Update usage
    }
}
