import Foundation

enum SCTimeFormatter {
    static func formatSecondsToTimeString(_ seconds: Int) -> String {
        if seconds >= 3600 {
            let hours = seconds / 3600
            let minutes = ((seconds % 3600) / 60)
            
            // HH:MM形式の場合、分数を1分遅く表示（より直感的に）
            var adjustedMinutes = minutes > 0 ? minutes + 1 : 0
            var adjustedHours = hours
            
            // 60分になったら時間を1時間増やし、分を0にする
            if adjustedMinutes == 60 {
                adjustedHours += 1
                adjustedMinutes = 0
            }
            
            return String(format: "%02d:%02d", adjustedHours, adjustedMinutes)
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
