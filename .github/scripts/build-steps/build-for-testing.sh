#!/bin/bash
# このファイルは関数定義のみを提供するため、直接実行は意図されていません。

SCRIPT_DIR_STEPS=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# 依存関係を source
source "$SCRIPT_DIR_STEPS/../common/logging.sh"
source "$SCRIPT_DIR_STEPS/../ci-env.sh"

# テスト用にアプリをビルドする関数
# ロギング関数と環境変数 (PROJECT_FILE など) が source 済みであることを想定
# 環境変数 TEST_SIMULATOR_ID を使用
build_for_testing() {
  # Check if TEST_SIMULATOR_ID is set
  if [ -z "$TEST_SIMULATOR_ID" ]; then
    fail "build_for_testing: 環境変数 TEST_SIMULATOR_ID が設定されていません。select_simulator を先に実行する必要があります。"
    return 1
  fi

  step "テスト用ビルドを開始します (シミュレータID: $TEST_SIMULATOR_ID)"
  # 古いDerivedDataを削除

  if ! set -o pipefail && xcodebuild build-for-testing \
    -project "$PROJECT_FILE" \
    -scheme "$WATCH_APP_SCHEME" \
    -destination "platform=watchOS Simulator,id=$TEST_SIMULATOR_ID" \
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