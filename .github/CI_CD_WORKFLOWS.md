# CI/CD Workflows

このディレクトリには SilentCue アプリケーション用の GitHub Actions ワークフローファイルが含まれています。

## ファイル構成

- **`ci-cd-pipeline.yml`**: メインとなる統合CI/CDパイプラインです。Pull Request作成時やmainブランチへのプッシュ時にトリガーされ、後述の他のワークフローを順次実行します。
- **`run-tests.yml`**: アプリのテスト向けビルドとその成果物を使ったテストを実行します。
- **`build-unsigned-archive.yml`**: 署名なしのアーカイブ（.xcarchive）を作成する再利用可能ワークフロー。主に`ci-cd-pipeline.yml`から`main`ブランチのビルド検証のために呼び出されます。
- **`code-quality.yml`**: コード品質チェック（SwiftFormat, SwiftLint）を実行します。
- **`test-reporter.yml`**: テスト結果のレポートを作成し、PRにコメントします。
- **`copilot-review.yml`**: GitHub CopilotによるPRレビューを自動化します。
- **`release.yml`**: vX.Y.Z 形式のタグプッシュ時にトリガーされ、アプリのビルド、署名、App Store Connectへのアップロード、GitHub Releaseの作成とIPA添付を行います。

## CIの特徴

### - モジュラー設計
メインの`ci-cd-pipeline.yml`が、テスト、コード品質チェック、アーカイブビルドなどの個別の再利用可能ワークフローを呼び出す構造になっています。

### 包括的なビルドプロセスの検証
Pull Requestや`main`ブランチへのプッシュ時に、以下の自動チェックを実行します。
- コードフォーマット (SwiftFormat) と静的解析 (SwiftLint)
- ユニットテストとUIテスト
- リリース設定でのアーカイブビルドを検証（`main`ブランチプッシュ時）

### Pull Request に自動でレビュー
Pull Requestに対して、テスト結果のレポート、GitHub Copilotによる自動レビューリクエスト、パイプライン全体の完了ステータス通知を行います。

### 成果物管理
- 成果物管理: ビルドやテストの成果物はGitHub Artifactsとしてアップロード・管理されます。
- 出力先を統一: 全てのビルド・テスト関連の成果物は、一貫して `ci-outputs/` ディレクトリ以下に出力されます。

### 自動リリース機能
`vX.Y.Z`形式のタグがプッシュされると、`release.yml`ワークフローが自動的にトリガーされ、以下の処理を実行します。
- アプリケーションのビルドと署名
- App Store ConnectへのIPAファイルアップロード
- GitHub Releaseの作成とIPAファイルの添付

### ローカルでの検証
`validate-ci-build-steps.sh`スクリプトを提供しており、主要なCIステップ（テスト、アーカイブ）をローカル環境で再現・検証できます。

## 機能詳細

### `ci-cd-pipeline.yml`

このワークフローは、SilentCue アプリケーションの CI/CD プロセスの中心的な流れを管理します。

**トリガー**:
- `main` または `master` ブランチへのプッシュ時 (`push`)
- `main` または `master` ブランチをターゲットとする Pull Request 作成・更新時 (`pull_request`)
- 手動実行時 (`workflow_dispatch`)
**処理内容**:
1.  `code-quality.yml` を呼び出し、コード品質をチェックします。
2.  `run-tests.yml` を呼び出し、ビルドとテスト（ユニット・UI）を実行します。
3.  Pull Request の場合、`test-reporter.yml` を呼び出し、テスト結果を PR にレポートします。
4.  Pull Request の場合、`copilot-review.yml` を呼び出し、GitHub Copilot による自動レビューを依頼します。
5.  `main` ブランチへのプッシュの場合、`build-unsigned-archive.yml` を呼び出し、Release 設定でのアーカイブビルドが成功するか検証します。
6.  最後に、パイプライン全体の完了ステータスを Pull Request にコメントします。（PR の場合）

### `run-tests.yml`

このワークフローは、アプリケーションのビルドとテスト（ユニット・UI）を実行する**再利用可能ワークフロー**です。

**トリガー**:
- `ci-cd-pipeline.yml` から `workflow_call` で呼び出されます。
**処理内容**:
1.  テスト用のアプリビルドを実行します (`xcodebuild build-for-testing`)。
2.  ユニットテストを実行し、結果を JUnit 形式で保存します。
3.  UI テストを実行し、結果を JUnit 形式で保存します。
4.  生成されたテスト結果（`.xcresult`, `.xml`）を `test-results` という名前のアーティファクトとしてアップロードします。
**出力**:
- テストの成功/失敗ステータス (`test_result`) を呼び出し元に返します。

### `build-unsigned-archive.yml`

このファイルは、署名なしのアーカイブビルドを作成する**再利用可能ワークフロー**です。

**トリガー**:
- `ci-cd-pipeline.yml` から `workflow_call` で呼び出されます。
**処理内容**:
1.  Release設定で署名なしのアーカイブビルド (`.xcarchive`) を作成します。
2.  アーカイブの内容を検証します。
3.  作成された `.xcarchive` を `unsigned-archive` という名前のアーティファクトとしてアップロードします。
**主な用途**:
- `ci-cd-pipeline.yml` の `main` ブランチへのプッシュ時に、Releaseビルドが成功するかどうかの検証に使用されます。

### `code-quality.yml`

このワークフローは、コードのフォーマットと静的解析を行う**再利用可能ワークフロー**です。

**トリガー**:
- `ci-cd-pipeline.yml` から `workflow_call` で呼び出されます。
**処理内容**:
1.  Mint を使用して SwiftFormat と SwiftLint をインストールします。
2.  SwiftFormat を実行してコードをフォーマットします。
3.  SwiftLint を `--strict` オプション付きで実行し、違反があればエラーとします。
4.  `git diff` でフォーマットによる変更がないか確認します。
**出力**:
- チェックの成功/失敗ステータス (`result`) を呼び出し元に返します。

### `test-reporter.yml`

このワークフローは、テスト結果を GitHub Checks と Pull Request コメントにレポートする**再利用可能ワークフロー**です。

**トリガー**:
- Pull Request 時に `ci-cd-pipeline.yml` から `workflow_call` で呼び出されます。
**入力**:
- レポート対象の Pull Request 番号 (`pull_request_number`)。
**処理内容**:
1.  `run-tests.yml` でアップロードされた `test-results` アーティファクトをダウンロードします。
2.  JUnit レポート (`.xml`) が存在する場合、`mikepenz/action-junit-report` を使用して GitHub Checks に結果を表示します。
3.  Pull Request にテスト結果のサマリーコメントを作成または更新します。

### `copilot-review.yml`

このワークフローは、Pull Request に対して GitHub Copilot によるレビューを依頼する**再利用可能ワークフロー**です。

**トリガー**:
- Pull Request 時に `ci-cd-pipeline.yml` から `workflow_call` で呼び出されます。
**入力**:
- レビュー対象の Pull Request 番号 (`pr_number`)。
**処理内容**:
1.  指定された Pull Request に GitHub Copilot (`copilot`) をレビュアーとして追加します。
2.  レビュアー追加に失敗した場合、エラーメッセージを含むコメントを Pull Request に投稿します。

### `release.yml`

このワークフローは、アプリケーションのビルド、署名、配布、および GitHub Release の作成を行います。

**トリガー**:
- `v*.*.*` という形式のタグ（例: `v1.0.0`）がリポジトリにプッシュされた時。
**処理内容**:
1.  プッシュされたタグが指すコミットのコードをチェックアウトします。
2.  SPMキャッシュを利用しつつ、Release設定でアプリをビルドし、署名なしの `.xcarchive` を作成します。
3.  GitHub Secretsに保存された証明書とプロファイルを使って一時キーチェーンを準備し、`.xcarchive` に署名して `.ipa` ファイルをエクスポートします。
4.  生成された `.ipa` を App Store Connect にアップロードします。
5.  トリガーとなったタグ名で GitHub Release を作成（または更新）し、生成された `.ipa` ファイルをアセットとして添付します。
  (必要なSecrets: 署名と配布に必要な各種キー、証明書、プロファイル等をGitHub Secretsに設定しておく必要があります)

## 使用方法

メインパイプライン (`ci-cd-pipeline.yml`) は以下のタイミングで自動実行されます:

- **プッシュ時**: `main` または `master` ブランチへのプッシュ
- **PR作成/更新時**: `main` または `master` ブランチをターゲットとするPull Request
- **手動実行**: GitHub Actionsタブから `ci-cd-pipeline.yml` を選択して実行可能

個別のワークフローは通常、直接実行するのではなく、`ci-cd-pipeline.yml` によって呼び出されます。

## ローカルでのCIプロセスの検証

GitHub Actions で実行される CI/CD パイプラインの主要なステップ（テスト、アーカイブ、IPAエクスポート）をローカルで検証するためのスクリプトを用意しています。

このスクリプトは、CI と同様の環境（パス設定など）でビルドとテストを実行し、成果物が期待通りに生成されるかを確認するのに役立ちます。

以下のコマンドで実行できます

```bash
$ ./.github/scripts/validate-ci-build-steps.sh
```

1.  `ci-outputs/` ディレクトリをクリーンアップし、再作成します。
2.  テスト用のビルドを実行します。
3.  テスト用のビルドの成果物を使って、ユニットテストとUIテストを実行します。
4.  リリース用（署名なし）のアーカイブを作成します。
5.  アーカイブの内容を検証します。

## 技術仕様

- Xcodeバージョン: 16.2
- テスト環境: watchOS シミュレータ
- 依存ツール管理: Mint (SwiftFormat, SwiftLint)
- アーティファクト保持期間: ビルド関連 = 1日、テスト結果/アーカイブビルド = 7日
- 出力先ディレクトリ: `ci-outputs/`
  - `test-results/`: テストの結果
  - `production/`: リリース用（署名なし）のアーカイブの結果

