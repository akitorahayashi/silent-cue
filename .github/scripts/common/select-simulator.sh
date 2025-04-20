#!/bin/bash
# このファイルは関数定義のみを提供するため、直接実行は意図されていません。

SCRIPT_DIR_STEPS=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# 依存関係を source
source "$SCRIPT_DIR_STEPS/../common/logging.sh"
source "$SCRIPT_DIR_STEPS/../ci-env.sh" # SIMULATOR_NAME_PATTERN を読み込む

# 利用可能なシミュレータを選択し、環境変数 TEST_SIMULATOR_ID に設定する関数
# 戻り値: 0 (成功) or 1 (失敗)
select_simulator() {
  step "watchOSシミュレータを検索・検証し、環境変数に設定しています..."

  local watch_scheme="$WATCH_APP_SCHEME"
  local unit_scheme="$UNIT_TEST_SCHEME"
  local ui_scheme="$UI_TEST_SCHEME"
  local schemes=("$watch_scheme" "$unit_scheme" "$ui_scheme") # 検証対象のスキーム配列
  local simulator_name_pattern="$SIMULATOR_NAME_PATTERN" # ci-env.sh から

  # SIMULATOR_NAME_PATTERN が空かチェック
  if [ -z "$simulator_name_pattern" ]; then
      echo "ℹ️ SIMULATOR_NAME_PATTERN が空です。利用可能な最初の watchOS Simulator を検索します。" >&2
      simulator_name_pattern="." # Match any name if pattern is empty
  fi

  local destinations
  local simulator_info
  local simulator_id
  local simulator_name

  # WATCH_APP_SCHEME で利用可能なデスティネーションを取得
  destinations=$(xcodebuild -showdestinations -project "$PROJECT_FILE" -scheme "$watch_scheme" 2>/dev/null || echo "error")
  if [[ "$destinations" == "error" ]]; then
    fail "xcodebuild -showdestinations の実行に失敗しました (Scheme: $watch_scheme)。プロジェクト設定を確認してください。"
    return 1
  fi

  # パターンに一致する watchOS Simulator を検索
  # grep で name をフィルターし、head で最初のものを取得
  simulator_info=$(echo "$destinations" | grep "platform:watchOS Simulator" | grep "name:$simulator_name_pattern" | head -1)

  if [ -z "$simulator_info" ]; then
    fail "'$watch_scheme' スキームで '$simulator_name_pattern' を含む有効な watchOS Simulator 宛先が見つかりません。"
    echo "--- 利用可能な watchOS Simulator 宛先 (Scheme: $watch_scheme) ---" >&2
    echo "$destinations" | grep "platform:watchOS Simulator" | cat >&2
    return 1
  fi

  # IDと名前を抽出 (awkを使用)
  simulator_id=$(echo "$simulator_info" | awk -F '[,:]' '{for(i=1; i<=NF; i++) if($i == " id") {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $(i+1)); print $(i+1); exit}}')
  simulator_name=$(echo "$simulator_info" | awk -F '[,:]' '{for(i=1; i<=NF; i++) if($i == " name") {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $(i+1)); print $(i+1); exit}}')

  if [ -z "$simulator_id" ] || [ -z "$simulator_name" ]; then
    fail "シミュレーター情報からIDまたは名前を抽出できませんでした: $simulator_info"
    return 1
  fi

  success "シミュレータ候補を発見: $simulator_name (ID: $simulator_id)"

  # 見つかったシミュレータIDが他の必須スキームでも有効か検証
  step "選択したシミュレータ ($simulator_name) の有効性を検証中..."
  local scheme
  for scheme in "${schemes[@]}"; do
    echo "検証中: Scheme '$scheme' で ID '$simulator_id' が利用可能か..." >&2
    local scheme_destinations
    scheme_destinations=$(xcodebuild -showdestinations -project "$PROJECT_FILE" -scheme "$scheme" 2>/dev/null | grep "id:$simulator_id" || echo "not found")
    if [[ "$scheme_destinations" == "not found" ]]; then
      fail "エラー: 選択されたシミュレータ ID $simulator_id ($simulator_name) は '$scheme' スキームの有効な宛先ではありません。"
      echo "--- 利用可能な宛先 (Scheme: $scheme) ---" >&2
      xcodebuild -showdestinations -project "$PROJECT_FILE" -scheme "$scheme" 2>/dev/null | cat >&2
      return 1
    fi
    success "OK: Scheme '$scheme' で有効です。" >&2
  done

  success "選択されたシミュレータはすべての必須スキームで有効です: $simulator_name (ID: $simulator_id)" >&2

  # 見つけたIDを既存の環境変数に代入
  TEST_SIMULATOR_ID="$simulator_id"
  return 0
}

export -f select_simulator 