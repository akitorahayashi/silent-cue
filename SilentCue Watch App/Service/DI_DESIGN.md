# Dependency Injection Design

このドキュメントは、SilentCue Watchアプリ内で、The Composable Architecture (TCA) を使用して依存関係を管理するための設計と、それが単体テストやUIテストにどのように関連するかを概説します。

## コアコンセプト

1.  **依存性逆転の原則:** コンポーネントが具体的な実装（`UserDefaults.standard`, `UNUserNotificationCenter.current()` など）を直接作成またはアクセスする代わりに、**プロトコル**に基づいた抽象化に依存します。これにより、コードはモジュール化され、テスト可能になります。
2.  **TCA Dependencies:** TCAは、依存関係を管理するための構造化された方法を提供します。
    *   **`DependencyKey` と `liveValue`:** 各依存関係に対してキーを定義し、本番環境で使用される「ライブ実装」を指定します。
    *   **`TestDependencyKey` と `testValue`:** テスト環境でのデフォルト実装を定義します。通常、**各メソッドが未実装であることを示すスタブ（`unimplemented`）** を設定し、テストで依存関係のモック提供漏れがあればテストが失敗するようにします。
    *   **`@Dependency` プロパティラッパー:** Reducer や View (場合によっては App 本体など) で、必要な依存関係を宣言し、TCAに注入を依頼します。TCAは実行コンテキスト（本番、テスト、プレビュー）に応じて適切な実装（`liveValue` または `testValue`/テスト時の上書き）を提供します。
3.  **テストのためのモック:** テスト中（単体テストやUIテスト）、副作用を回避し、予測可能な動作を保証するために、「ライブ実装」を「モック」または「スタブ」バージョンに置き換えます。TCA の `withDependencies` や `TestStore.dependencies` を使用して、テストケースごとに必要な依存関係の動作を具体的に設定します。
4.  **(更新) 共有ファイルの構成:**
    *   アプリ本体とテストターゲットの両方から必要とされる共通コンポーネントは `/Shared` ディレクトリ以下に配置します。
    *   **依存関係プロトコル** は `/Shared/Protocols/` に配置し、アプリ本体とテストターゲットの両方から参照可能にします (プロトコルファイルはアプリ本体ターゲットのみに所属させ、テストからは `@testable import` でアクセス)。
    *   **テスト用のモック/スタブ実装** (`MockUserDefaultsManager`, `NoopNotificationService` など) は `/Shared/TestingSupport/` に配置し、テストターゲットのみに所属させます。

## 管理されている主な依存関係

このアプリでは、以下の主要な依存関係がTCAのシステムを通じて管理されています。

*   **`userDefaultsService: UserDefaultsServiceProtocol`:** `UserDefaults` へのアクセス。
    *   プロトコル: `/Shared/Protocols/UserDefaultsServiceProtocol.swift`
    *   ライブ実装: `LiveUserDefaultsService` (in `/Service/UserDefaultsService.swift`)
    *   テスト用デフォルト: `unimplemented` (TestDependencyKey経由)
    *   モック実装: `MockUserDefaultsManager` (`/Shared/TestingSupport/`) - ※モック名自体は維持
*   **`notificationService: NotificationServiceProtocol`:** 通知の許可確認、リクエスト、スケジュール、キャンセル。
    *   プロトコル: `/Shared/Protocols/NotificationServiceProtocol.swift`
    *   ライブ実装: `LiveNotificationService` (in `/Service/NotificationService.swift`)
    *   テスト用デフォルト: `unimplemented` (TestDependencyKey経由)
    *   スタブ実装 (No-op): `NoopNotificationService` (`/Shared/TestingSupport/NoopImplementations.swift`)
*   **`extendedRuntimeService: ExtendedRuntimeServiceProtocol`:** 拡張ランタイムセッションの管理。
    *   プロトコル: `/Shared/Protocols/ExtendedRuntimeServiceProtocol.swift`
    *   ライブ実装: `LiveExtendedRuntimeService` (in `/Service/ExtendedRuntimeService.swift`)
    *   テスト用デフォルト: `unimplemented` (TestDependencyKey経由)
    *   スタブ実装 (No-op): `NoopExtendedRuntimeService` (`/Shared/TestingSupport/NoopImplementations.swift`)
*   **`hapticsService: HapticsServiceProtocol`:** 触覚フィードバックの再生。
    *   プロトコル: `/Shared/Protocols/HapticsServiceProtocol.swift`
    *   ライブ実装: `LiveHapticsService` (in `/Service/HapticsService.swift`)
    *   テスト用デフォルト: `unimplemented` (TestDependencyKey経由)
    *   スタブ実装 (No-op): `NoopHapticsService` (`/Shared/TestingSupport/NoopImplementations.swift`)
*   **`continuousClock: any Clock<Duration>`:** 時間の経過 (タイマー用)。
    *   (TCA標準の依存関係)

## UIテストのオーバーライド (`SilentCueApp.swift`)

UIテスト実行時には、アプリ起動時のコマンドライン引数 (`uiTesting`) を検知し、`SilentCueApp.swift` の `init()` 内で **Storeを初期化する際に `withDependencies` を使用して**、依存関係（例: `userDefaultsService`）をテスト用のモック (`MockUserDefaultsManager`) に差し替えています。この差し替え処理は、テスト用コードが本番ビルドに含まれないように **`#if DEBUG` による条件付きコンパイル** で囲われています。これにより、UIテスト全体で Store が使用する依存関係に対して一貫したモック環境を提供しつつ、リリースビルドの安全性を確保しています。

## 設計の進化

当初はシングルトンパターンや直接的なAPI呼び出しが多く存在しましたが、TCAの依存性注入システムを活用するようにリファクタリングされました。主な変更点は以下の通りです。

*   `UserDefaults`, `Notification`, `ExtendedRuntime`, `Haptics` 関連の依存関係を `*Service` という命名規則とプロトコルベース (`*ServiceProtocol`) に統一し、ライブ実装 (`Live*Service`) とテスト実装 (`unimplemented`) を分離。
*   実装ファイルを `/Service/` ディレクトリに集約。
*   共有の依存関係プロトコルを `/Shared/Protocols/` に、テスト用モック/スタブ実装を `/Shared/TestingSupport/` に整理。
*   テスト時のデフォルト実装定義に `TestDependencyKey` を採用。
*   UIテスト時のモック注入に `Store` 初期化時の `withDependencies` を使用するよう変更。

**(更新)** `SilentCueApp.swift` や `TimerReducer`, `SettingsReducer`, `HapticsReducer` 内で直接シングルトンアクセスやフレームワークAPI (`UserDefaults.standard`, `UNUserNotificationCenter.current()`, `WKExtendedRuntimeSession`, `WKInterfaceDevice.current().play()`, 各種 `.shared` インスタンス) を使用していた箇所は、TCAの `@Dependency` (`.userDefaultsService`, `.notificationService`, `.extendedRuntimeService`, `.hapticsService`) を使用するようにリファクタリングされました。これにより、依存性注入の仕組みが一貫し、テスト容易性が大幅に向上しました。 