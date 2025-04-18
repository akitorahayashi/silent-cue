## プロジェクト概要

SilentCueは、Apple Watch専用のタイマーアプリです。Apple Watch特有の触覚フィードバックで通知するため、音を出さずにタイマーを使用できます。

従来のiPhoneタイマーアプリと異なり、腕に装着しているApple Watchだけで完結するため、デバイスを取り出す手間がありません。また、デフォルトでは振動が3秒後に自動停止するため、タイマーが終了した際は、アプリを開いて操作する必要がなく、より快適なユーザー体験を提供します。

振動の強さや停止機能のオン・オフなど、各種設定は好みに合わせてカスタマイズできます。

## アーキテクチャ

このアプリは The Composable Architecture をベースに、Presentation Domain Separation の考え方を採用しています。

### プレゼンテーション層
- `SilentCue Watch App/View/` ディレクトリ以下に配置された SwiftUI View で構成されます。
- View は TCA の `ViewStore` を介して状態を監視し、ユーザー操作を`Action` として `Store` に送信します。また、 UI の見た目やインタラクションを担当します。

### ドメイン層
- `SilentCue Watch App/Domain/` ディレクトリ以下に配置された TCA のコンポーネント (`State`, `Action`, `Reducer`) で構成されます。
- 各機能（`App`, `Timer`, `Settings`, `Haptics`）が独立したドメインとして定義され、それぞれの状態管理、ビジネスロジック、副作用（UserDefaultsへの保存、振動の実行など）を担当します。
- `AppReducer` がルートとなり、各機能ドメインの Reducer を統合し、アプリ全体の状態遷移や機能間の連携（タイマー完了時の振動開始など）を管理します。
- 依存性（UserDefaults, Clock など）は `@Dependency` を通じて注入され、テスト時にはモックに差し替えることが可能です。

## ディレクトリ構成

```
SilentCue/
├── .github/
│   ├── README.md # 各ワークフローの詳細はこちら
│   ├── scripts/
│   │   ├── find-simulator.sh
│   │   └── validate-ci-build-steps.sh
│   └── workflows/
│       ├── ci-cd-pipeline.yml
│       ├── run-tests.yml
│       ├── build-unsigned-archive.yml
│       ├── code-quality.yml
│       ├── copilot-review.yml
│       ├── test-reporter.yml
│       └── release.yml
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
│   │   └── UserDefaultsManager.swift
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
│   ├── Mock/ # Renamed from Mocks/
│   └── StorageService/
├── SilentCue Watch AppUITests/
│   ├── CountdownViewUITests.swift
│   ├── SettingsViewUITests.swift
│   └── Util/
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
  - The Composable Architecture

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

- **通知機能** タイマー設定時に自動的に通知がスケジュールされ、タイマー完了時に通知が表示されます。これにより、アプリがバックグラウンドにある時でもタイマーの完了を知ることができます。

- **通知アクション** 通知には「アプリを開く」アクションが含まれており、タップするとタイマー完了画面に遷移します。

- **フォアグラウンド復帰時** アプリを通知以外の方法で直接開いた場合、タイマーが既に完了していれば完了画面が表示されます。通知経由でない場合のみ振動が発生する仕組みになっています。

## CI/CD パイプライン

このプロジェクトでは、GitHub Actions を利用して CI/CD パイプラインを構築しています。`.github/workflows/` ディレクトリ以下に設定ファイルが格納されています。

主なパイプライン (`ci-cd-pipeline.yml`) は、Pull Request や `main` ブランチへのプッシュ時に自動実行され、以下の主要な処理を行います:
- **コード品質チェック** SwiftFormat と SwiftLint を実行します。
- **ビルドとテスト** アプリのビルドとユニット/UIテストを実行します。
- **リリース準備** `main` ブランチへのプッシュ時には、署名なしの `.xcarchive` を作成し、アーティファクトとして保存します。

**リリースのプロセス**
- App Store Connect への配布や GitHub Releases への `.ipa` ファイルのアップロードは、**手動トリガー**によるワークフロー (`sign-and-distribute.yml`) で行います。
- この手動ワークフローは、保存された署名なし `.xcarchive` をダウンロードし、必要な証明書とプロファイルで署名した後、配布を実行します。

**主な機能**
- **Pull Request** PR作成・更新時に、コード品質チェック、ビルド、テストが自動実行されます。
- **Mainブランチ** `main` ブランチへのプッシュ時にも同様のチェックが実行されます。
- **リリース** `vX.Y.Z` 形式のタグがプッシュされると、リリース用のワークフロー (`release.yml`) が自動実行され、ビルド、署名、App Store Connect へのアップロード、GitHub Release の作成が行われます。

詳細なワークフローの説明は [CI_CD_WORKFLOWS.md](./CI_CD_WORKFLOWS.md) を参照してください。

## リリース方法

1.  リリース対象のコミットを決定します。
   - 最新の `main` ブランチのコミットをリリースする場合 (通常):
     ```bash
     git checkout main
     git pull origin main
     ```
   - 過去の特定のコミットをリリースする場合:
     リリースしたいコミットのハッシュ値を確認します。`git log` や GitHub の履歴で探します。
     ```bash
     git log --oneline --graph
     ```
     見つけたコミットハッシュ (例: `a1b2c3d`) を控えておきます。

2. 決定したコミットに対してタグを作成します:
   - 最新の `main` にいる場合:
     ```bash
     git tag v1.0.0
     ```
   - 過去のコミット (`a1b2c3d`) に対して直接タグ付けする場合:
     ```bash
     git tag v1.0.1 a1b2c3d
     ```

3. 作成したタグをリモートリポジトリにプッシュします:
     ```bash
     git push origin v1.0.0
     ```
これにより、GitHub Actions の `release.yml` ワークフローが自動的にトリガーされ、App Store Connect へのアップロードと GitHub Release の作成が行われます。

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
