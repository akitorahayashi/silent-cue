#!/bin/bash

# コマンドが失敗したらすぐに終了する
set -e

# 設定ファイルを読み込む
source "$(dirname "$0")/ci-env.sh"

# 変数はci-config.shから直接利用 (ローカル定義は削除)
SIMULATOR_NAME_PATTERN="Apple Watch" # 検索するシミュレーター名のパターン

echo "Searching for valid '$SIMULATOR_NAME_PATTERN' simulator destination for scheme '$WATCH_APP_SCHEME'..." >&2

# アプリスキームの有効な watchOS Simulator の宛先リストを取得
DESTINATIONS=$(xcodebuild -showdestinations -project "$PROJECT_FILE" -scheme "$WATCH_APP_SCHEME")

# '$SIMULATOR_NAME_PATTERN' を含む watchOS Simulator の宛先を検索
SIMULATOR_INFO=$(echo "$DESTINATIONS" | grep "platform:watchOS Simulator" | grep "name:$SIMULATOR_NAME_PATTERN" | head -1)

if [ -z "$SIMULATOR_INFO" ]; then
  echo "エラー: '$WATCH_APP_SCHEME' スキームで '$SIMULATOR_NAME_PATTERN' を含む有効な watchOS Simulator 宛先が見つかりません。" >&2
  echo "利用可能な宛先:" >&2
  echo "$DESTINATIONS" | grep "platform:watchOS Simulator" | cat >&2
  exit 1
fi

# 宛先情報から ID と名前を抽出
SIMULATOR_ID=$(echo "$SIMULATOR_INFO" | sed -nE 's/.*id:([0-9A-F-]+).*/\1/p')
SIMULATOR_NAME=$(echo "$SIMULATOR_INFO" | sed -nE 's/.*name:([^,]+).*/\1/p' | xargs)

if [ -z "$SIMULATOR_ID" ]; then
    echo "エラー: シミュレーター情報からIDを抽出できませんでした: $SIMULATOR_INFO" >&2
    exit 1
fi

echo "Found simulator: $SIMULATOR_NAME (ID: $SIMULATOR_ID)" >&2

# UIテストのスキームで宛先が存在するか検証
echo "Verifying destination for UI test scheme '$UI_TEST_SCHEME'..." >&2
DESTINATION_UI_FOUND=$(xcodebuild -showdestinations -project "$PROJECT_FILE" -scheme "$UI_TEST_SCHEME" | grep "id:$SIMULATOR_ID" || echo "not found")
if [[ "$DESTINATION_UI_FOUND" == "not found" ]]; then
    echo "エラー: 選択されたシミュレーター ID $SIMULATOR_ID ($SIMULATOR_NAME) は '$UI_TEST_SCHEME' スキームの有効な宛先ではありません。" >&2
    echo "UIテストスキームで利用可能な宛先:" >&2
    xcodebuild -showdestinations -project "$PROJECT_FILE" -scheme "$UI_TEST_SCHEME" | cat >&2
    exit 1
fi

# すべてのチェックをパスしたらIDを出力
echo "Using simulator: $SIMULATOR_NAME (ID: $SIMULATOR_ID)" >&2 # ログ情報を標準エラー出力へ
echo "$SIMULATOR_ID" # IDを標準出力へ 