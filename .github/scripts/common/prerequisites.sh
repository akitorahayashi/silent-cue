# 前提条件チェック関数

# 注意: 呼び出し元がロギング関数を source 済みであることを想定

check_xcpretty() {
  step "前提条件のチェック (xcpretty)"

  if ! command -v xcpretty &> /dev/null; then
    echo "⚠️ 警告: 'xcpretty' コマンドが見つかりません。インストールを試みます..." >&2
    if gem install xcpretty; then
      success "xcpretty が正常にインストールされました。"
    else
      # fail 関数はスクリプト/サブシェルを終了させる
      fail "xcpretty のインストールに失敗しました。手動でインストールしてください (gem install xcpretty)。"
    fi
  else
      success "xcpretty は既にインストールされています。"
  fi
  success "前提条件 (xcpretty) を満たしました。"
}

export -f check_xcpretty 