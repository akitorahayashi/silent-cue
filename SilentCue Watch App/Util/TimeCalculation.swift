import Foundation

/// Utility struct for time-related calculations.
enum TimeCalculation {

    /// Calculates the total seconds until the target time based on the selected mode.
    static func calculateTotalSeconds(
        mode: TimerMode,
        selectedMinutes: Int,
        selectedHour: Int,
        selectedMinute: Int,
        now: Date,
        calendar: Calendar = .current // Default to current calendar
    ) -> Int {
        switch mode {
        case .afterMinutes:
            return max(0, selectedMinutes) * 60
        case .atTime:
            var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
            dateComponents.hour = selectedHour
            dateComponents.minute = selectedMinute
            dateComponents.second = 0

            guard let targetDate = calendar.date(from: dateComponents) else {
                print("Error: Could not create target date from components.")
                return 0
            }

            if targetDate <= now {
                guard let tomorrowTargetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) else {
                    print("Error: Could not calculate tomorrow's target date.")
                    return 0
                }
                return max(0, Int(ceil(tomorrowTargetDate.timeIntervalSince(now))))
            } else {
                return max(0, Int(ceil(targetDate.timeIntervalSince(now))))
            }
        }
    }
} 