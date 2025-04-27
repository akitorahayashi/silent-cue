import Dependencies
import Foundation
import SCProtocol
import WatchKit
import XCTestDynamicOverlay

public class LiveHapticsService: HapticsServiceProtocol {
    public init() {}

    public func play(_ type: Int) {
        guard let hapticType = WKHapticType(rawValue: type) else { return }
        WKInterfaceDevice.current().play(hapticType)
    }
}
