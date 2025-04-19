#!/bin/bash
# このファイルは関数定義のみを提供するため、直接実行は意図されていません。

SCRIPT_DIR_STEPS=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# 依存関係を source
source "$SCRIPT_DIR_STEPS/../common/logging.sh"
source "$SCRIPT_DIR_STEPS/../ci-env.sh"

clean_old_output() {
  step "出力ディレクトリをクリーンアップしています..."
  echo "古い $OUTPUT_DIR ディレクトリを削除中..."
  rm -rf "$OUTPUT_DIR"
  echo "ディレクトリを作成中..."
  mkdir -p "$TEST_RESULTS_DIR/unit" "$TEST_RESULTS_DIR/ui" "$TEST_DERIVED_DATA_DIR" "$ARCHIVE_DIR" "$PRODUCTION_DERIVED_DATA_DIR"

  success "ディレクトリを作成しました ($OUTPUT_DIR)。"
}

export -f clean_old_output 