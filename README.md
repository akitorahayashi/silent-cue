# SilentCue

## プロジェクト概要

SilentCueは、Apple Watch専用のタイマーアプリです。Apple Watch特有の触覚フィードバックで通知するため、音を出さずにタイマーを使用できます。また、振動が3秒後に自動停止するため、タイマーが終了した際は、アプリを開いて操作する必要がなく、より快適なユーザー体験を提供します。

## アーキテクチャ

このアプリは The Composable Architecture (TCA) を基盤とし、マルチモジュールアーキテクチャを採用しています。
各モジュールは特定の責務（プロトコル定義、ライブ実装、プレビュー実装、モック実装、共有コードなど）に分離されており、XcodeGen で管理されています。

詳細なアーキテクチャ設計、モジュール構成、依存関係については [ARCHITECTURE.md](./ARCHITECTURE.md) を参照してください。

## ディレクトリ構成

このプロジェクトは **XcodeGen** を使用して `.xcodeproj` ファイルを生成・管理しています。ディレクトリ構成とモジュール構造は以下の通りです。

```plaintext
SilentCue/
├── SCProtocol/
├── SCShared/
├── SCLiveService/
├── SCPreview/
├── SCDependencyMocks/
├── SilentCue Watch App/
│   ├── Assets.xcassets/
│   ├── Dependency/
│   ├── Domain/
│   ├── View/
│   ├── Util/
│   ├── Supporting Files/
│   └── SilentCueApp.swift
├── SilentCue Watch AppTests/
│   ├── Domain/
│   └── Service/
├── SilentCue Watch AppUITests/
│   ├── Constant/
│   ├── Extension/
│   ├── Util/
│   └── Tests/
├── .github/
│   └── workflows/
├── .gitignore
├── .swiftformat
├── .swiftlint.yml
├── Mintfile
├── project.yml
└── README.md
```

## 技術スタック

- **言語とフレームワーク**: Swift, SwiftUI, WatchKit
- **状態管理**: The Composable Architecture (TCA)
- **依存性管理**: swift-dependencies, Swift Package Manager (SPM)
- **プロジェクト生成**: XcodeGen
- **リンター/フォーマッター**: SwiftLint, SwiftFormat (Mintで管理)
- **ネイティブ機能**: WKExtendedRuntimeSession, WKHapticType

## 主要機能

### 直感的な設定
Apple Watchの小さな画面でも時間を直感的に設定でき、分数を指定する他に特定の時刻までの正確なカウントダウンにも対応しています

### 振動による無音通知
Apple Watch独自の触覚フィードバック機能を活用し、最小限の音でタイマーの完了を通知します複数の振動パターンから好みの振動を選択することも可能です

### 自動停止機能
タイマー完了時の振動がデフォルトで3秒後に自動的に停止するため、アプリを開いて操作する必要がありません

### カスタマイズ可能な設定
振動のパターンを好みに合わせて調整できます各設定は永続的に保存され、アプリを再起動しても維持されます

### バックグラウンド実行
Apple Watchアプリを閉じた後もタイマーが正確に動作し続けますWKExtendedRuntimeSessionを活用した高度なバックグラウンド処理により、アプリがバックグラウンドにある状態でも正確な時間計測と通知を実現しています長時間のタイマーでも精度を維持します

### バックグラウンドでのタイマー完了対応
バックグラウンドでタイマーが完了した場合の動作は以下のようになっています：

- **通知機能** タイマー設定時に自動的に通知がスケジュールされ、タイマー完了時に通知が表示されますこれにより、アプリがバックグラウンドにある時でもタイマーの完了を知ることができます

- **通知アクション** 通知には「アプリを開く」アクションが含まれており、タップするとタイマー完了画面に遷移します

- **フォアグラウンド復帰時** アプリを通知以外の方法で直接開いた場合、タイマーが既に完了していれば完了画面が表示されます通知経由でない場合のみ振動が発生する仕組みになっています

## CI/CD

このプロジェクトでは、GitHub Actions を利用して CI/CD パイプラインを構築しています`.github/workflows/` ディレクトリ以下に設定ファイルが格納されています

主なパイプライン (`ci-cd-pipeline.yml`) は、Pull Request や `main` ブランチへのプッシュ時に自動実行され、以下の主要な処理を行います:
- **コード品質チェック** SwiftFormat と SwiftLint を実行します
- **ビルドとテスト** アプリのビルドとユニット/UIテストを実行します
- **リリース準備** `main` ブランチへのプッシュ時には、署名なしの `.xcarchive` を作成し、アーティファクトとして保存します

**リリースのプロセス**
- App Store Connect への配布や GitHub Releases への `.ipa` ファイルのアップロードは、**手動トリガー**によるワークフロー (`release.yml`) で行います
- この手動ワークフローは、保存された署名なし `.xcarchive` をダウンロードし、必要な証明書とプロファイルで署名した後、配布を実行します

**主な機能**
- **Pull Request**: PR作成・更新時に、コード品質チェック、ビルド、テストが自動実行されます
- **Mainブランチ**: `main` ブランチへのプッシュ時にも同様のチェックが実行されます
- **リリース**: `vX.Y.Z` 形式のタグがプッシュされると、リリース用のワークフロー (`release.yml`) が自動実行され、ビルド、署名、App Store Connect へのアップロード、GitHub Release の作成が行われます

詳細なワークフローの説明は [CI_CD_WORKFLOWS.md](./.github/CI_CD_WORKFLOWS.md) を参照してください

## リリース方法

1.  リリース対象のコミットを決定します
   - 最新の `main` ブランチのコミットをリリースする場合 (通常):
     ```bash
     git checkout main
     git pull origin main
     ```
   - 過去の特定のコミットをリリースする場合:
     リリースしたいコミットのハッシュ値を確認します`git log` や GitHub の履歴で探します
     ```bash
     git log --oneline --graph
     ```
     見つけたコミットハッシュ (例: `a1b2c3d`) を控えておきます

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
これにより、GitHub Actions の `release.yml` ワークフローが自動的にトリガーされ、App Store Connect へのアップロードと GitHub Release の作成が行われます

## 開発環境セットアップ

1.  **Mintのインストール (未導入の場合):**
    ```bash
    brew install mint
    ```
2.  **開発ツールのインストール:**
    `Mintfile` で管理されているSwiftLintとSwiftFormatをインストールします。
    ```bash
    mint bootstrap
    ```
3.  **Xcodeプロジェクトファイルの生成:**
    XcodeGenを使用して `.xcodeproj` ファイルを生成します。プロジェクトを開く前に必ず実行してください。
    ```bash
    mint run xcodegen generate
    # または xcodegen generate (XcodeGenが直接インストールされている場合)
    ```
4.  **プロジェクトを開く:** 生成された `SilentCue.xcodeproj` をXcodeで開きます。
    依存パッケージ (TCAなど) はSPMによって自動的に解決・ダウンロードされます。
