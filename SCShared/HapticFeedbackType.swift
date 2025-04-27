import Foundation

public enum HapticFeedbackType: String, CaseIterable, Identifiable {
    case start
    case success
    case failure

    public var id: String { rawValue }
}
