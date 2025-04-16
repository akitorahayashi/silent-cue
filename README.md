## プロジェクト概要

SilentCueは、Apple Watch専用のタイマーアプリです。Apple Watch特有の触覚フィードバックで通知するため、音を出さずにタイマーを使用できます。

従来のiPhoneタイマーアプリと異なり、腕に装着しているApple Watchだけで完結するため、デバイスを取り出す手間がありません。また、デフォルトでは振動が3秒後に自動停止するため、タイマーが終了した際は、アプリを開いて操作する必要がなく、より快適なユーザー体験を提供します。

振動の強さや停止機能のオン・オフなど、各種設定は好みに合わせてカスタマイズできます。

## アーキテクチャ

このアプリは The Composable Architecture をベースに、Presentation Domain Separation の考え方を採用しています。これにより、UIロジックとロジックを分離しています。

-   **Presentation (プレゼンテーション層)**:
    -   `SilentCue Watch App/View/` ディレクトリ以下に配置された SwiftUI View で構成されます。
    -   View は TCA の `ViewStore` を介して状態を監視し、ユーザー操作を `Action` として `Store` に送信する役割に集中します。UI の見た目やユーザーインタラクションを担当します。

-   **Domain (ドメイン層)**:
    -   `SilentCue Watch App/Domain/` ディレクトリ以下に配置された TCA のコンポーネント (`State`, `Action`, `Reducer`) で構成されます。
    -   各機能（`App`, `Timer`, `Settings`, `Haptics`）が独立したドメインとして定義され、それぞれの状態管理、ビジネスロジック、副作用（UserDefaultsへの保存、振動の実行など）を担当します。
    -   `AppReducer` がルートとなり、各機能ドメインの Reducer を統合し、アプリ全体の状態遷移や機能間の連携（タイマー完了時の振動開始など）を管理します。
    -   依存性（UserDefaults, Clock など）は `@Dependency` を通じて注入され、テスト時にはモックに差し替えることが可能です。

この構成により、各ドメインは他のドメインの実装詳細を知ることなく独立して開発・テストが可能となり、SwiftUI の View は状態を表示しユーザー入力を伝えるだけの薄い層になります。

## ディレクトリ構成

```
SilentCue/
├── .github/workflows/
│   ├── ci-cd-pipeline.yml # メインのCI/CDパイプライン
│   └── callable_workflows/ # 再利用可能なワークフロー群
│       ├── build-and-test.yml
│       ├── build-for-production.yml
│       ├── code-quality.yml
│       ├── pr-reviewer.yml
│       └── test-reporter.yml
├── SilentCue Watch App/
│   ├── Assets.xcassets/
│   ├── Domain/
│   │   ├── App/
│   │   │   ├── AppAction.swift
│   │   │   ├── AppReducer.swift
│   │   │   ├── AppState.swift
│   │   │   └── NavigationDestination.swift
│   │   ├── Settings/
│   │   │   ├── SettingsAction.swift
│   │   │   ├── SettingsReducer.swift
│   │   │   └── SettingsState.swift
│   │   ├── Timer/
│   │   │   ├── TimerAction.swift
│   │   │   ├── TimerReducer.swift
│   │   │   └── TimerState.swift
│   │   └── Haptics/
│   │       ├── HapticsAction.swift
│   │       ├── HapticsReducer.swift
│   │       ├── HapticsState.swift
│   │       └── HapticType.swift
│   ├── Preview Content/
│   ├── StorageService/
│   │   ├── UserDefaultsDependency.swift
│   │   ├── UserDefaultsManager.swift
│   │   └── UserDefaultsManagerProtocol.swift
│   ├── Util/
│   │   ├── ExtendedRuntimeManager.swift
│   │   └── SCTimeFormatter.swift
│   ├── View/
│   │   ├── CountdownView/
│   │   ├── SetTimerView/
│   │   ├── SettingsView/
│   │   └── TimerCompletionView/
│   └── SilentCueApp.swift
├── SilentCue Watch AppTests/
│   ├── Domain/
│   ├── Mocks/
│   ├── StorageService/
│   └── SilentCue_Watch_AppTests.swift
├── SilentCue Watch AppUITests/
│   ├── CountdownViewUITests.swift
│   └── SettingsViewUITests.swift
├── .gitignore
├── .swiftformat
├── .swiftlint.yml
├── Mintfile
├── README.md
├── SilentCue.xcodeproj/
└── SilentCue-Watch-App-Info.plist
```

## 技術スタック

- **言語とフレームワーク**
  - Swift
  - SwiftUI
  - WatchKit

- **状態管理**
  - The Composable Architecture (バージョンは `Package.swift` を参照)

- **永続化**
  - UserDefaults

- **ネイティブ機能**
  - WKExtendedRuntimeSession
  - WKHapticType

## 主要機能

### 直感的な設定
Apple Watchの小さな画面でも時間を直感的に設定でき、分数を指定する他に特定の時刻までの正確なカウントダウンにも対応しています。

### 振動による無音通知
Apple Watch独自の触覚フィードバック機能を活用し、最小限の音でタイマーの完了を通知します。複数の振動パターンから好みの振動を選択することも可能です。

### 自動停止機能
タイマー完了時の振動がデフォルトで3秒後に自動的に停止するため、アプリを開いて操作する必要がありません。

### カスタマイズ可能な設定
振動のパターンを好みに合わせて調整できます。各設定は永続的に保存され、アプリを再起動しても維持されます。

### バックグラウンド実行
Apple Watchアプリを閉じた後もタイマーが正確に動作し続けます。WKExtendedRuntimeSessionを活用した高度なバックグラウンド処理により、アプリがバックグラウンドにある状態でも正確な時間計測と通知を実現しています。長時間のタイマーでも精度を維持します。

### バックグラウンドでのタイマー完了対応
バックグラウンドでタイマーが完了した場合の動作は以下のようになっています：

- **通知機能**: タイマー設定時に自動的に通知がスケジュールされ、タイマー完了時に通知が表示されます。これにより、アプリがバックグラウンドにある時でもタイマーの完了を知ることができます。

- **通知アクション**: 通知には「アプリを開く」アクションが含まれており、タップするとタイマー完了画面に遷移します。通知自体ですでに音や振動でユーザーに知らせているため、通知から起動した場合は余計な振動を避ける設計になっています。

- **フォアグラウンド復帰時**: アプリを通知以外の方法で直接開いた場合、タイマーが既に完了していれば完了画面が表示されます。通知経由でない場合のみ振動が発生する仕組みになっています。

- **堅牢なバックグラウンド処理**: WKExtendedRuntimeSessionを活用して、Apple Watchの厳しいバックグラウンド制限下でも正確にタイマーの状態を追跡し、信頼性の高いタイマー機能を提供します。

- **通知許可のガイダンス**: 通知を許可していないユーザーに対しては、タイマー完了画面で通知許可を促すボタンを表示します。「通知を有効にする」ボタンをタップすると、通知を許可することでアプリを閉じた状態でもタイマー完了を知ることができるようになります。

## CI/CD パイプライン

このプロジェクトでは、GitHub Actions を利用して CI/CD パイプラインを構築しています。`.github/workflows/` ディレクトリ以下に設定ファイルが格納されています。

- **`ci-cd-pipeline.yml`**: メインとなる統合パイプラインです。Pull Request作成時やmainブランチへのプッシュ時にトリガーされ、以下のステップを順次実行します。
    - コード品質チェック
    - ビルドとテスト（ユニットテスト、UIテスト）
    - テスト結果レポート
    - (PR時) 自動コードレビュー
    - (mainブランチ時) 本番用ビルド生成
    - 完了通知

- **`callable_workflows/` ディレクトリ**: パイプラインの各ステップを実行する、再利用可能なワークフロー群です。
    - **`code-quality.yml`**: SwiftFormatとSwiftLintによるコードフォーマットと静的解析を実行します。
    - **`build-and-test.yml`**: アプリのビルド、ユニットテスト、UIテストを実行します。
    - **`test-reporter.yml`**: テスト結果（JUnit形式）を解析し、Pull Requestにサマリーをコメントします。
    - **`pr-reviewer.yml`**: (PR時) GitHub Copilotを利用した自動コードレビューを試みます。
    - **`build-for-production.yml`**: mainブランチへのマージ時に、App Store提出用または開発用のIPAファイルを生成します。GitHub Releasesへのドラフト作成も行います。

## 開発環境

プロジェクトのビルドと開発に必要なツールとそのバージョンは `Mintfile` で管理されています。
以下のコマンドで必要なツール (`SwiftFormat`, `SwiftLint`) をインストールできます。

```bash
# Mintをインストール（未導入の場合）
brew install mint

# Mintfileに記載されたツールをインストール/アップデート
mint bootstrap
```

TCAなどの依存パッケージはSwift Package Managerによって自動的に管理されるため、Xcodeがプロジェクトを開く際に必要なパッケージを自動的にダウンロードします。

これにより、プロジェクトで使用している以下のツールが自動的にインストール、またはバージョン管理されます：
- SwiftLint (`0.54.0`)
- SwiftFormat (`0.52.0`)
