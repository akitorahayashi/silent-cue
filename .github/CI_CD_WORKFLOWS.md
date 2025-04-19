# CI/CD Workflows

このディレクトリには SilentCue アプリケーション用の GitHub Actions ワークフローファイルが含まれています。

## ファイル構成

- **`ci-cd-pipeline.yml`**: メインとなる統合CI/CDパイプラインです。Pull Request作成時やmainブランチへのプッシュ時にトリガーされ、後述の他のワークフローを順次実行します。
- **`run-tests.yml`**: アプリのビルドとテスト（ユニット・UI）を実行する再利用可能ワークフロー。`.github/scripts/` 配下の関数定義ファイルを `source` し、必要な関数（シミュレータ選択、ビルド、テスト実行、結果検証など）を直接呼び出します。
- **`build-unsigned-archive.yml`**: 署名なしのアーカイブ（.xcarchive）を作成する再利用可能ワークフロー。`.github/scripts/` 配下の関数定義ファイルを `source` し、必要な関数（アーカイブビルド、結果検証など）を直接呼び出します。
- **`code-quality.yml`**: コード品質チェック（SwiftFormat, SwiftLint）を実行します。
- **`test-reporter.yml`**: テスト結果のレポートを作成し、PRにコメントします。
- **`copilot-review.yml`**: GitHub CopilotによるPRレビューを自動化します。
- **`release.yml`**: vX.Y.Z 形式のタグプッシュ時にトリガーされ、アプリのビルド、署名、App Store Connectへのアップロード、GitHub Releaseの作成とIPA添付を行います。

## CIの特徴

### - モジュラー設計
メインの`ci-cd-pipeline.yml`が、テスト、コード品質チェック、アーカイブビルドなどの個別の再利用可能ワークフローを呼び出す構造になっています。
コアなビルド・テスト・アーカイブ処理は、`.github/scripts/steps/` および `.github/scripts/common/` 配下のシェルスクリプトに関数として定義され、各ワークフローが必要に応じてこれらを呼び出します。

### 包括的なビルドプロセスの検証
Pull Requestや`main`ブランチへのプッシュ時に、以下の自動チェックを実行します。
- コードフォーマット (SwiftFormat) と静的解析 (SwiftLint)
- ユニットテストとUIテスト、およびそれらの結果（xcresult）の検証
- リリース設定でのアーカイブビルドと結果の検証（`main`ブランチプッシュ時）

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
主要なCIステップ（テスト、アーカイブ）のコアロジックを呼び出すローカル検証用スクリプト (`.github/scripts/run-local-validation.sh`) を提供しており、ローカル環境でCIの主要な処理フローを再現・検証できます。このスクリプトは、CIワークフローが使用する関数定義ファイルを `source` して利用します。

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
1.  必要な関数定義スクリプト (`.github/scripts/common/*.sh`, `.github/scripts/steps/*.sh`) を `source` します。
2.  `select_simulator` 関数を呼び出し、CI環境に適したwatchOSシミュレータIDを取得します。
3.  `build_for_testing` 関数を呼び出し、テスト用ビルドを実行します。
4.  `run_unit_tests` 関数を呼び出し、ユニットテストを実行します。実行後、`verify_unit_test_results` 関数で結果バンドルの存在を確認します（テスト成功時のみ）。
5.  `run_ui_tests` 関数を呼び出し、UIテストを実行します。実行後、`verify_ui_test_results` 関数で結果バンドルの存在を確認します（テスト成功時のみ）。
6.  生成された `.xcresult` ファイルから JUnit XML レポート (`.xml`) を生成します。
7.  生成されたテスト結果（`.xcresult`, `.xml`）を `test-results` という名前のアーティファクトとしてアップロードします。
**出力**:
- ビルド、テスト実行、結果検証ステップの成否に基づいたテスト全体の成功/失敗ステータス (`test_result`) を呼び出し元に返します。

### `build-unsigned-archive.yml`

このファイルは、署名なしのアーカイブビルドを作成する**再利用可能ワークフロー**です。

**トリガー**:
- `ci-cd-pipeline.yml` から `workflow_call` で呼び出されます。
**処理内容**:
1.  必要な関数定義スクリプト (`.github/scripts/common/*.sh`, `.github/scripts/steps/build-archive.sh`) を `source` します。
2.  `build_archive_step` 関数を呼び出し、Release設定での署名なしアーカイブビルド (`.xcarchive`) を作成します。
3.  ビルド成功後、`verify_archive_step` 関数を呼び出し、アーカイブの内容（`.app`の存在）を検証します。
4.  作成された `.xcarchive` を `unsigned-archive` という名前のアーティファクトとしてアップロードします。
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
1.  `run-tests.yml` でアップロードされた `test-results` アーティファクト（`.xcresult` と `.xml` を含む）をダウンロードします。
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
2.  SPMキャッシュを利用しつつ、Release設定でアプリをビルドし、署名なしの `.xcarchive` を作成します。（この部分は `build-unsigned-archive.yml` を再利用可能ワークフローとして呼び出す形も検討可能）
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

GitHub Actions で実行される主要なCIステップ（テスト、アーカイブ）のコアロジックをローカルで検証するためのスクリプト (`.github/scripts/run-local-validation.sh`) を用意しています。このスクリプトは、`.github/scripts/` 配下の関数定義ファイルを `source` し、コマンドライン引数に基づいて適切な関数を呼び出すことで、CIの主要な処理フローを再現します。

### ビルドを含む検証

ローカル環境でビルドからテストやアーカイブを実行し、CIワークフローで実行されるコアな処理が期待通りかを確認します。

```shell
# 全てのステップ (ビルド、単体テスト実行・検証、UIテスト実行・検証、アーカイブビルド・検証) を実行
$ ./.github/scripts/run-local-validation.sh

# テスト用ビルド + 単体テストとUIテストの両方を実行・検証
$ ./.github/scripts/run-local-validation.sh --all-tests

# テスト用ビルド + 単体テストのみを実行・検証
$ ./.github/scripts/run-local-validation.sh --unit-test

# テスト用ビルド + UIテストのみを実行・検証
$ ./.github/scripts/run-local-validation.sh --ui-test

# ビルド + アーカイブのみを実行・検証
$ ./.github/scripts/run-local-validation.sh --archive-only
```

### テストのみ実行 (ビルド成果物を再利用)

テストコードなどを修正した後、既存のビルド成果物 (`ci-outputs/test-results/DerivedData`) を再利用して、テストのみを高速に再実行・検証します。
事前に上記のコマンドで `--all-tests` や `--unit-test` などを実行してビルド成果物を作成しておく必要があります。

```shell
# 単体テストとUIテストの両方を再実行・検証
$ ./.github/scripts/run-local-validation.sh --test-without-building

# 単体テストのみを再実行・検証
$ ./.github/scripts/run-local-validation.sh --test-without-building --unit-test

# UIテストのみを再実行・検証
$ ./.github/scripts/run-local-validation.sh --test-without-building --ui-test
```

## 技術仕様

- Xcodeバージョン: 16.2
- テスト環境: watchOS シミュレータ
- 依存ツール管理: Mint (SwiftFormat, SwiftLint), Homebrew (xcbeautify), RubyGems (xcpretty)
- アーティファクト保持期間: ビルド関連 = 1日、テスト結果/アーカイブビルド = 7日
- 出力先ディレクトリ: `ci-outputs/`
  - `test-results/`: テストの結果 (`.xcresult`, `.xml`)
  - `production/`: リリース用（署名なし）のアーカイブの結果

