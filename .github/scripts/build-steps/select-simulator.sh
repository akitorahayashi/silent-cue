#!/bin/bash
# このファイルは関数定義のみを提供するため、直接実行は意図されていません。

# 依存関係を source
source "$(dirname "$0")/../common/logging.sh"
source "$(dirname "$0")/../ci-env.sh"

# 利用可能なシミュレータを選択し、そのIDを出力する関数
# 戻り値: 0 (成功) or 1 (失敗)
# 成功時: シミュレータIDを標準出力へ出力
select_simulator() {
  step "利用可能なシミュレータを検索・検証中..."

  local watch_scheme="$WATCH_APP_SCHEME"
  local unit_scheme="$UNIT_TEST_SCHEME"
  local ui_scheme="$UI_TEST_SCHEME"
  local schemes=("$watch_scheme" "$unit_scheme" "$ui_scheme") # 検証対象のスキーム配列
  local simulator_name_pattern="$SIMULATOR_NAME_PATTERN" # ci-env.sh から

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
  simulator_info=$(echo "$destinations" | grep "platform:watchOS Simulator" | grep "name:$simulator_name_pattern" | head -1)

  if [ -z "$simulator_info" ]; then
    fail "'$watch_scheme' スキームで '$simulator_name_pattern' を含む有効な watchOS Simulator 宛先が見つかりません。"
    echo "--- 利用可能な watchOS Simulator 宛先 (Scheme: $watch_scheme) ---" >&2
    echo "$destinations" | grep "platform:watchOS Simulator" | cat >&2
    return 1
  fi

  # IDと名前を抽出
  simulator_id=$(echo "$simulator_info" | sed -nE 's/.*id:([0-9A-F-]+).*/\1/p')
  simulator_name=$(echo "$simulator_info" | sed -nE 's/.*name:([^,]+).*/\1/p' | xargs)

  if [ -z "$simulator_id" ]; then
    fail "シミュレーター情報からIDを抽出できませんでした: $simulator_info"
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
    success "OK: Scheme '$scheme' で有効です。"
  done

  success "選択されたシミュレータはすべての必須スキームで有効です: $simulator_name (ID: $simulator_id)"
  echo "$simulator_id" # 成功した場合のみIDを標準出力へ
  return 0
}

export -f select_simulator 