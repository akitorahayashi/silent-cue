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

  step "テスト用ビルドを開始します (App Scheme, シミュレータID: $TEST_SIMULATOR_ID)"
  # 古いDerivedDataを削除 - build_for_testing 自体が上書きするので不要かもしれないが念のため
  if [ -d "$TEST_DERIVED_DATA_DIR" ]; then
      echo "古いテスト用DerivedDataを削除しています: $TEST_DERIVED_DATA_DIR"
      rm -rf "$TEST_DERIVED_DATA_DIR"
  fi
  mkdir -p "$TEST_DERIVED_DATA_DIR"

  local xcodebuild_exit_code=0
  set -o pipefail && xcodebuild build-for-testing \
    -project "$PROJECT_FILE" \
    -scheme "$WATCH_APP_SCHEME" \
    -destination "platform=watchOS Simulator,id=$TEST_SIMULATOR_ID" \
    -derivedDataPath "$TEST_DERIVED_DATA_DIR" \
    -configuration Debug \
    -skipMacroValidation \
    CODE_SIGNING_ALLOWED=NO \
    | xcpretty -c

  xcodebuild_exit_code=${PIPESTATUS[0]}
  set +o pipefail

  if [ $xcodebuild_exit_code -ne 0 ]; then
    echo "⚠️ テスト用ビルドがゼロ以外の終了コード ($xcodebuild_exit_code) で完了しました。" >&2
    # fail は呼ばず、終了コードを返す
  else
    success "テスト用ビルドが終了コード 0 で完了しました。"
  fi
  return $xcodebuild_exit_code
}

# build-for-testing の結果を検証する関数
# 引数: なし
# 戻り値: 0 (成功) or 1 (失敗)
verify_build_for_testing() {
  step "テスト用ビルドの結果を検証中..."
  local app_bundle_path="$TEST_DERIVED_DATA_DIR/Build/Products/Debug-watchsimulator/$WATCH_APP_SCHEME.app"

  if [ ! -d "$app_bundle_path" ]; then
    fail "テスト用ビルドは成功しましたが、期待されるアプリケーションバンドルが見つかりません: $app_bundle_path"
    return 1 # 検証失敗
  fi

  success "テスト用ビルドの成果物 (アプリケーションバンドル) を確認しました: $app_bundle_path"
  return 0 # 検証成功
}

export -f build_for_testing verify_build_for_testing 