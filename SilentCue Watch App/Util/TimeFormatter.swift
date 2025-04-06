import Foundation

enum TimeFormatter {
    static func formatTime(_ seconds: Int) -> String {
        if seconds >= 3600 {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return String(format: "%02d:%02d", hours, minutes)
        } else if seconds >= 60 {
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "%02d:%02d", minutes, secs)
        } else {
            return String(format: "00:%02d", seconds)
        }
    }
} 