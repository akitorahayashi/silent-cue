import ComposableArchitecture
import SCShared

/// 設定画面に関連するアクション
enum SettingsAction: Equatable {
    // Internal Actions Enum
    enum InternalAction: Equatable {
        case saveSettingsEffect // 保存副作用をトリガー
    }

    // 設定の読み込み関連
    case loadSettings
    case settingsLoaded(hapticType: HapticType)

    // 設定の変更関連
    case selectHapticType(HapticType)
    @available(*, deprecated, message: "Use selectHapticType, saving is now an effect.")
    case saveSettings

    // --- New Haptic Feedback Actions ---
    case startHapticPreview(HapticType) // プレビュー開始 & 初期再生 & タイマー起動
    case hapticPreviewTick // タイマーからのTick
    case stopHapticPreview // プレビュー停止 (タイムアウトまたはキャンセル)

    // --- Deprecated Haptic Feedback Actions ---
    @available(*, deprecated, message: "Use startHapticPreview, hapticPreviewTick, stopHapticPreview")
    case previewHapticFeedback(HapticType)
    @available(*, deprecated, message: "Use stopHapticPreview")
    case previewHapticCompleted

    // ナビゲーション関連
    case backButtonTapped

    // Internal action case
    case `internal`(InternalAction)
}
