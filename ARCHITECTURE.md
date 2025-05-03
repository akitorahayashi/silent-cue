このドキュメントは、SilentCue Watchアプリ内で、The Composable Architecture を基盤としたマルチモジュールアーキテクチャにおける依存関係の管理設計について説明します。

## 1. コアコンセプト：TCAにおける依存関係管理

TCAには、依存関係を管理するための仕組みがあり、このアプリの設計の中心となるのは以下の原則です。

*   **依存性の逆転:** 具体的な実装に直接依存せず、抽象的なインターフェース（プロトコル）に依存します。
*   **責務の分離:** アプリケーションの各機能レイヤーやビルド環境（本番、プレビュー、テスト）で使用される依存関係の実装を、独立したモジュールに分離します。
*   **テスト容易性:** 依存関係を容易に差し替え可能にし、ユニットテストやUIテストを実行しやすくします。

TCAでは、`DependencyKey` プロトコルと `@Dependency` プロパティラッパーを使用してこれを実現します。

*   **`DependencyKey`**: 各依存関係に対して一意なキーを定義します。このキーは、本番用 (`liveValue`)、プレビュー用 (`previewValue`)、テスト用 (`testValue`) のデフォルト実装を指定します。
*   **`@Dependency`**: Reducerなどのコンポーネントで、必要な依存関係を宣言的に注入します。TCAは実行コンテキストに応じて、`DependencyKey` で定義された、対応する実装を提供します。

## 2. モジュール構成と役割

依存関係管理においては、以下のコンポーネントを独立したモジュールとして構成しています。各モジュールの役割、配置場所、依存関係、ビルド構成におけるリンクの扱いは以下の表のようになります。

| モジュール名           | 主な役割/内容                         | 配置場所 (ルート直下)            | Xcodeターゲット (Type) | 主な依存先                   | ビルド構成リンク           | アクセス制御 |
| :------------------- | :------------------------------------ | :----------------------------- | :------------------- | :------------------------- | :----------------------- | :--------- |
| `Infrastructure`     | 低レベル実装詳細 (下記を含む)         | `/Infrastructure/`             | -                    | -                          | -                        | -          |
|   `SCProtocol`       | サービスインターフェース (プロトコル) | `/Infrastructure/SCProtocol/`  | `library.static`     | `Dependencies`           | 常時                     | `public`   |
|   `SCLiveService`    | 本番サービス実装                      | `/Infrastructure/SCLiveService/` | `library.static`     | `SCProtocol`, `ComposableArchitecture` | 常時                     | `public`   |
|   `SCPreview`        | プレビュー用実装・アセット            | `/Infrastructure/SCPreview/`   | `library.static`     | `SCProtocol`, `ComposableArchitecture` | Debug のみ (Appリンク時) | `public`   |
|   `SCMock`           | テスト用モック実装                    | `/Infrastructure/SCMock/`      | `library.static`     | `SCProtocol`, `ComposableArchitecture` | Debug のみ (Appリンク時), 常時 (Testsリンク時) | `public`   |
| `SCShared`         | 複数モジュールで共有されるコード      | `/SCShared/`                   | `library.static`     | `SCProtocol`, `ComposableArchitecture` | 常時                     | `public`   |
| `SilentCue_Watch_App` (本体) | UI, Domain, DI設定             | (アプリ内)                     | `application.watchapp2`| 各モジュール, `ComposableArchitecture` | -                        | -          |

## 3. 管理戦略

*   **XcodeGen:** プロジェクトファイル (`.xcodeproj`) は `project.yml` から生成する構成です。モジュール構成や依存関係、ビルド設定は `project.yml` で管理します。
*   **ディレクトリ構造:** 上記のモジュール構成に従い、ファイルを各モジュールのディレクトリ (`/Infrastructure/SCProtocol/`, `/SCShared/`, `/Infrastructure/SCLiveService/`, `/Infrastructure/SCPreview/`, `/Infrastructure/SCMock/`) に配置するようにします。
*   **命名規則:** `*ServiceProtocol`, `Live*Service`, `Preview*Service`, `Mock*Service` の一貫性を保つようにします。
*   **`DependencyKey` の設定:** `SCDependencyKeys.swift` で各依存関係の `liveValue`, `previewValue`, `testValue` を**設定し**、`#if DEBUG` を用いてビルド構成に応じた実装を参照するようにします。モジュール名をプレフィックスとして付与します (例: `SCLiveService.LiveUserDefaultsService`, `SCMock.MockUserDefaultsManager`)。
*   **アクセス制御:** モジュール間で共有される `protocol`, `class`, `struct`, `enum`, `init` などには `public` 修飾子を適用します。
*   **テストでの依存関係注入:**
    *   **ユニットテスト:** `TestStore` を使用する場合、デフォルトでは `SCDependencyKeys.swift` の `testValue` (Mock実装、`SCMock`内) が注入されるようになっています。特定のテストケースで挙動を変更したい場合は、`TestStore` 初期化時の `withDependencies` や `store.dependencies.service = specificMock` で上書きすることができます。
    *   **UIテスト:** (現在は未サポート) アプリ起動時に `launchArguments` 等でテストモードを識別し、アプリの早期段階 (`SilentCueApp.init()` 等) で `withDependencies` を使用して、必要な依存関係をテスト用のモック (`SCMock` 内の実装) に差し替えることを想定しています。この差し替えコードは `#if DEBUG` で囲むようにします。

## 4. UIテストのオーバーライド (`SilentCueApp.swift`)

(現在は未サポート) UIテスト実行時には、アプリ起動時のコマンドライン引数 (`uiTesting`) を検知し、`SilentCueApp.swift` の `init()` 内で `withDependencies` を使用して、依存関係をテスト用のモック (`SCMock` 内の実装) に差し替えることを想定しています。このコードは **`#if DEBUG` による条件付きコンパイル** で囲むことで、リリースビルドに含まれないようにします。
