#!/bin/bash
# このファイルは関数定義のみを提供するため、直接実行は意図されていません。

SCRIPT_DIR_STEPS=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# 依存関係を source
source "$SCRIPT_DIR_STEPS/../common/logging.sh"
source "$SCRIPT_DIR_STEPS/../ci-env.sh"

# 署名なしアーカイブのビルドのみを行う関数
# 戻り値: xcodebuild の終了コード
build_archive_step() {
  step "署名なしアーカイブのビルドを開始..."

  # --- 事前クリーンアップ ---
  step "古いプロダクション出力ディレクトリを削除中..."
  if [ -d "$PRODUCTION_OUTPUT_DIR" ]; then
    rm -rf "$PRODUCTION_OUTPUT_DIR"
    success "プロダクション出力ディレクトリを削除しました: $PRODUCTION_OUTPUT_DIR"
  else
    success "プロダクション出力ディレクトリは存在しませんでした。スキップします。"
  fi
  # 必要なディレクトリを作成 (削除後に再作成)
  mkdir -p "$ARCHIVE_DIR" "$PRODUCTION_DERIVED_DATA_DIR"
  success "必要なディレクトリを作成しました。"

  # --- アーカイブビルド ---
  step "アーカイブをビルド中..."
  local archive_path="$ARCHIVE_PATH" # ci-env.sh から
  local xcodebuild_exit_code=0

  set -o pipefail && xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$WATCH_APP_SCHEME" \
    -configuration Release \
    -destination "generic/platform=watchOS" \
    -archivePath "$archive_path" \
    -derivedDataPath "$PRODUCTION_DERIVED_DATA_DIR" \
    -skipMacroValidation \
    CODE_SIGNING_ALLOWED=NO \
    archive \
    | xcpretty -c # 出力を整形

  xcodebuild_exit_code=${PIPESTATUS[0]} # xcodebuild の終了コードを取得
  set +o pipefail

  if [ $xcodebuild_exit_code -ne 0 ]; then
    echo "⚠️ アーカイブビルドがゼロ以外の終了コード ($xcodebuild_exit_code) で完了しました。" >&2
    # ここでは fail を呼ばず、終了コードを返す
  else
    success "アーカイブビルドが成功しました (終了コード: $xcodebuild_exit_code)。アーカイブパス: $archive_path"
  fi
  return $xcodebuild_exit_code
}

# アーカイブ結果を検証する関数 (Buildステップ成功時のみ実行される前提)
# 引数: なし
# 戻り値: 0 (成功) or 1 (失敗)
verify_archive_step() {
  local archive_path="$ARCHIVE_PATH" # ci-env.sh から
  local archive_app_path="$archive_path/Products/Applications/$WATCH_APP_SCHEME.app"
  step "アーカイブの内容を確認中..."

  # Buildステップが成功しているはずなので、.app が存在するか確認
  if [ ! -d "$archive_app_path" ]; then
    echo "エラー: '$WATCH_APP_SCHEME.app' が期待される場所に見つかりません ($archive_app_path)。" >&2
    echo "--- アーカイブ内容リスト (エラー時) ---" >&2
    ls -lR "$archive_path" 2>/dev/null || echo "アーカイブディレクトリが見つからないか空です。"
    fail "アーカイブ検証に失敗しました。"
    return 1 # 検証失敗
  fi

  success "アーカイブの内容を確認しました ($archive_app_path)。"
  return 0 # 検証成功
}

export -f build_archive_step verify_archive_step 