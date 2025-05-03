# CI/CD Workflows

## ファイル構成

- **`Makefile`**: ビルド、テスト、アーカイブ、コード品質チェックなど、主要なCI/CDステップのコマンドを定義・集約します。ワークフローやローカル環境から `make <ターゲット名>` 形式で呼び出されます
- **`ci-cd-pipeline.yml`**: メインとなる統合CI/CDパイプラインで、Pull Request作成時やmainブランチへのプッシュ時にトリガーされ、後述の他のワークフローを順次実行したり、一部ステップを直接実行します
- **`run-tests.yml`**: `Makefile` のテスト関連ターゲット (`make unit-test`, `make ui-test`) を呼び出し、アプリのビルドとテスト（ユニット・UI）を実行します
- **`setup-mint.yml`**: Mintをセットアップし、キャッシュします
- **`build-unsigned-archive.yml`**: `make build-unsigned-archive`を呼び出し、署名なしのアーカイブ（.xcarchive）を作成します
- **`test-reporter.yml`**: テスト結果のレポートを作成し、PRにコメントします
- **`copilot-review.yml`**: GitHub CopilotによるPRレビューを自動化します
- **`release.yml`**: vX.Y.Z 形式のタグプッシュ時にトリガーされ、アプリのビルド、署名、App Store Connectへのアップロード、GitHub Releaseの作成とIPA添付を行います

## CIの特徴

### ワークフローの分割とMakefileによる集約
メインの`ci-cd-pipeline.yml`が、テスト (`run-tests.yml`) やアーカイブビルド (`build-unsigned-archive.yml`) など、比較的複雑な処理をまとめた個別の再利用可能ワークフローを呼び出す構造になっています。
一方で、コード品質チェックのようなシンプルな処理は `ci-cd-pipeline.yml` 内で直接 `make code-quality-check` を実行します。
コアなビルド・テスト・アーカイブ処理の**コマンド自体**は `Makefile` にターゲットとして集約され、ワークフローは対応する `make <ターゲット名>` コマンドを呼び出す形になっています。

### 包括的なビルドプロセスの検証
Pull Requestや`main`ブランチへのプッシュ時に、以下の自動チェックを実行します (実処理は `make` 経由で実行):
- コードフォーマット (SwiftFormat) と静的解析 (SwiftLint) (`make code-quality-check`)
- UnitテストとUIテスト、およびそれらの結果（xcresult）の検証 (`make run-tests` または個別の `make unit-test`, `make ui-test`)
- リリース設定でのアーカイブビルドと結果の検証 (`make build-unsigned-archive`)

### Pull Request に自動でレビュー
Pull Requestに対して、テスト結果のレポート、GitHub Copilotによる自動レビューリクエスト、パイプライン全体の完了ステータス通知を行います。

### 成果物管理
- 成果物管理: ビルドやテストの成果物はGitHub Artifactsとしてアップロード・管理されます。
- 出力先を統一: 全てのビルド・テスト関連の成果物は、一貫して `ci-outputs/` ディレクトリ以下に出力されます

### リリース機能
`vX.Y.Z`形式のタグがプッシュされると、`release.yml`ワークフローが自動的にトリガーされ、以下の処理を実行します
- アプリケーションのビルドと署名
- App Store ConnectへのIPAファイルアップロード
- GitHub Releaseの作成とIPAファイルの添付

### ローカルでの検証 (Makefile推奨)
CIで実行される主要なステップは `Makefile` にターゲットとして定義されているため、ローカル環境でこれらのターゲットを実行することで、CIと同じ処理を簡単に再現・検証できます
また、従来の検証用スクリプト (`.github/scripts/run-local-ci.sh`) も `make` コマンドを内部で呼び出すラッパーとして引き続き利用可能です

## 機能詳細

### `ci-cd-pipeline.yml` (メインパイプライン)

- **トリガー**: `main`/`master`へのPush、`main`/`master`ターゲットのPR、手動実行
- **処理**:
    1.  Mint依存関係セットアップ (`setup-mint.yml`)
    2.  コード品質チェック (直接 `make code-quality-check` を実行)
    3.  ビルドとテスト実行 (`run-tests.yml` -> `make unit-test`, `make ui-test`)
    4.  テスト結果レポート (PR時, `test-reporter.yml`)
    5.  Copilotレビュー依頼 (PR時, `copilot-review.yml`)
    6.  アーカイブビルド検証 (`build-unsigned-archive.yml` -> `make build-unsigned-archive`)
    7.  パイプライン完了ステータス通知 (PR時)

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
    1.  プロジェクト生成 (`make codegen`)
    2.  Xcodeセットアップ
    3.  Unitテスト実行 (`make unit-test`)
    4.  UIテスト実行 (`make ui-test`)
    5.  テスト結果 (`.xcresult`, `.xml`) をアーティファクト としてアップロード

### `build-unsigned-archive.yml` (署名なしアーカイブ作成)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  プロジェクト生成 (`make codegen`)
    2.  Xcodeセットアップ
    3.  アーカイブビルドと検証 (`make build-unsigned-archive`)
    4.  `.xcarchive` をアーティファクト (`unsigned-archive`) としてアップロード

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
- **処理**: (変更なし、将来的には `make release-archive` 等を呼び出す形にできる可能性あり)
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

個別のワークフローは通常、直接実行するのではなく、`ci-cd-pipeline.yml` によって呼び出されます。

## ローカルでのCIプロセスの検証

CIで実行される主要なステップは `Makefile` にターゲットとして定義されています。ローカル環境でこれらのターゲットを実行することで、CI上の動作を再現・検証できます。

### Makefileターゲットの直接実行 (推奨)

ターミナルでプロジェクトルートに移動し、`make` コマンドを実行します。

```shell
# 利用可能なターゲットと説明を表示
$ make help

# コード品質チェック (SwiftLint + SwiftFormat --lint)
$ make code-quality-check

# UnitテストとUIテストを実行 (必要ならビルドも実行される)
$ make run-tests

# Unitテストのみ実行
$ make unit-test

# UIテストのみ実行
$ make ui-test

# 署名なしアーカイブを作成して検証
$ make build-unsigned-archive

# Xcodeプロジェクト生成
$ make codegen

# Mint依存関係のインストール (初回やMintfile変更時)
$ make setup-mint

# ビルド成果物や出力ディレクトリを削除
$ make clean
```
特定のシミュレータでテストを実行したい場合は、`SIMULATOR_ID` を指定できます。
```shell
$ make run-tests SIMULATOR_ID=YOUR_SIMULATOR_UDID
```

### 検証用ラッパースクリプトの利用

従来のローカル検証用スクリプト `.github/scripts/run-local-ci.sh` も引き続き利用可能です。このスクリプトは内部的に上記の `make` コマンドを呼び出すラッパーとして機能します。

初回実行前に、スクリプトに実行権限を付与してください:
```shell
$ chmod +x .github/scripts/run-local-ci.sh
```

```shell
# デフォルト: Unitテスト、UIテスト、アーカイブを実行 (make unit-test && make ui-test && make build-unsigned-archive 相当)
$ ./.github/scripts/run-local-ci.sh

# UnitテストとUIテストを実行 (make run-tests 相当)
$ ./.github/scripts/run-local-ci.sh --all-tests

# Unitテストのみを実行 (make unit-test 相当)
$ ./.github/scripts/run-local-ci.sh --unit-test

# UIテストのみを実行 (make ui-test 相当)
$ ./.github/scripts/run-local-ci.sh --ui-test

# アーカイブのみを実行 (make build-unsigned-archive 相当)
$ ./.github/scripts/run-local-ci.sh --archive-only
```
**注意:** `--test-without-building` オプションは廃止されました。`Makefile` が自動的に依存関係を解決します。

## 技術仕様

- **コマンド管理:** `Makefile`
- Xcodeバージョン: 16.2 (Makefile内で指定, 各ワークフローで `setup-xcode` アクション使用)
- テスト環境: watchOS シミュレータ (Makefile内で自動選択 or `SIMULATOR_ID` 指定)
- 依存ツール管理: Mint (SwiftFormat, SwiftLint, XCBeautify), Homebrew (mint)
- アーティファクト保持期間: 7日 (`ci-cd-pipeline.yml`, `run-tests.yml`, `build-unsigned-archive.yml` 内で設定)
- 出力先ディレクトリ: `ci-outputs/` (`Makefile` 内で定義)
  - `test-results/`: テストの結果 (`.xcresult`, `.xml`)
  - `production/archives/`: 署名なしアーカイブの結果 (.xcarchive)


