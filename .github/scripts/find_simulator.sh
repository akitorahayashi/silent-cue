#!/bin/bash

# コマンドが失敗したらすぐに終了する
set -e

# 利用可能な最初の 'Apple Watch Series' シミュレーターを見つける
SIMULATOR_INFO=$(xcrun simctl list devices available | grep 'Apple Watch Series' | head -1)

if [ -z "$SIMULATOR_INFO" ]; then
  echo "エラー: 'Apple Watch Series' シミュレーターが見つかりません。" >&2
  exit 1
fi

SIMULATOR_ID=$(echo "$SIMULATOR_INFO" | grep -oE '[0-9A-F\-]{36}')
SIMULATOR_NAME=$(echo "$SIMULATOR_INFO" | sed -E 's/^[[:space:]]*([^(]+).*$/\1/' | xargs)

if [ -z "$SIMULATOR_ID" ]; then
    echo "エラー: シミュレーター情報からIDを抽出できませんでした: $SIMULATOR_INFO" >&2
    exit 1
fi

# メインアプリのスキームで宛先が存在するか検証
DESTINATION_APP_FOUND=$(xcodebuild -showdestinations -project "SilentCue.xcodeproj" -scheme "SilentCue Watch App" | grep "id:$SIMULATOR_ID" || echo "not found")
if [[ "$DESTINATION_APP_FOUND" == "not found" ]]; then
    echo "エラー: 選択されたシミュレーター ID $SIMULATOR_ID ($SIMULATOR_NAME) は 'SilentCue Watch App' スキームの有効な宛先ではありません。" >&2
    echo "アプリスキームで利用可能な宛先:" >&2
    xcodebuild -showdestinations -project "SilentCue.xcodeproj" -scheme "SilentCue Watch App" | cat >&2
    exit 1
fi

# UIテストのスキームで宛先が存在するか検証
DESTINATION_UI_FOUND=$(xcodebuild -showdestinations -project "SilentCue.xcodeproj" -scheme "SilentCue Watch AppUITests" | grep "id:$SIMULATOR_ID" || echo "not found")
if [[ "$DESTINATION_UI_FOUND" == "not found" ]]; then
    echo "エラー: 選択されたシミュレーター ID $SIMULATOR_ID ($SIMULATOR_NAME) は 'SilentCue Watch AppUITests' スキームの有効な宛先ではありません。" >&2
    echo "UIテストスキームで利用可能な宛先:" >&2
    xcodebuild -showdestinations -project "SilentCue.xcodeproj" -scheme "SilentCue Watch AppUITests" | cat >&2
    exit 1
fi

# すべてのチェックをパスしたらIDを出力
echo "使用するシミュレーター: $SIMULATOR_NAME (ID: $SIMULATOR_ID)" >&2 # ログ情報を標準エラー出力へ
echo "$SIMULATOR_ID" # IDを標準出力へ 