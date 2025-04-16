# CI/CD Workflows

このディレクトリには SilentCue アプリケーション用の GitHub Actions ワークフローファイルが含まれています。

## ファイル構成

- **`ci-cd-pipeline.yml`**: メインとなる統合CI/CDパイプラインです。Pull Request作成時やmainブランチへのプッシュ時にトリガーされ、後述の呼び出し可能なワークフロー（callable workflows）を順次実行します。
- **`callable_workflows/`**: `ci-cd-pipeline.yml` から呼び出される、再利用可能なワークフロー群が格納されています。
    - `build-and-test.yml`: アプリのビルドとテストを実行します。
    - `code-quality.yml`: コード品質チェック（SwiftFormat, SwiftLint）を実行します。
    - `test-reporter.yml`: テスト結果のレポートを作成し、PRにコメントします。
    - `pr-reviewer.yml`: PRレビューの自動化を試みます。
    - `build-for-production.yml`: 本番用（または開発用）のIPAビルドを実行します。

## 機能詳細

### `ci-cd-pipeline.yml`

このワークフローが、パイプライン全体の流れを管理します。トリガー（Push, Pull Request, 手動実行）に応じて、以下の呼び出し可能ワークフローを適切な順序と条件で実行します。

1.  `code-quality.yml` を実行し、コード品質をチェックします。
2.  `build-and-test.yml` を実行し、ビルドとテストを行います。
3.  `test-reporter.yml` を実行し、テスト結果をレポートします。
4.  Pull Requestの場合、`pr-reviewer.yml` を実行し、自動レビューを試みます。
5.  mainブランチへのPushの場合、`build-for-production.yml` を実行し、本番用ビルドを生成します。
6.  最後に、パイプライン全体の完了ステータスをPull Requestにコメントします。

### `callable_workflows/build-and-test.yml`

`ci-cd-pipeline.yml` から呼び出され、主に以下の2つのジョブを実行します:

1. **Build for Testing**: watchOSシミュレータを準備し、テスト用のアプリビルドを実行後、成果物をアップロードします。
2. **Run Tests**: ビルド成果物をダウンロードし、ユニットテストとUIテストを実行します。テスト結果とコードカバレッジレポートを生成し、アップロードします。

### `callable_workflows/code-quality.yml`

`ci-cd-pipeline.yml` から呼び出され、コード品質に関するチェックを行います:

- Mint経由でSwiftFormatとSwiftLintをインストールし、実行します。
- フォーマットやLintに違反があれば、ワークフローを失敗させます。

### `callable_workflows/test-reporter.yml`

`ci-cd-pipeline.yml` から呼び出され、`build-and-test.yml` で生成されたテスト結果ファイルを処理します:

- テスト結果のアーティファクトをダウンロードします。
- JUnit形式のレポートがあれば解析し、GitHub Checks APIを通じて結果を報告します。
- Pull Requestのコンテキストで実行された場合、テスト結果のサマリー（カバレッジ情報含む）をPRにコメントします。

### `callable_workflows/pr-reviewer.yml`

Pull Request時に `ci-cd-pipeline.yml` から呼び出され、自動コードレビューを開始します:

- レビュー開始を示すコメントをPull Requestに追加します。
- GitHub Copilotをレビュアーとして追加しようと試みます（利用可能な場合）。

### `callable_workflows/build-for-production.yml`

mainブランチへのPush時に `ci-cd-pipeline.yml` から呼び出され、本番リリース向けのビルドを実行します:

- 現在は署名なし（development）でビルドし、IPAファイルを生成します。
- App Storeリリース用の署名済みビルドとアップロード処理はコメントアウトされています（将来的に有効化可能）。
- 指定された`release_tag`（通常は実行番号から生成）を用いてGitHub Releasesにドラフトを作成し、生成されたIPAファイルを添付します。

## 使用方法

メインパイプライン (`ci-cd-pipeline.yml`) は以下のタイミングで自動実行されます:

- **プッシュ時**: `main` または `master` ブランチへのプッシュ
- **PR作成/更新時**: `main` または `master` ブランチをターゲットとするPull Request
- **手動実行**: GitHub Actionsタブから `ci-cd-pipeline.yml` を選択して実行可能

個別の呼び出し可能ワークフローは通常、直接実行するのではなく、`ci-cd-pipeline.yml` によって呼び出されます。

## 技術仕様

- 主な実行環境: macOSランナー (macos-latest または macos-14)
- Xcodeバージョン: 16.2
- テスト環境: watchOS シミュレータ
- 依存ツール管理: Mint (SwiftFormat, SwiftLint)
- アーティファクト保持期間: ビルド関連=1日、テスト結果/本番ビルド=7日
