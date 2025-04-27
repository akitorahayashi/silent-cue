# Dependency Injection Design (Multi-Module Architecture)

このドキュメントは、SilentCue Watchアプリ内で、The Composable Architecture (TCA) を基盤としたマルチモジュールアーキテクチャにおける依存関係の管理設計を解説します。

## 1. コアコンセプト：TCAにおける依存関係管理

TCAは、依存関係を管理するための仕組みを提供しており、このアプリの設計の中心となるのは以下の原則です。

*   **依存性逆転:** 具体的な実装に直接依存せず、抽象的なインターフェース（プロトコル）に依存します。
*   **責務の分離:** アプリケーションの各機能レイヤーやビルド環境（本番、プレビュー、テスト）で使用される依存関係の実装を、独立したモジュールに分離します。
*   **テスト容易性:** 依存関係を容易に差し替え可能にし、ユニットテストやUIテストを実行しやすくします。

TCAでは、`DependencyKey` プロトコルと `@Dependency` プロパティラッパーを使用してこれを実現します。

*   **`DependencyKey`**: 各依存関係に対して一意なキーを定義します。このキーは、本番用 (`liveValue`)、プレビュー用 (`previewValue`)、テスト用 (`testValue`) のデフォルト実装を指定します。
*   **`@Dependency`**: Reducerなどのコンポーネントで、必要な依存関係を宣言的に注入します。TCAは実行コンテキストに応じて、`DependencyKey` で定義された適切な実装を提供します。

## 2. モジュール構成と役割

依存関係管理においては、以下のコンポーネントが独立したモジュールとして構成されます。各モジュールの役割、配置場所、依存関係、ビルド構成におけるリンクの扱いは以下の通りです。

| モジュール名           | 主な役割/内容                         | 配置場所 (ルート直下) | Xcodeターゲット (Type) | 主な依存先                   | ビルド構成リンク           | アクセス制御 |
| :------------------- | :------------------------------------ | :------------------ | :------------------- | :------------------------- | :----------------------- | :--------- |
| `SCProtocol`         | サービスインターフェース (プロトコル) | `/SCProtocol/`      | `library.static`     | `Dependencies`           | 常時                     | `public`   |
| `SCLiveService`      | 本番サービス実装                      | `/SCLiveService/`   | `library.static`     | `SCProtocol`, `ComposableArchitecture` | 常時                     | `public`   |
| `SCPreview`        | プレビュー用実装・アセット            | `/SCPreview/`       | `library.static`     | `SCProtocol`, `ComposableArchitecture` | Debug のみ (Appリンク時) | `public`   |
| `SCMock`             | テスト用モック実装                    | `/SCMock/`          | `library.static`     | `SCProtocol`, `ComposableArchitecture` | Debug のみ (Appリンク時), 常時 (Testsリンク時) | `public`   |
| `SCShared`         | 複数モジュールで共有されるコード      | `/SCShared/`        | `library.static`     | `SCProtocol`, `ComposableArchitecture` | 常時                     | `public`   |
| `SilentCue_Watch_App` (本体) | UI, Domain, DI設定             | (アプリ内)          | `application.watchapp2`| 各モジュール, `ComposableArchitecture` | -                        | -          |

**補足:**
*   **依存性キー/値:** DIの設定ファイル (`SCDependencyKeys.swift`, `SCDependencyValues.swift`) はアプリケーション本体 (`SilentCue_Watch_App`) の `/Dependency/` ディレクトリ内に配置されます。これらは各実装モジュールに依存します。
*   **ビルド構成リンク:** `project.yml` の `condition: { config: Debug }` 設定により、`SCPreview` と `SCMock` は Debug ビルド時にのみアプリケーション本体にリンクされます。テストターゲット (`SilentCue_Watch_AppTests`) は常に `SCMock` にリンクされます。

## 3. モジュール依存関係の概要

### `SilentCue_Watch_App` (アプリケーション本体)

*   → `SCProtocol`
*   → `SCShared`
*   → `SCLiveService`
*   → `SCPreview` (Debugビルド時のみリンク)
*   → `SCMock` (Debugビルド時のみリンク)
*   → `ComposableArchitecture`

### `SilentCue_Watch_AppTests` (テストターゲット)

*   → `SilentCue_Watch_App`
*   → `SCProtocol`
*   → `SCShared`
*   → `SCMock`
*   → `SCLiveService`
*   → `SCPreview`
*   → `ComposableArchitecture`

### `SCProtocol`

*   → `Dependencies`

### `SCShared`

*   → `SCProtocol`
*   → `ComposableArchitecture`

### `SCLiveService`

*   → `SCProtocol`
*   → `ComposableArchitecture`

### `SCPreview`

*   → `SCProtocol`
*   → `ComposableArchitecture`

### `SCMock`

*   → `SCProtocol`
*   → `ComposableArchitecture`

### 依存関係のポイント

*   依存関係は基本的に `実装` → `インターフェース(プロトコル)` の方向です。
*   `SCPreview` と `SCMock` は Debug ビルド時にのみアプリケーション本体 (`SilentCue_Watch_App`) にリンクされます。これは `project.yml` で制御されます。
*   テストターゲット (`SilentCue_Watch_AppTests`) は、テストに必要なモック (`SCMock`) やテスト対象のアプリ本体 (`SilentCue_Watch_App`) などに依存します。

## 4. 管理戦略

*   **XcodeGen:** プロジェクトファイル (`.xcodeproj`) は `project.yml` から生成されます。モジュール構成や依存関係、ビルド設定は `project.yml` で管理します。
*   **ディレクトリ構造:** 上記のモジュール構成に従い、ファイルを各モジュールのディレクトリ (`/SCProtocol/`, `/SCShared/`, `/SCLiveService/`, `/SCPreview/`, `/SCMock/`) に配置します。
*   **命名規則:** `*ServiceProtocol`, `Live*Service`, `Preview*Service`, `Mock*Service` の一貫性を保ちます。
*   **`DependencyKey` 設定:** `SCDependencyKeys.swift` で各依存関係の `liveValue`, `previewValue`, `testValue` を適切に設定し、`#if DEBUG` を用いてビルド構成に応じた実装を参照します。モジュール名をプレフィックスとして付与します (例: `SCLiveService.LiveUserDefaultsService`, `SCMock.MockUserDefaultsManager`)。
*   **アクセス制御:** モジュール間で共有される `protocol`, `class`, `struct`, `enum`, `init` などには `public` 修飾子を適用します。
*   **テストでの依存関係注入:**
    *   **ユニットテスト:** `TestStore` を使用する場合、デフォルトで `SCDependencyKeys.swift` の `testValue` (Mock実装、`SCMock`内) が注入されます。特定のテストケースで挙動を変更したい場合は、`TestStore` 初期化時の `withDependencies` や `store.dependencies.service = specificMock` で上書きします。
    *   **UIテスト:** (現在は未サポート) アプリ起動時に `launchArguments` 等でテストモードを識別し、アプリの早期段階 (`SilentCueApp.init()` 等) で `withDependencies` を使用して、必要な依存関係をテスト用のモック (`SCMock` 内の実装) に差し替えます。この差し替えコードは `#if DEBUG` で囲みます。

## 管理されている主な依存関係

*   **`userDefaultsService: UserDefaultsServiceProtocol`**: `UserDefaults` へのアクセス
    *   プロトコル: `/SCProtocol/UserDefaultsServiceProtocol.swift` (`SCProtocol`)
    *   ライブ実装: `LiveUserDefaultsService` (in `/SCLiveService/LiveUserDefaultsService.swift`, `SCLiveService`)
    *   プレビュー実装: `PreviewUserDefaultsService` (in `/SCPreview/PreviewUserDefaultsService.swift`, `SCPreview`)
    *   テスト用デフォルト/モック実装: `MockUserDefaultsManager` (in `/SCMock/MockUserDefaultsManager.swift`, `SCMock`)
*   **`notificationService: NotificationServiceProtocol`**: 通知の許可確認、リクエスト、スケジュール、キャンセル
    *   プロトコル: `/SCProtocol/NotificationServiceProtocol.swift` (`SCProtocol`)
    *   ライブ実装: `LiveNotificationService` (in `/SCLiveService/LiveNotificationService.swift`, `SCLiveService`)
    *   プレビュー実装: `PreviewNotificationService` (in `/SCPreview/PreviewNotificationService.swift`, `SCPreview`)
    *   テスト用デフォルト/モック実装: `MockNotificationService` (in `/SCMock/MockNotificationService.swift`, `SCMock`)
*   **`extendedRuntimeService: ExtendedRuntimeServiceProtocol`**: 拡張ランタイムセッションの管理
    *   プロトコル: `/SCProtocol/ExtendedRuntimeServiceProtocol.swift` (`SCProtocol`)
    *   ライブ実装: `LiveExtendedRuntimeService` (in `/SCLiveService/LiveExtendedRuntimeService.swift`, `SCLiveService`)
    *   プレビュー実装: `PreviewExtendedRuntimeService` (in `/SCPreview/PreviewExtendedRuntimeService.swift`, `SCPreview`)
    *   テスト用デフォルト/モック実装: `MockExtendedRuntimeService` (in `/SCMock/MockExtendedRuntimeService.swift`, `SCMock`)
*   **`hapticsService: HapticsServiceProtocol`**: 触覚フィードバックの再生
    *   プロトコル: `/SCProtocol/HapticsServiceProtocol.swift` (`SCProtocol`)
    *   ライブ実装: `LiveHapticsService` (in `/SCLiveService/LiveHapticsService.swift`, `SCLiveService`)
    *   プレビュー実装: `PreviewHapticsService` (in `/SCPreview/PreviewHapticsService.swift`, `SCPreview`)
    *   テスト用デフォルト/モック実装: `MockHapticsService` (in `/SCMock/MockHapticsService.swift`, `SCMock`)
*   **`continuousClock: any Clock<Duration>`**: 時間の経過 (タイマー用)
    *   (TCA標準の依存関係)

## UIテストのオーバーライド (`SilentCueApp.swift`)

(現在は未サポート) UIテスト実行時には、アプリ起動時のコマンドライン引数 (`uiTesting`) を検知し、`SilentCueApp.swift` の `init()` 内で `withDependencies` を使用して、依存関係をテスト用のモック (`SCMock` 内の実装) に差し替えます。このコードは **`#if DEBUG` による条件付きコンパイル** で囲まれ、リリースビルドには含まれません。

## 設計の進化

当初の構成から、TCAの依存性注入システムを活用し、段階的にマルチモジュールアーキテクチャへとリファクタリングされました。

*   依存関係をプロトコルベースに統一。
*   プロトコル、ライブ実装、プレビュー実装、モック実装、共有コードをそれぞれ独立したモジュール (`SCProtocol`, `SCLiveService`, `SCPreview`, `SCMock`, `SCShared`) に分離。
*   テスト時のデフォルト依存性として `TestDependencyKey` (`unimplemented`) を使用する方式から、`DependencyKey` の `testValue` で明示的にモック実装 (`SCMock` 内) を指定する方式へ変更。
*   プロジェクト管理にXcodeGenを導入。
*   モジュール名とディレクトリ名を一致させ、一貫性を向上 (例: `SCProtocol` モジュールは `/SCProtocol/` ディレクトリに対応)。
*   モジュールタイプを `framework` から `library.static` に変更し、静的リンクを利用。

これにより、モジュール間の依存関係が明確になり、ビルド時間の改善やテスト容易性の向上が期待されます。