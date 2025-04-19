# Dependency Injection Design

このドキュメントは、SilentCue Watchアプリ内で、The Composable Architecture (TCA) を使用して依存関係を管理するための設計と、それが単体テストやUIテストにどのように関連するかを概説します。

## コアコンセプト

1.  **依存性逆転の原則:** コンポーネントが具体的な実装（`UserDefaults.standard`, `UNUserNotificationCenter.current()` など）を直接作成またはアクセスする代わりに、**プロトコル**に基づいた抽象化に依存します。これにより、コードはモジュール化され、テスト可能になります。
2.  **TCA Dependencies:** TCAは、依存関係を管理するための構造化された方法を提供します。
    *   **`DependencyKey` と `liveValue`:** 各依存関係に対してキーを定義し、本番環境で使用される「ライブ実装」を指定します。
    *   **`TestDependencyKey` と `testValue`:** テスト環境でのデフォルト実装を定義します。通常、**各メソッドが未実装であることを示すスタブ（`unimplemented`）** を設定し、テストで依存関係のモック提供漏れがあればテストが失敗するようにします。
    *   **`previewValue`:** Xcode プレビューで使用される依存関係の実装を指定します。プレビューはUIの見た目を素早く確認するためのものであり、`liveValue` が持つ副作用（ネットワークアクセス等）がプレビューに適さない場合があるため、プレビュー専用の軽量で安全な実装（例: `liveValue` 自身、No-Op実装、サンプルデータを返す実装など）を提供します。
    *   **`@Dependency` プロパティラッパー:** Reducer や View (場合によっては App 本体など) で、必要な依存関係を宣言し、TCAに注入を依頼します。TCAは実行コンテキスト（本番、テスト、プレビュー）に応じて適切な実装（`liveValue` または `testValue`/テスト時の上書き、あるいは `previewValue`）を提供します。
3.  **テストのためのモック:** テスト中（単体テストやUIテスト）、副作用を回避し、予測可能な動作を保証するために、「ライブ実装」を「モック」または「スタブ」バージョンに置き換えます。TCA の `withDependencies` や `TestStore.dependencies` を使用して、テストケースごとに必要な依存関係の動作を具体的に設定します。
4.  **(更新) 共有ファイルの構成:**
    *   アプリ本体とテストターゲットの両方から必要とされる共通コンポーネントは `/Shared` ディレクトリ以下に配置します。
    *   **依存関係プロトコル** は `/Shared/Protocol/` に配置し、アプリ本体ターゲット (`SilentCue Watch App`) にのみ所属させ、テストからは `@testable import SilentCue_Watch_App` でアクセスします。
    *   **テスト用のモック/スタブ実装** (`MockUserDefaultsManager`, `MockHapticsService` など) は `/Shared/Mock/` に配置し、テストターゲット (`SilentCue Watch AppTests`) にのみ所属させます。
    *   **その他の共通ファイル** (`SCAppEnvironment.swift`, `SCAccessibilityIdentifiers.swift` など) は `/Shared/` 直下に配置し、アプリ本体ターゲット (`SilentCue Watch App`) に所属させ、テストからは `@testable import SilentCue_Watch_App` でアクセスします。

## 依存関係実装の種類と役割

TCA で依存関係を管理する際には、主に 3 種類の実装が登場します。それぞれの目的と所属ターゲットは以下の通りです。

*   **Live 実装 (`Live...Service`)**:
    *   **目的:** アプリの本番環境で実際に動作する機能を提供します。実際のシステムフレームワーク (`UserDefaults`, `UNUserNotificationCenter` など) と連携します。
    *   **ターゲット:** **アプリ本体 (`SilentCue Watch App`) のみ** に所属します。

*   **Preview 実装 (`Preview...Service` または `Live...Service`)**:
    *   **目的:** Xcode の SwiftUI プレビューや UI テストで使用するための、軽量で安全な実装です。プレビューを壊す可能性のある副作用（重い処理、実際のデータ変更、外部通信など）を避けるために使われます。
    *   **内容:** `Live` 実装がプレビューで安全ならそれを流用 (`previewValue = Self.liveValue`) することも、プレビュー専用のシンプルな実装 (`Preview...Service`) を用意することもあります。
    *   **ターゲット:** **アプリ本体 (`SilentCue Watch App`) のみ** に所属します。リリースビルドには不要なため、通常は実装を **`#if DEBUG`** で囲みます。

*   **Mock 実装 (`Mock...Service`)**:
    *   **目的:** **ユニットテスト (`TestStore` を使うテスト) 専用** です。テストコードから動作を細かく制御し、特定のシナリオ（成功、失敗、特定のデータ返却など）をシミュレートするために使用します。呼び出し回数の記録なども行えます。
    *   **ターゲット:** **テスト (`SilentCue Watch AppTests`) のみ** に所属します。

**なぜ Mock 実装をアプリ本体ターゲットに含めないか:**

Mock 実装は純粋にテストのためのコードであり、以下の理由からアプリ本体ターゲットには含めるべきではありません。

1.  **関心の分離:** 本番コードとテストコードを明確に分離し、プロジェクトの構造をクリーンに保ちます。
2.  **アプリサイズの削減:** アプリ本体に不要なコードを含めず、ユーザーがダウンロードするバイナリサイズを最小限に抑えます。
3.  **安全性:** 本番環境で誤ってテスト用の Mock が使用されるリスクを排除します。

## 管理されている主な依存関係

このアプリでは、以下の主要な依存関係がTCAのシステムを通じて管理されています。

*   **`userDefaultsService: UserDefaultsServiceProtocol`:** `UserDefaults` へのアクセス。
    *   プロトコル: `/Shared/Protocol/UserDefaultsServiceProtocol.swift`
    *   ライブ実装: `LiveUserDefaultsService` (in `/Service/UserDefaultsService.swift`)
    *   テスト用デフォルト: `unimplemented` (TestDependencyKey経由)
    *   モック実装: `MockUserDefaultsManager` (`/Shared/Mock/MockUserDefaultsManager.swift`) - ※モック名自体は維持
*   **`notificationService: NotificationServiceProtocol`:** 通知の許可確認、リクエスト、スケジュール、キャンセル。
    *   プロトコル: `/Shared/Protocol/NotificationServiceProtocol.swift`
    *   ライブ実装: `LiveNotificationService` (in `/Service/NotificationService.swift`)
    *   テスト用デフォルト: `unimplemented` (TestDependencyKey経由)
    *   モック実装: `MockNotificationService` (`/Shared/Mock/MockNotificationService.swift`)
*   **`extendedRuntimeService: ExtendedRuntimeServiceProtocol`:** 拡張ランタイムセッションの管理。
    *   プロトコル: `/Shared/Protocol/ExtendedRuntimeServiceProtocol.swift`
    *   ライブ実装: `LiveExtendedRuntimeService` (in `/Service/ExtendedRuntimeService.swift`)
    *   テスト用デフォルト: `unimplemented` (TestDependencyKey経由)
    *   モック実装: `MockExtendedRuntimeService` (`/Shared/Mock/MockExtendedRuntimeService.swift`)
*   **`hapticsService: HapticsServiceProtocol`:** 触覚フィードバックの再生。
    *   プロトコル: `/Shared/Protocol/HapticsServiceProtocol.swift`
    *   ライブ実装: `LiveHapticsService` (in `/Service/HapticsService.swift`)
    *   テスト用デフォルト: `unimplemented` (TestDependencyKey経由)
    *   モック実装: `MockHapticsService` (`/Shared/Mock/MockHapticsService.swift`)
*   **`continuousClock: any Clock<Duration>`:** 時間の経過 (タイマー用)。
    *   (TCA標準の依存関係)

## UIテストのオーバーライド (`SilentCueApp.swift`)

UIテスト実行時には、アプリ起動時のコマンドライン引数 (`uiTesting`) を検知し、`SilentCueApp.swift` の `init()` 内で **Storeを初期化する際に `withDependencies` を使用して**、依存関係（例: `userDefaultsService`）をテスト用のモック (`MockUserDefaultsManager`) に差し替えています。この差し替え処理は、テスト用コードが本番ビルドに含まれないように **`#if DEBUG` による条件付きコンパイル** で囲われています。これにより、UIテスト全体で Store が使用する依存関係に対して一貫したモック環境を提供しつつ、リリースビルドの安全性を確保しています。

## 設計の進化

当初はシングルトンパターンや直接的なAPI呼び出しが多く存在しましたが、TCAの依存性注入システムを活用するようにリファクタリングされました。主な変更点は以下の通りです。

*   `UserDefaults`, `Notification`, `ExtendedRuntime`, `Haptics` 関連の依存関係を `*Service` という命名規則とプロトコルベース (`*ServiceProtocol`) に統一し、ライブ実装 (`Live*Service`) とテスト実装 (`unimplemented`) を分離。
*   実装ファイルを `/Service/` ディレクトリに集約。
*   共有の依存関係プロトコルを `/Shared/Protocol/` に集約。
*   テスト用モック/スタブ実装を `/Shared/Mock/` に整理。
*   テスト時のデフォルト実装定義に `TestDependencyKey` を採用。
*   UIテスト時のモック注入に `Store` 初期化時の `withDependencies` を使用するよう変更。

**(更新)** `SilentCueApp.swift` や `TimerReducer`, `SettingsReducer`, `HapticsReducer` 内で直接シングルトンアクセスやフレームワークAPI (`UserDefaults.standard`, `UNUserNotificationCenter.current()`, `WKExtendedRuntimeSession`, `WKInterfaceDevice.current().play()`, 各種 `.shared` インスタンス) を使用していた箇所は、TCAの `@Dependency` (`.userDefaultsService`, `.notificationService`, `.extendedRuntimeService`, `.hapticsService`) を使用するようにリファクタリングされました。これにより、依存性注入の仕組みが一貫し、テスト容易性が大幅に向上しました。 