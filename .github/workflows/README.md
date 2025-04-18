# CI/CD Workflows

このディレクトリには SilentCue アプリケーション用の GitHub Actions ワークフローファイルが含まれています。

## ファイル構成

- **`ci-cd-pipeline.yml`**: メインとなる統合CI/CDパイプラインです。Pull Request作成時やmainブランチへのプッシュ時にトリガーされ、後述の他のワークフローを順次実行します。
- **`run-tests.yml`**: アプリのビルドとテストを実行します。
- **`code-quality.yml`**: コード品質チェック（SwiftFormat, SwiftLint）を実行します。
- **`test-reporter.yml`**: テスト結果のレポートを作成し、PRにコメントします。
- **`copilot-review.yml`**: GitHub CopilotによるPRレビューを自動化します。
- **`build-for-production.yml`**: 本番用（または開発用）のIPAビルドを実行します。

## 機能詳細

### `ci-cd-pipeline.yml`

このワークフローが、パイプライン全体の流れを管理します。トリガー（Push, Pull Request, 手動実行）に応じて、以下のワークフローを適切な順序と条件で実行します。

1.  `code-quality.yml` を実行し、コード品質をチェックします。
2.  `run-tests.yml` を実行し、ビルドとテストを行います。
3.  `test-reporter.yml` を実行し、テスト結果をレポートします。
4.  Pull Requestの場合、`copilot-review.yml` を実行し、GitHub Copilotによる自動レビューを実施します。
5.  mainブランチへのPushの場合、`build-for-production.yml` を実行し、本番用ビルドを生成します。
6.  最後に、パイプライン全体の完了ステータスをPull Requestにコメントします。

### `run-tests.yml`

`ci-cd-pipeline.yml` から呼び出され、主に以下の3つのステップを実行します:

1. **Build for Testing**: 
   - watchOSシミュレータを準備し、テスト用のアプリビルドを実行します
   - ビルド成果物のデバッグ用に `xcbuild` ディレクトリの内容を出力します

2. **Run Unit Tests**: 
   - ユニットテストを実行します
   - テスト結果は `test-results/unit/` ディレクトリに保存されます

3. **Run UI Tests**: 
   - UIテストを実行します
   - テスト結果は `test-results/ui/` ディレクトリに保存されます

テスト結果とコードカバレッジレポートを生成し、アップロードします。処理のステータスは環境変数として記録され、パイプラインの後続プロセスで使用されます。

### `code-quality.yml`

`ci-cd-pipeline.yml` から呼び出され、コード品質に関するチェックを行います:

- Mint経由でSwiftFormatとSwiftLintをインストールし、実行します。
- フォーマットやLintに違反があれば、ワークフローを失敗させます。
- 問題が検出された場合、「コードフォーマットの問題が見つかりました」と日本語で通知します。

### `test-reporter.yml`

`ci-cd-pipeline.yml` から呼び出され、`run-tests.yml` で生成されたテスト結果ファイルを処理します:

- テスト結果のアーティファクトをダウンロードします。
- デバッグ用にダウンロードしたファイルの一覧を表示します。
- JUnit形式のレポートがあれば解析し、GitHub Checks APIを通じて結果を報告します。
- Pull Requestのコンテキストで実行された場合、テスト結果のサマリーをPRにコメントします。

### `copilot-review.yml`

Pull Request時に `ci-cd-pipeline.yml` から呼び出され、GitHub Copilotによる自動コードレビューを実行します:

- GitHub Copilotをレビュアーとして追加し、PRの自動レビューを依頼します。
- レビュアー追加に失敗した場合、リポジトリの設定でGitHub Copilotコードレビュー機能が有効になっているか確認を促す日本語のコメントをPRに追加します。
- GitHub Copilotによるレビューは、コードの品質向上や潜在的な問題の早期発見に役立ちます。

### `build-for-production.yml`

mainブランチへのPush時に `ci-cd-pipeline.yml` から呼び出され、本番リリース向けのビルドを実行します:

- 現在は署名なし（development）でビルドし、IPAファイルを生成します。
- App Storeリリース用の署名済みビルドとアップロード処理はコメントアウトされています（将来的に有効化可能）。
- 指定された`release_tag`（通常は実行番号から生成）を用いてGitHub Releasesにドラフトを作成し、生成されたIPAファイルを添付します。

## 使用方法

メインパイプライン (`ci-cd-pipeline.yml`) は以下のタイミングで自動実行されます:

- **プッシュ時**: `main` または `master` ブランチへのプッシュ
- **PR作成/更新時**: `main` または `master` ブランチをターゲットとするPull Request
- **手動実行**: GitHub Actionsタブから `ci-cd-pipeline.yml` を選択して実行可能

個別のワークフローは通常、直接実行するのではなく、`ci-cd-pipeline.yml` によって呼び出されます。

## トラブルシューティング

ビルドやテストに問題が発生した場合、以下の点を確認してください：

- **ビルド成果物の確認**: `run-tests.yml` のログで `xcbuild` ディレクトリの内容を確認し、`.app` ファイルが正しく生成されているか確認できます
- **テスト実行エラー**: テスト実行中に `.app` ファイルが見つからないエラーが発生する場合、`-derivedDataPath` の指定が適切か確認してください
- **コードカバレッジエラー**: カバレッジ関連のエラーが発生する場合は、`-enableCodeCoverage NO` オプションが正しく設定されているか確認してください

## 技術仕様

- 主な実行環境: macOSランナー (macos-latest または macos-14)
- Xcodeバージョン: 16.2
- テスト環境: watchOS シミュレータ
- 依存ツール管理: Mint (SwiftFormat, SwiftLint)
- アーティファクト保持期間: ビルド関連 = 1日、テスト結果/本番ビルド = 7日
