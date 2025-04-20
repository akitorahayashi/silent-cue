# Dependency Injection Design

このドキュメントは、SilentCue Watchアプリ内で、The Composable Architecture (TCA) を使用して依存関係を管理するための設計と、それが単体テストやUIテストにどのように関連するかを詳細に解説します。

## 1. コアコンセプト：TCAにおける依存関係管理

TCA (The Composable Architecture) は、依存関係を管理するための強力な仕組みを提供します。この設計の中心となるのは以下の原則です。

*   **依存性逆転:** 具体的な実装（`UserDefaults.standard` など）に直接依存するのではなく、抽象的なインターフェース（**プロトコル**）に依存します。
*   **明確な責務分離:** アプリケーションの各部分（本番ロジック、プレビュー用ロジック、テスト用ロジック）で使用される依存関係の実装を明確に分離します。
*   **テスト容易性:** 依存関係を簡単に差し替え可能にすることで、ユニットテストやUIテストを容易にします。

TCAでは、`DependencyKey` プロトコルと `@Dependency` プロパティラッパーを使用してこれを実現します。

*   **`DependencyKey`**: 各依存関係に対して一意なキーを定義します。このキーは、本番用 (`liveValue`)、テスト用 (`testValue`)、プレビュー用 (`previewValue`) のデフォルト実装を指定します。
*   **`@Dependency`**: ReducerやView（場合によってはAppのエントリーポイントなど）で、必要な依存関係を宣言的に注入します。TCAは実行コンテキスト（本番、テスト、プレビュー）に応じて、適切な実装（`liveValue`, `testValue`/テスト時の上書き、`previewValue`）を提供します。

## 2. 依存関係コンポーネントの種類、役割、ターゲット設定

依存関係管理においては、主に以下の種類のコンポーネントが登場します。それぞれの役割と、Xcodeプロジェクト内でのターゲット設定、配置場所について詳しく説明します。

### プロトコル (`*ServiceProtocol`)

*   **役割:**
    *   依存関係の**契約（インターフェース）**を定義します。
    *   具体的な実装の詳細を隠蔽し、依存する側（Reducerなど）が期待する機能（メソッド、プロパティ）を明確にします。
    *   依存性逆転の原則を実現するための**要**となります。
*   **配置場所:**
    *   `/Shared/Protocol/` （例: `UserDefaultsServiceProtocol.swift`）
    *   アプリ本体とテストの両方から参照される共通の定義ですが、実装は含みません。
*   **ターゲット設定:**
    *   **アプリ本体ターゲット (`SilentCue Watch App`) のみ**に所属させます。
    *   テストターゲットからは、`@testable import SilentCue_Watch_App` を使用してアクセスします。これにより、プロトコル定義が一元管理されます。

### Live 実装 (`Live*Service`)

*   **役割:**
    *   **本番環境**で実際に動作する依存関係の**具体的な実装**を提供します。
    *   実際のシステムフレームワーク (`UserDefaults`, `UNUserNotificationCenter`, `WKExtendedRuntimeSession`, `WKInterfaceDevice` など）と連携し、アプリのコア機能を実現します。
*   **配置場所:**
    *   `/Service/` （例: `UserDefaultsService.swift` 内の `LiveUserDefaultsService`）
    *   機能ごとにファイルを分け、関連する `DependencyKey` 定義と一緒に配置します。
*   **ターゲット設定:**
    *   **アプリ本体ターゲット (`SilentCue Watch App`) のみ**に所属させます。
    *   テストターゲットからは直接参照しません（テストではMock実装を使用します）。
*   **`DependencyKey` への登録:**
    *   `liveValue` プロパティに、このLive実装のインスタンスを返却するように設定します。
    *   例: `static let liveValue = LiveUserDefaultsService()`

### Preview 実装 (`Preview*Service` または `Live*Service` の流用)

*   **役割:**
    *   **SwiftUIプレビュー (`#Preview`)** や、場合によっては**UIテスト**で使用するための、**軽量で安全な実装**を提供します。
    *   プレビューの動作を妨げる副作用（ネットワークアクセス、ファイル書き込み、重い計算、データ変更など）を回避します。
    *   プレビュー用に特定の状態やサンプルデータを返すこともあります。
*   **配置場所:**
    *   Live実装と同じファイル内、または専用ファイル (例: `PreviewNotificationService.swift`)。
    *   Live実装がプレビューで安全かつ適切であれば、それを流用 (`Self.liveValue`) することも一般的です。
*   **ターゲット設定:**
    *   **アプリ本体ターゲット (`SilentCue Watch App`) のみ**に所属させます。
*   **コンパイル条件:**
    *   **`#if DEBUG ... #endif`** で囲むことが**必須**です。これにより、リリースビルドから除外されます。
*   **`DependencyKey` への登録:**
    *   `previewValue` プロパティに、Preview実装または流用するLive実装のインスタンスを設定します。
    *   例1 (専用実装): `static let previewValue = PreviewUserDefaultsService()`
    *   例2 (Live流用): `static let previewValue = Self.liveValue`
    *   例3 (No-Op実装): 何もしないダミー実装を提供する場合もあります。

### Mock 実装 (`Mock*Service`)

*   **役割:**
    *   **ユニットテスト (`TestStore` を使用するテスト) 専用**の実装です。
    *   テストコードから**動作を細かく制御**可能にします（例: 特定の返り値、呼び出し回数の記録）。
    *   Reducerと依存関係の相互作用を検証するために不可欠です。
*   **配置場所:**
    *   `/Shared/Mock/` （例: `MockUserDefaultsManager.swift`, `MockNotificationService.swift`）
    *   テストコード専用であることを明確にするためのディレクトリです。
*   **ターゲット設定:**
    *   **テストターゲット (`SilentCue Watch AppTests`) のみ**に所属させます。
    *   **重要:** アプリ本体ターゲットには**絶対に含めません**。
        *   **理由:** 関心の分離、アプリサイズ削減、安全性確保のため。
*   **テストでの使用:**
    *   `TestStore.dependencies` や `withDependencies` を使用して、テストケースごとにMock実装とその挙動を設定します。
    *   例: `mockUserDefaults.getStringForKeyClosure = { _ in "testValue" }`

### Test 実装 (`testValue`)

*   **役割:**
    *   `DependencyKey` の `testValue` は、テスト実行時の**デフォルト実装**を定義します。
    *   テストコードで明示的に上書きされなかった場合に使用されます。
*   **推奨される実装:**
    *   TCA提供の **`unimplemented`** を使用します。これは、未実装のメソッドが呼び出されるとテストを失敗させるスタブです。
    *   これにより、テストでMock実装の提供漏れがあれば早期に検知できます。
*   **`DependencyKey` への登録:**
    *   `testValue` プロパティに `unimplemented` などのデフォルトテスト実装を設定します。
    *   例: `static let testValue = unimplemented(UserDefaultsServiceProtocol.self)`

## 3. ターゲット設定のまとめと根拠

| コンポーネント種類 | 配置場所 (例)        | ターゲット所属           | 根拠                                                               |
| :--------------- | :------------------- | :--------------------- | :----------------------------------------------------------------- |
| **プロトコル**   | `/Shared/Protocol/`  | **アプリ本体のみ**     | 定義の一元管理、`@testable import` でテストからアクセス可能        |
| **Live 実装**    | `/Service/`          | **アプリ本体のみ**     | 本番ロジック専用、テストからは直接利用しない                     |
| **Preview 実装** | Live実装と同じ/専用 | **アプリ本体のみ**     | プレビュー用、`#if DEBUG` でリリースビルドから除外               |
| **Mock 実装**    | `/Shared/Mock/`      | **テストターゲットのみ** | テスト専用、関心の分離、アプリサイズ削減、安全性確保             |
| **Test 実装**    | `DependencyKey`内    | (定義の一部)           | テスト時のデフォルト、`unimplemented` で設定漏れを検知             |

## 4. 管理戦略

*   **ディレクトリ構造:** 上記の配置場所 (`/Shared/Protocol`, `/Shared/Mock`, `/Service`) に従い、ファイルを整理します。
*   **命名規則:** `*ServiceProtocol`, `Live*Service`, `Preview*Service` (必要な場合), `Mock*Service` のように一貫性を保ちます。
*   **`DependencyKey` 設定:** 各依存関係に `liveValue`, `testValue` (`unimplemented`推奨), `previewValue` を適切に設定します。
*   **`#if DEBUG` の徹底:** `previewValue` の実装やUIテスト用の依存関係差し替えコード (例: `SilentCueApp.swift` 内) は、必ず `#if DEBUG` で囲みます。
*   **テストでの依存関係注入:**
    *   **ユニットテスト:** `TestStore.dependencies` や `withDependencies` を活用し、テストケースごとにMockの挙動を正確に設定します。
    *   **UIテスト:** アプリ起動時に `launchArguments` 等でテストモードを識別し、アプリの早期段階 (`SilentCueApp.init()` 等) で `withDependencies` を使用して、テスト用の依存関係 (`previewValue` や専用Mock) に差し替えます（コードは `#if DEBUG` で囲むこと）。

この詳細な設計と規約に従うことで、SilentCue Watchアプリの依存関係はより明確に管理され、保守性、テスト容易性、安全性が向上します。

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