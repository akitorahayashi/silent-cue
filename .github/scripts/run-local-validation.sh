#!/bin/bash
set -euo pipefail

# --- Source Libraries and Environment --- 

# 環境変数を読み込む
source "$(dirname "$0")/ci-env.sh"

# 共通関数を読み込む (logging, prerequisites)
source "$(dirname "$0")/common/logging.sh"
source "$(dirname "$0")/common/prerequisites.sh"

# ステップ関数を読み込む
source "$(dirname "$0")/build-steps/clean-old-output.sh"
source "$(dirname "$0")/build-steps/select-simulator.sh"
source "$(dirname "$0")/build-steps/build-for-testing.sh"
source "$(dirname "$0")/build-steps/run-unit-tests.sh"
source "$(dirname "$0")/build-steps/run-ui-tests.sh"
source "$(dirname "$0")/build-steps/build-archive.sh"

# --- Argument Parsing --- 

# デフォルト値
run_unit=true
run_ui=true
run_archive=true
skip_build_for_testing=false
provided_simulator_id=""
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
    --simulator-id)     # シミュレータID指定
      if [[ -z "${2:-}" ]]; then fail "--simulator-id オプションにはシミュレータIDが必要です。"; fi
      provided_simulator_id="$2"
      shift 2 ;;       # オプションと値を消費
    *)                  # 不明なオプション
      fail "不明なオプション: $1"
      ;;
  esac
done

# --- Main Execution Logic --- 

main() {
  # 前提条件チェック（xcprettyがなければインストール試行）
  check_xcpretty

  # 出力ディレクトリ初期化
  clean_old_output

  local simulator_id=""
  local unit_test_run_exit_code=0
  local unit_test_verify_exit_code=0 # 検証ステップの終了コード用
  local ui_test_run_exit_code=0
  local ui_test_verify_exit_code=0   # 検証ステップの終了コード用

  # テストを実行する場合
  if $run_unit || $run_ui; then
    # シミュレータ選択
    if [[ -n "$provided_simulator_id" ]]; then
      simulator_id="$provided_simulator_id"
      success "指定されたシミュレータIDを使用します: $simulator_id"
    else
      # select_simulator は成功時にIDを標準出力へ出す
      simulator_id=$(select_simulator)
      if [ $? -ne 0 ]; then
        fail "シミュレータの選択に失敗しました。"
      fi
      # select_simulator内のログで成功メッセージは出るはず
    fi

    # テスト用ビルド（スキップしない場合）
    if ! $skip_build_for_testing; then
      build_for_testing "$simulator_id"
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
      run_unit_tests "$simulator_id"
      unit_test_run_exit_code=$? # 実行の終了コードを取得
      # 実行が成功した場合のみ検証を実行
      if [ $unit_test_run_exit_code -eq 0 ]; then
        verify_unit_test_results # 引数なしで呼び出す
        unit_test_verify_exit_code=$? # 検証の終了コードを取得
      else
        # 実行が失敗した場合、検証はスキップ (検証コードは 0 のまま)
        echo "ℹ️ ユニットテスト実行が失敗したため、結果検証はスキップします。"
      fi
    fi

    # UIテスト実行
    if $run_ui; then
      run_ui_tests "$simulator_id"
      ui_test_run_exit_code=$? # 実行の終了コードを取得
      # 実行が成功した場合のみ検証を実行
      if [ $ui_test_run_exit_code -eq 0 ]; then
        verify_ui_test_results # 引数なしで呼び出す
        ui_test_verify_exit_code=$? # 検証の終了コードを取得
      else
        # 実行が失敗した場合、検証はスキップ (検証コードは 0 のまま)
        echo "ℹ️ UIテスト実行が失敗したため、結果検証はスキップします。"
      fi
    fi
  fi

  # アーカイブを実行する場合
  if $run_archive; then
    # build_archive_step を呼び出し、終了コードを取得
    build_archive_step
    archive_build_exit_code=$?
    archive_verify_exit_code=0 # 検証コード初期化

    # ビルドが成功した場合のみ検証を実行
    if [ $archive_build_exit_code -eq 0 ]; then
      verify_archive_step # 引数なしで呼び出す
      archive_verify_exit_code=$? # 検証の終了コードを取得
    else
      echo "ℹ️ アーカイブビルドが失敗したため、検証はスキップします。"
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