#!/bin/bash
set -euo pipefail

# --- Source Libraries and Environment --- 

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# 環境変数を読み込む
source "$SCRIPT_DIR/ci-env.sh"

# 共通関数を読み込む (logging, prerequisites)
source "$SCRIPT_DIR/common/logging.sh"
source "$SCRIPT_DIR/common/prerequisites.sh"

# ステップ関数を読み込む
source "$SCRIPT_DIR/build-steps/select-simulator.sh"
source "$SCRIPT_DIR/build-steps/build-for-testing.sh"
source "$SCRIPT_DIR/build-steps/run-unit-tests.sh"
source "$SCRIPT_DIR/build-steps/run-ui-tests.sh"
source "$SCRIPT_DIR/build-steps/build-archive.sh"

# --- Argument Parsing --- 

# デフォルト値
run_unit=true
run_ui=true
run_archive=true
skip_build_for_testing=false
# provided_simulator_id="" # Removed
selected_option="" # オプションの組み合わせチェック用

# 引数解析ループ
while [[ $# -gt 0 ]]; do
  key="$1"
  # 相互排他的なオプションのチェック（以前と同様）
  if [[ -n "$selected_option" && "$key" == --* ]]; then
      if ! ( [[ "$selected_option" == "--test-without-building" ]] && [[ "$key" == "--unit-test" || "$key" == "--ui-test" ]] ) && \
         ! ( [[ "$key" == "--test-without-building" ]] && [[ "$selected_option" == "--unit-test" || "$selected_option" == "--ui-test" ]] ); then
        fail "エラー: オプション $selected_option と $key は同時に指定できません。"
      fi
  fi

  case $key in
    --all-tests)        # テストのみ実行（ビルド含む）
      run_unit=true; run_ui=true; run_archive=false; skip_build_for_testing=false; selected_option="$key"
      shift ;;         # 引数を消費
    --unit-test)        # ユニットテストのみ実行（ビルド含む or なし）
      run_unit=true
      if [[ "$selected_option" != "--test-without-building" ]]; then
          run_ui=false; run_archive=false; skip_build_for_testing=false; selected_option="$key"
      fi
      shift ;;         # 引数を消費
    --ui-test)          # UIテストのみ実行（ビルド含む or なし）
      run_ui=true
      if [[ "$selected_option" != "--test-without-building" ]]; then
          run_unit=false; run_archive=false; skip_build_for_testing=false; selected_option="$key"
      fi
      shift ;;         # 引数を消費
    --archive-only)     # アーカイブのみ実行
      run_unit=false; run_ui=false; run_archive=true; skip_build_for_testing=false; selected_option="$key"
      shift ;;         # 引数を消費
    --test-without-building) # テストのみ実行（ビルドスキップ）
      run_unit=true; run_ui=true; run_archive=false; skip_build_for_testing=true; selected_option="$key"
      # --unit-test/--ui-test が後続すれば run_flags はそちらで調整される
      shift ;;         # 引数を消費
    # --simulator-id)     # Removed
    #   if [[ -z "${2:-}" ]]; then fail "--simulator-id オプションにはシミュレータIDが必要です。"; fi
    #   provided_simulator_id="$2"
    #   shift 2 ;;       # オプションと値を消費
    *)                  # 不明なオプション
      fail "不明なオプション: $1"
      ;;
  esac
done

# --- Main Execution Logic --- 

main() {
  # 前提条件チェック（xcprettyがなければインストール試行）
  check_xcpretty

  # --- シミュレータ選択 (環境変数を設定) ---
  # テストまたはアーカイブを実行する場合にのみシミュレータ選択が必要
  # build_archive_step は destination 不要なのでテスト実行時のみ選択
  if $run_unit || $run_ui; then
      select_simulator # TEST_SIMULATOR_ID を設定するために実行
      if [ $? -ne 0 ]; then
          fail "シミュレータの選択と環境変数への設定に失敗しました。"
      fi
  fi

  # local simulator_id="" # Removed
  local unit_test_run_exit_code=0
  local unit_test_verify_exit_code=0 # 検証ステップの終了コード用
  local ui_test_run_exit_code=0
  local ui_test_verify_exit_code=0   # 検証ステップの終了コード用
  local archive_build_exit_code=0    # Initialize archive codes
  local archive_verify_exit_code=0

  # テストを実行する場合 (シミュレータIDは環境変数から取得される)
  if $run_unit || $run_ui; then

    # テスト用ビルド（スキップしない場合）
    if ! $skip_build_for_testing; then
      build_for_testing # 引数なしで呼び出す
    else
      step "ビルドをスキップします (--test-without-building)"
      # ビルドスキップ時もDerivedDataの存在をチェックする方が親切かもしれない
      if [ ! -d "$TEST_DERIVED_DATA_DIR" ]; then
          fail "エラー: DerivedData ディレクトリが見つかりません ($TEST_DERIVED_DATA_DIR)。--test-without-building を使用するには、事前にビルドが必要です。"
      fi
      success "既存の DerivedData を使用します: $TEST_DERIVED_DATA_DIR"
    fi

    # ユニットテスト実行
    if $run_unit; then
      run_unit_tests # 引数なしで呼び出す
      unit_test_run_exit_code=$? # 実行の終了コードを取得
      # 実行が成功した場合のみ検証を実行
      if [ $unit_test_run_exit_code -eq 0 ]; then
        verify_unit_test_results # 引数なしで呼び出す
        unit_test_verify_exit_code=$? # 検証の終了コードを取得
      else
        # 実行が失敗した場合、検証はスキップ (検証コードは 0 のまま)
        echo "ℹ️ ユニットテスト実行が失敗したため、結果検証はスキップします。" >&2
      fi
    fi

    # UIテスト実行
    if $run_ui; then
      run_ui_tests # 引数なしで呼び出す
      ui_test_run_exit_code=$? # 実行の終了コードを取得
      # 実行が成功した場合のみ検証を実行
      if [ $ui_test_run_exit_code -eq 0 ]; then
        verify_ui_test_results # 引数なしで呼び出す
        ui_test_verify_exit_code=$? # 検証の終了コードを取得
      else
        # 実行が失敗した場合、検証はスキップ (検証コードは 0 のまま)
        echo "ℹ️ UIテスト実行が失敗したため、結果検証はスキップします。" >&2
      fi
    fi
  fi

  # アーカイブを実行する場合
  if $run_archive; then
    # build_archive_step を呼び出し、終了コードを取得
    build_archive_step # 引数なしで呼び出す
    archive_build_exit_code=$?
    
    # ビルドが成功した場合のみ検証を実行
    if [ $archive_build_exit_code -eq 0 ]; then
      verify_archive_step # 引数なしで呼び出す
      archive_verify_exit_code=$? # 検証の終了コードを取得
    else
      echo "ℹ️ アーカイブビルドが失敗したため、検証はスキップします。" >&2
    fi
  fi

  # 最終的なステータス表示
  step "処理が完了しました。"

  # テスト実行、検証、またはアーカイブ実行、検証が失敗した場合にエラー終了
  if [[ $unit_test_run_exit_code -ne 0 || $unit_test_verify_exit_code -ne 0 || \
        $ui_test_run_exit_code -ne 0 || $ui_test_verify_exit_code -ne 0 || \
        $archive_build_exit_code -ne 0 || $archive_verify_exit_code -ne 0 ]]; then
    fail "テストまたはアーカイブの実行/検証が失敗しました (UnitRun:$unit_test_run_exit_code UnitVerify:$unit_test_verify_exit_code UIRun:$ui_test_run_exit_code UIVerify:$ui_test_verify_exit_code ArchiveBuild:$archive_build_exit_code ArchiveVerify:$archive_verify_exit_code)。"
  fi

  success "すべての要求されたステップが正常に完了しました！"
}

# --- Script Entry Point --- 

# メイン関数を実行（スクリプト引数を渡す）
main "$@"