import Foundation

enum HapticType: String, Equatable, CaseIterable, Identifiable {
    case `default` = "default"
    case notification = "notification"
    case success = "success"
    case warning = "warning"
    case failure = "failure"
    
    var id: String { self.rawValue }
} 