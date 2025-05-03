# CI/CD Workflows

## ファイル構成

- **`ci-cd-pipeline.yml`**: メインとなる統合CI/CDパイプラインで、Pull Request作成時やmainブランチへのプッシュ時にトリガーされ、後述の他のワークフローを順次実行します
- **`run-tests.yml`**: アプリのビルドとテスト（ユニット・UI）を実行する再利用可能ワークフローです
- **`setup-mint.yml`**: Mint（Swiftパッケージマネージャ）をセットアップし、依存ライブラリ（SwiftFormat, SwiftLintなど）をインストール・キャッシュする再利用可能ワークフローです
- **`build-unsigned-archive.yml`**: 署名なしのアーカイブ（.xcarchive）を作成する再利用可能ワークフローです
- **`code-quality.yml`**: コード品質チェック（SwiftFormat, SwiftLint）を実行します
- **`test-reporter.yml`**: テスト結果のレポートを作成し、PRにコメントします
- **`copilot-review.yml`**: GitHub CopilotによるPRレビューを自動化します
- **`release.yml`**: vX.Y.Z 形式のタグプッシュ時にトリガーされ、アプリのビルド、署名、App Store Connectへのアップロード、GitHub Releaseの作成とIPA添付を行います

## CIの特徴

### ワークフローの分割
メインの`ci-cd-pipeline.yml`が、テスト、コード品質チェック、アーカイブビルドなどの個別の再利用可能ワークフローを呼び出す構造になっています
コアなビルド・テスト・アーカイブ処理は、各ワークフロー (`run-tests.yml`, `build-unsigned-archive.yml` など) の `run` ステップ内に `xcodebuild` コマンドとして直接記述されています (一部ヘルパースクリプト `.github/scripts/find-simulator.sh` を除く)

### 包括的なビルドプロセスの検証
Pull Requestや`main`ブランチへのプッシュ時に、以下の自動チェックを実行します
- コードフォーマット (SwiftFormat) と静的解析 (SwiftLint)
- UnitテストとUIテスト、およびそれらの結果（xcresult）の検証
- リリース設定でのアーカイブビルドと結果の検証（`main`ブランチプッシュ時）

### Pull Request に自動でレビュー
Pull Requestに対して、テスト結果のレポート、GitHub Copilotによる自動レビューリクエスト、パイプライン全体の完了ステータス通知を行います

### 成果物管理
- 成果物管理: ビルドやテストの成果物はGitHub Artifactsとしてアップロード・管理されます
- 出力先を統一: 全てのビルド・テスト関連の成果物は、一貫して `ci-outputs/` ディレクトリ以下に出力されます

### リリース機能
`vX.Y.Z`形式のタグがプッシュされると、`release.yml`ワークフローが自動的にトリガーされ、以下の処理を実行します
- アプリケーションのビルドと署名
- App Store ConnectへのIPAファイルアップロード
- GitHub Releaseの作成とIPAファイルの添付

### ローカルでの検証
主要なCIステップ（テスト、アーカイブ）のコアロジックはワークフローファイルに直接記述されていますが、一部共通処理 (`find-simulator.sh`) やローカルでの検証を容易にするためのスクリプト (`.github/scripts/run-local-ci.sh`) も提供されています。ただし、`run-local-ci.sh` はCIで実行されるロジックとは**独立しており**、ローカルでの再現・検証を目的としています。CIのワークフロー自体は、このスクリプトを**利用しません**。

## 機能詳細

### `ci-cd-pipeline.yml` (メインパイプライン)

- **トリガー**: `main`/`master`へのPush、`main`/`master`ターゲットのPR、手動実行
- **処理**:
    1.  Mint依存関係セットアップ (`setup-mint.yml`)
    2.  コード品質チェック (`code-quality.yml` - `setup` に依存)
    3.  ビルドとテスト実行 (`run-tests.yml` - `setup` に依存)
    4.  テスト結果レポート (PR時, `test-reporter.yml` - `build-and-test` に依存)
    5.  Copilotレビュー依頼 (PR時, `copilot-review.yml` - `build-and-test` に依存)
    6.  アーカイブビルド検証 (`main` Push時, `build-unsigned-archive.yml` - `build-and-test`と`code-quality` に依存)
    7.  パイプライン完了ステータス通知 (PR時 - 上記ジョブ全てに依存)

### `setup-mint.yml` (Mint依存関係セットアップ)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  リポジトリをチェックアウト
    2.  Homebrewをセットアップ
    3.  Mintをインストール (`brew install mint`)
    4.  Mintパッケージをキャッシュ (`actions/cache`)
    5.  Mintパッケージをブートストラップ (`mint bootstrap`)

### `run-tests.yml` (テスト実行)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  Mintキャッシュを復元し、Mintをインストール
    2.  Xcodeセットアップ
    3.  Xcodeプロジェクト生成 (`mint run xcodegen generate`)
    4.  watchOSシミュレータを選択 (`.github/scripts/find-simulator.sh` を実行)
    5.  テスト用ビルド (`xcodebuild build-for-testing` を実行)
    6.  Unitテスト実行と結果検証 (`xcodebuild test-without-building` を実行、結果ファイルの存在確認)
    7.  UIテスト実行と結果検証 (`xcodebuild test-without-building` を実行、結果ファイルの存在確認)
    8.  JUnit XMLレポート生成 (`xcbeautify` を利用)
    9.  テスト結果 (`.xcresult`, `.xml`) をアーティファクト (`test-results`) としてアップロード

### `build-unsigned-archive.yml` (署名なしアーカイブ作成)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  Mintキャッシュを復元し、Mintをインストール
    2.  Xcodeセットアップ
    3.  Xcodeプロジェクト生成 (`mint run xcodegen generate`)
    4.  アーカイブビルド (`xcodebuild archive` を実行)
    5.  アーカイブ内容検証 (シェルスクリプトでファイル存在確認)
    6.  `.xcarchive` をアーティファクト (`unsigned-archive`) としてアップロード

### `code-quality.yml` (コード品質チェック)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  Mintキャッシュを復元し、Mintをインストール
    2.  SwiftFormatを実行 (`mint run swiftformat`)
    3.  SwiftLint (`--strict`) を実行 (`mint run swiftlint`)
    4.  `git diff` でフォーマット変更がないか確認

### `test-reporter.yml` (テスト結果レポート)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し (PR時)
- **処理**:
    1.  `test-results` アーティファクトをダウンロード
    2.  JUnitレポートからGitHub Checksに結果を表示
    3.  PRにテスト結果サマリーをコメント

### `copilot-review.yml` (Copilotレビュー依頼)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し (PR時)
- **処理**:
    1.  Copilotをレビュアーに追加
    2.  失敗時にエラーコメントをPRに投稿

### `release.yml` (リリース)

- **トリガー**: `v*.*.*` 形式のタグプッシュ (例: `v1.0.0`)
- **処理**:
    1.  コードチェックアウト
    2.  署名なし `.xcarchive` 作成 (Release設定)
    3.  Secretsを使用し、`.ipa` ファイルを署名・エクスポート
    4.  `.ipa` を App Store Connect にアップロード
    5.  GitHub Release を作成し、`.ipa` をアセットとして添付
    *(Secrets設定が必要)*

## 使用方法

メインパイプライン (`ci-cd-pipeline.yml`) は以下のタイミングで自動実行されます:

- **プッシュ時**: `main` または `master` ブランチへのプッシュ
- **PR作成/更新時**: `main` または `master` ブランチをターゲットとするPull Request
- **手動実行**: GitHub Actionsタブから `ci-cd-pipeline.yml` を選択して実行可能

個別のワークフローは通常、直接実行するのではなく、`ci-cd-pipeline.yml` によって呼び出されます

## ローカルでのCIプロセスの検証

**注意:** ローカル検証用スクリプト (`.github/scripts/run-local-ci.sh`) は、CIワークフローが実際に実行するステップとは独立したものです。このスクリプトはローカル環境でのビルド・テストプロセスをシミュレート・検証するために提供されていますが、CIパイプライン自体はこのスクリプトを使用しません。CIの実際の動作はワークフローファイル (`.yml`) に定義されています。

初回実行前に、以下のコマンドでスクリプトに実行権限を付与してください
```