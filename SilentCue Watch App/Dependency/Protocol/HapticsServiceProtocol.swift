import WatchKit

protocol HapticsServiceProtocol {
    func play(_ type: WKHapticType) async
}
