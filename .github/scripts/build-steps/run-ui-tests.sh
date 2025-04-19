#!/bin/bash
# このファイルは関数定義のみを提供するため、直接実行は意図されていません。
# run_ui_tests と verify_ui_test_results 関数を定義します。

SCRIPT_DIR_STEPS=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# 依存関係を source
source "$SCRIPT_DIR_STEPS/../common/logging.sh"
source "$SCRIPT_DIR_STEPS/../ci-env.sh"

# UIテストを実行する関数
# 引数: なし (環境変数 TEST_SIMULATOR_ID を使用)
# 戻り値: xcodebuild の終了コード
run_ui_tests() {
  # Check if TEST_SIMULATOR_ID is set
  if [ -z "$TEST_SIMULATOR_ID" ]; then
    fail "run_ui_tests: 環境変数 TEST_SIMULATOR_ID が設定されていません。select_simulator を先に実行する必要があります。"
    return 1
  fi

  step "UIテストを実行しています (シミュレータID: $TEST_SIMULATOR_ID)"
  local result_path="$TEST_RESULTS_DIR/ui/TestResults.xcresult"
  rm -rf "$result_path" # 前回の結果を削除

  local xcodebuild_exit_code=0
  # set -o pipefail で xcodebuild の終了コードを取得
  set -o pipefail && xcodebuild test-without-building \
    -project "$PROJECT_FILE" \
    -scheme "$UI_TEST_SCHEME" \
    -destination "platform=watchOS Simulator,id=$TEST_SIMULATOR_ID" \
    -derivedDataPath "$TEST_DERIVED_DATA_DIR" \
    -enableCodeCoverage NO \
    -resultBundlePath "$result_path" \
  | xcbeautify --report junit --report-path ./ci-outputs/test-results/ui/junit.xml

  xcodebuild_exit_code=${PIPESTATUS[0]} # xcodebuild の終了コードを取得
  set +o pipefail

  if [ $xcodebuild_exit_code -ne 0 ]; then
    echo "⚠️ UIテストがゼロ以外の終了コード ($xcodebuild_exit_code) で完了しました。" >&2
    # ここでは fail を呼ばず、終了コードを返す
  else
    success "UIテストが成功しました (終了コード: $xcodebuild_exit_code)。"
  fi
  return $xcodebuild_exit_code
}

# UIテストの結果を検証する関数 (Runステップ成功時のみ実行される前提)
# 引数: なし
# 戻り値: 0 (成功) or 1 (失敗)
verify_ui_test_results() {
  local result_path="$TEST_RESULTS_DIR/ui/TestResults.xcresult"
  step "UIテストの結果を検証中..."

  # Runステップが成功しているはずなので、.xcresult が存在するか確認
  if [ ! -d "$result_path" ]; then
    fail "UIテストは成功しましたが、結果バンドルが見つかりません: $result_path"
    return 1 # 検証失敗
  fi

  success "UIテストの結果バンドルが見つかりました: $result_path"
  return 0 # 検証成功
}

export -f run_ui_tests verify_ui_test_results

# --- スクリプトエントリポイント --- を削除
# # 第一引数に基づいて実行する関数を決定
# COMMAND=${1:-"run"} # デフォルトは run
# shift || true # 第一引数を消費 (引数がない場合もエラーにしない)
# 
# case "$COMMAND" in
#   run)
#     run_ui_tests "$@" # 残りの引数を渡す (シミュレータID)
#     exit $? # 関数の終了コードで exit
#     ;;
#   verify)
#     verify_ui_test_results "$@" # 残りの引数を渡す (終了コード)
#     exit $? # 関数の終了コードで exit
#     ;;
#   *)
#     fail "不明なコマンド: $COMMAND 。'run' または 'verify' を指定してください。"
#     exit 1
#     ;;
# esac 