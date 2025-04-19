#!/bin/bash
# このファイルは関数定義のみを提供するため、直接実行は意図されていません。

# 依存関係を source
source "$(dirname "$0")/../common/logging.sh"
source "$(dirname "$0")/../ci-env.sh"

# テスト用にアプリをビルドする関数
# ロギング関数と環境変数 (PROJECT_FILE など) が source 済みであることを想定
# 最初の引数 ($1) としてシミュレータIDを受け取る

build_for_testing() {
  if [ -z "${1:-}" ]; then fail "build_for_testing: シミュレータIDが必要です。"; fi
  local SIMULATOR_ID="$1"
  step "テスト用にビルド中 (シミュレータID: $SIMULATOR_ID)"

  if ! set -o pipefail && xcodebuild build-for-testing \
    -project "$PROJECT_FILE" \
    -scheme "$WATCH_APP_SCHEME" \
    -destination "platform=watchOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath "$TEST_DERIVED_DATA_DIR" \
    -configuration Debug \
    -skipMacroValidation \
    CODE_SIGNING_ALLOWED=NO \
    | xcpretty -c; then
    fail "テスト用ビルドに失敗しました。ログを確認してください。"
  fi

  success "テスト用ビルドが完了しました。"
  return 0
}

export -f build_for_testing 