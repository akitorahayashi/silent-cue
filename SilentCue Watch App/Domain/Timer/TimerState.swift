import Foundation

/// タイマーのモード（分後か時刻指定か）
enum TimerMode: String, Equatable, CaseIterable, Identifiable {
    case afterMinutes = "分数" // 何分後に鳴らすか
    case atTime = "時刻" // 何時に鳴らすか

    var id: String { rawValue }
}

/// タイマーの状態を管理するクラス
struct TimerState: Equatable {
    // タイマー設定の状態
    var timerMode: TimerMode = .afterMinutes
    var selectedMinutes = 1
    var selectedHour: Int = Calendar.current.component(.hour, from: Date())
    var selectedMinute: Int = (Calendar.current.component(.minute, from: Date()) + 5) % 60

    // カウントダウンの状態
    var totalSeconds = 0
    var isRunning = false
    var displayTime = "00:00"

    // バックグラウンド対応のための時間情報
    var startDate: Date?
    var targetEndDate: Date?

    // 完了画面用の情報
    var completionDate: Date?
    var timerDurationMinutes = 0

    // remainingSecondsを計算プロパティに変更
    var remainingSeconds: Int {
        guard let targetEnd = targetEndDate, isRunning else {
            // タイマーが実行中でない場合はtotalSecondsを表示
            return totalSeconds
        }
        // timeIntervalSinceの値を切り上げて整数に変換
        return max(0, Int(ceil(targetEnd.timeIntervalSince(Date()))))
    }

    // タイマーの計算された合計秒数
    var calculatedTotalSeconds: Int {
        switch timerMode {
            case .afterMinutes:
                return selectedMinutes * 60
            case .atTime:
                let now = Date()
                let calendar = Calendar.current
                let hour = selectedHour
                let minute = selectedMinute

                var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
                dateComponents.hour = hour
                dateComponents.minute = minute
                dateComponents.second = 0

                guard let targetDate = calendar.date(from: dateComponents) else {
                    return 0
                }

                // 選択された時刻が現在時刻より前の場合は翌日とみなす
                if targetDate < now {
                    guard let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: targetDate) else {
                        return 0
                    }
                    return Int(tomorrowDate.timeIntervalSince(now))
                }

                return Int(targetDate.timeIntervalSince(now))
        }
    }

    init() {
        // 現在時刻を取得して初期値として設定
        let now = Date()
        let calendar = Calendar.current

        selectedHour = calendar.component(.hour, from: now)

        // 「分後」モードは5分後をデフォルトにするが、
        // 「時刻」モードの初期値は現在の分をそのまま使用
        let currentMinute = calendar.component(.minute, from: now)
        selectedMinute = currentMinute

        // 「分後」モードでは初期設定を1分に
        selectedMinutes = 1
    }
}
