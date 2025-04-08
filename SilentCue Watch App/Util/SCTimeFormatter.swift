import Foundation

enum SCTimeFormatter {
    static func formatSecondsToTimeString(_ seconds: Int) -> String {
        if seconds >= 3600 {
            let hours = seconds / 3600
            let remainingSeconds = seconds % 3600
            
            // 秒数が0でない場合は分を切り上げる
            var minutes = (remainingSeconds == 0) ? 0 : (remainingSeconds / 60) + (remainingSeconds % 60 > 0 ? 1 : 0)
            
            // 分が60になったら時間を+1して分を0に
            var adjustedHours = hours
            if minutes == 60 {
                adjustedHours += 1
                minutes = 0
            }
            
            return String(format: "%02d:%02d", adjustedHours, minutes)
        } else if seconds >= 60 {
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "%02d:%02d", minutes, secs)
        } else {
            return String(format: "00:%02d", seconds)
        }
    }
    
    // 時刻のみのフォーマッター（HH:mm）
    static func formatToHoursAndMinutes(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // 時刻と秒を含むフォーマッター（HH:mm:ss）
    static func formatToHoursMinutesAndSeconds(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
} 
