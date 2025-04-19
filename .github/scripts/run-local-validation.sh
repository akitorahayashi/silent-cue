#!/bin/bash
set -euo pipefail

# --- Source Libraries and Environment --- 

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# 環境変数を読み込む
source "$SCRIPT_DIR/ci-env.sh"

# 共通関数を読み込む (logging, prerequisites)
source "$SCRIPT_DIR/common/logging.sh"
source "$SCRIPT_DIR/common/prerequisites.sh"
source "$SCRIPT_DIR/common/select-simulator.sh"

# ステップ関数を読み込む
source "$SCRIPT_DIR/build-steps/build-for-testing.sh"
source "$SCRIPT_DIR/build-steps/run-unit-tests.sh"
source "$SCRIPT_DIR/build-steps/run-ui-tests.sh"
source "$SCRIPT_DIR/build-steps/build-archive.sh"

# --- Argument Parsing --- 

# デフォルト: 全てのテストとアーカイブを実行
run_unit=true
run_ui=true
run_archive=true
skip_build_for_testing=false
selected_option="" # 排他的オプションのチェック用

# 引数解析ループ
while [[ $# -gt 0 ]]; do
  key="$1"
  # 同時に指定できないオプションの組み合わせがないかチェック
  if [[ -n "$selected_option" && "$key" == --* ]]; then
      # 例外: --test-without-building は --unit-test または --ui-test と併用可能
      if ! { [[ "$selected_option" == "--test-without-building" ]] && [[ "$key" == "--unit-test" || "$key" == "--ui-test" ]]; } && \
         ! { [[ "$key" == "--test-without-building" ]] && [[ "$selected_option" == "--unit-test" || "$selected_option" == "--ui-test" ]]; }; then
          fail "エラー: オプション $selected_option と $key は同時に指定できません。"
      fi
  fi

  case $key in
    --all-tests)        # ビルド + 全テスト実行 (アーカイブなし)
      run_unit=true; run_ui=true; run_archive=false; skip_build_for_testing=false; selected_option="$key"
      shift ;;         # 引数を消費
    --unit-test)        # ビルド + ユニットテスト実行 (またはビルドスキップ)
      run_unit=true
      if [[ "$selected_option" != "--test-without-building" ]]; then
          run_ui=false; run_archive=false; skip_build_for_testing=false; selected_option="$key"
      fi
      shift ;;         # 引数を消費
    --ui-test)          # ビルド + UIテスト実行 (またはビルドスキップ)
      run_ui=true
      if [[ "$selected_option" != "--test-without-building" ]]; then
          run_unit=false; run_archive=false; skip_build_for_testing=false; selected_option="$key"
      fi
      shift ;;         # 引数を消費
    --archive-only)     # ビルド + アーカイブ実行
      run_unit=false; run_ui=false; run_archive=true; skip_build_for_testing=false; selected_option="$key"
      shift ;;         # 引数を消費
    --test-without-building) # テストのみ実行 (ビルドスキップ)
      run_unit=true; run_ui=true; run_archive=false; skip_build_for_testing=true; selected_option="$key"
      # --unit-test/--ui-test が続く場合は run_ flags はそちらで調整される
      shift ;;         # 引数を消費
    *)                  # 不明なオプション
      fail "不明なオプション: $1"
      ;;
  esac
done

# --- Main Execution Logic --- 

main() {
  # 前提条件チェック
  check_xcpretty

  # --- シミュレータ選択 (TEST_SIMULATOR_ID を設定) ---
  # テスト実行時のみシミュレータが必要
  if $run_unit || $run_ui; then
      select_simulator # 環境変数 TEST_SIMULATOR_ID を設定
      if [ $? -ne 0 ]; then
          fail "シミュレータの選択と環境変数への設定に失敗しました。"
      fi
  fi

  # 各ステップの終了コードを保持する変数
  local build_for_testing_exit_code=0
  local build_for_testing_verify_exit_code=0
  local unit_test_run_exit_code=0
  local unit_test_verify_exit_code=0
  local ui_test_run_exit_code=0
  local ui_test_verify_exit_code=0
  local archive_build_exit_code=0
  local archive_verify_exit_code=0

  # --- ビルドステップ --- 
  if $run_unit || $run_ui; then # テスト実行にはビルドが必要
    if ! $skip_build_for_testing; then
      build_for_testing
      build_for_testing_exit_code=$?
      if [ $build_for_testing_exit_code -eq 0 ]; then
          verify_build_for_testing
          build_for_testing_verify_exit_code=$?
      else
          echo "ℹ️ テスト用ビルドが失敗したため、検証はスキップします。" >&2
      fi
    else
      step "ビルドをスキップします (--test-without-building)"
      verify_build_for_testing # ビルドスキップ時も成果物の検証は行う
      build_for_testing_verify_exit_code=$?
      if [ $build_for_testing_verify_exit_code -ne 0 ]; then
          fail "エラー: ビルドはスキップされましたが、必要なアプリケーションバンドルが見つかりません。" 
      fi
      success "既存の DerivedData とアプリケーションバンドルを使用します。"
    fi
  fi

  # --- テスト実行ステップ --- 
  # ビルドと検証が成功した場合のみテストを実行
  if [ $build_for_testing_exit_code -eq 0 ] && [ $build_for_testing_verify_exit_code -eq 0 ]; then
      # ユニットテスト実行
      if $run_unit; then
        run_unit_tests
        unit_test_run_exit_code=$?
        # 実行が成功した場合のみ検証を実行
        if [ $unit_test_run_exit_code -eq 0 ]; then
          verify_unit_test_results
          unit_test_verify_exit_code=$?
        else
          echo "ℹ️ ユニットテスト実行が失敗したため、結果検証はスキップします。" >&2
        fi
      fi
  
      # UIテスト実行
      if $run_ui; then
        run_ui_tests
        ui_test_run_exit_code=$?
        # 実行が成功した場合のみ検証を実行
        if [ $ui_test_run_exit_code -eq 0 ]; then
          verify_ui_test_results
          ui_test_verify_exit_code=$?
        else
          echo "ℹ️ UIテスト実行が失敗したため、結果検証はスキップします。" >&2
        fi
      fi
  else
      # ビルドor検証失敗時は run_unit or run_ui が true でもテストをスキップ
      if $run_unit || $run_ui; then 
          echo "ℹ️ テスト用ビルドまたはその検証に失敗したため、テスト実行はスキップします。" >&2
      fi
  fi

  # --- アーカイブステップ --- 
  if $run_archive; then
    build_archive_step
    archive_build_exit_code=$?
    # ビルドが成功した場合のみ検証を実行
    if [ $archive_build_exit_code -eq 0 ]; then
      verify_archive_step
      archive_verify_exit_code=$?
    else
      echo "ℹ️ アーカイブビルドが失敗したため、検証はスキップします。" >&2
    fi
  fi

  # --- 最終ステータスチェック --- 
  step "処理が完了しました。"

  # いずれかのステップでエラーがあれば失敗とする
  if [[ $build_for_testing_exit_code -ne 0 || $build_for_testing_verify_exit_code -ne 0 || \
        $unit_test_run_exit_code -ne 0 || $unit_test_verify_exit_code -ne 0 || \
        $ui_test_run_exit_code -ne 0 || $ui_test_verify_exit_code -ne 0 || \
        $archive_build_exit_code -ne 0 || $archive_verify_exit_code -ne 0 ]]; then
    # エラーメッセージには各ステップの終了コードを含める
    fail "一つ以上のステップで失敗しました (Build:$build_for_testing_exit_code BuildVerify:$build_for_testing_verify_exit_code UnitRun:$unit_test_run_exit_code UnitVerify:$unit_test_verify_exit_code UIRun:$ui_test_run_exit_code UIVerify:$ui_test_verify_exit_code ArchiveBuild:$archive_build_exit_code ArchiveVerify:$archive_verify_exit_code)。"
  fi

  success "すべての要求されたステップが正常に完了しました！"
}

# --- Script Entry Point --- 

# メイン関数を実行
main "$@"