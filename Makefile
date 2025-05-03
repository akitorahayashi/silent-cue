# Makefile for SilentCue CI/CD

# Variables
SHELL := /bin/bash
PROJECT := SilentCue.xcodeproj
SCHEME_WATCH_APP := "SilentCue Watch App"
SCHEME_UNIT_TESTS := "SilentCue Watch AppTests"
SCHEME_UI_TESTS := "SilentCue Watch AppUITests"
CONFIGURATION_DEBUG := Debug
CONFIGURATION_RELEASE := Release
DESTINATION_GENERIC_WATCHOS := "generic/platform=watchOS"

# Output directories (relative to project root)
OUTPUT_DIR := ci-outputs
DERIVED_DATA_PATH := $(OUTPUT_DIR)/test-results/DerivedData
UNIT_TEST_RESULTS_DIR := $(OUTPUT_DIR)/test-results/unit
UI_TEST_RESULTS_DIR := $(OUTPUT_DIR)/test-results/ui
ARCHIVE_OUTPUT_DIR := $(OUTPUT_DIR)/production/archives
ARCHIVE_PATH := $(ARCHIVE_OUTPUT_DIR)/SilentCue.xcarchive

# Tools
XCODEBUILD := xcrun xcodebuild
XCBEAUTIFY := xcrun xcbeautify
MINT := mint

# シミュレータID検索コマンド
FIND_SIM_CMD := \
	set -o pipefail; \
	SIM_INFO=$$($$(XCODEBUILD) -showdestinations -project "$(PROJECT)" -scheme $(SCHEME_WATCH_APP) 2>/dev/null | grep 'platform:watchOS Simulator' | grep 'name:Apple Watch' | head -n 1); \
	if [ -z "$$SIM_INFO" ]; then \
		echo "エラー: スキーム $(SCHEME_WATCH_APP) に適した 'Apple Watch' シミュレータが見つかりません。" >&2; \
		exit 1; \
	fi; \
	SIM_ID=$$($$(echo "$$SIM_INFO" | sed -nE 's/.*id:([0-9A-F-]+).*/\1/p')); \
	if [ -z "$$SIM_ID" ]; then \
		echo "エラー: シミュレータIDを抽出できませんでした: $$SIM_INFO" >&2; \
		exit 1; \
	fi; \
	# UIテストスキームでの有効性を検証
	if ! $$(XCODEBUILD) -showdestinations -project "$(PROJECT)" -scheme $(SCHEME_UI_TESTS) 2>/dev/null | grep -q "id:$$SIM_ID"; then \
		echo "エラー: シミュレータID $$SIM_ID はUIテストスキーム $(SCHEME_UI_TESTS) で有効ではありません。" >&2; \
		exit 1; \
	fi; \
	echo $$SIM_ID

_SIMULATOR_ID :=

define find_simulator_id_once
  $(if $(_SIMULATOR_ID),, \
    $(eval _SIMULATOR_ID := $(shell $(FIND_SIM_CMD))))
endef

.PHONY: ensure-simulator-id
ensure-simulator-id:
	$(call find_simulator_id_once)
	$(if $(_SIMULATOR_ID), \
	    @echo "シミュレータIDを使用: $(_SIMULATOR_ID)", \
	    $(error シミュレータIDが見つかりませんでした。FIND_SIM_CMD出力: $(shell $(FIND_SIM_CMD) 2>&1)))

DESTINATION_SIMULATOR = "platform=watchOS Simulator,id=$(_SIMULATOR_ID)"

.PHONY: all setup-mint codegen build-for-testing unit-test ui-test run-tests build-unsigned-archive verify-archive lint format-check code-quality-check clean clean-derived-data help release-archive setup-signing export-ipa validate-ipa upload-ipa github-release release clean-release

help: ## ヘルプメッセージを表示
	@echo "使用法: make [ターゲット]"
	@echo ""
	@echo "ターゲット:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

all: code-quality-check run-tests build-unsigned-archive ## 品質チェック、テスト、アーカイブを実行

# === セットアップ ===
setup-mint: ## Mintをインストールし、依存関係をブートストラップ
	brew install mint
	$(MINT) bootstrap

codegen:
	$(MINT) run xcodegen generate

# === ビルドとテスト ===

$(DERIVED_DATA_PATH):
	mkdir -p $(DERIVED_DATA_PATH)

build-for-testing: $(DERIVED_DATA_PATH) ensure-simulator-id ## シミュレータでのテスト用にアプリをビルド
	@echo ">>> テスト用にビルド中 (シミュレータID: $(_SIMULATOR_ID))"
	set -o pipefail && $(XCODEBUILD) build-for-testing \
		-project "$(PROJECT)" \
		-scheme $(SCHEME_WATCH_APP) \
		-destination $(DESTINATION_SIMULATOR) \
		-derivedDataPath "$(DERIVED_DATA_PATH)" \
		-configuration $(CONFIGURATION_DEBUG) \
		-skipMacroValidation \
		CODE_SIGNING_ALLOWED=NO \
	| $(XCBEAUTIFY)

$(UNIT_TEST_RESULTS_DIR):
	mkdir -p $(UNIT_TEST_RESULTS_DIR)

unit-test: build-for-testing ensure-simulator-id ## Unitテストを実行
	@echo ">>> Unitテストを実行中 (シミュレータID: $(_SIMULATOR_ID))"
	set -o pipefail && $(XCODEBUILD) test-without-building \
		-project "$(PROJECT)" \
		-scheme $(SCHEME_UNIT_TESTS) \
		-destination $(DESTINATION_SIMULATOR) \
		-derivedDataPath "$(DERIVED_DATA_PATH)" \
		-enableCodeCoverage NO \
		-resultBundlePath "$(UNIT_TEST_RESULTS_DIR)/TestResults.xcresult" \
	| $(XCBEAUTIFY) --report junit --report-path "$(UNIT_TEST_RESULTS_DIR)/junit.xml"
	@echo "Unitテスト結果バンドルを確認中..."
	@if [ ! -d "$(UNIT_TEST_RESULTS_DIR)/TestResults.xcresult" ]; then \
		echo "❌ エラー: Unitテスト結果バンドルが $(UNIT_TEST_RESULTS_DIR)/TestResults.xcresult に見つかりません"; \
		exit 1; \
	fi
	@echo "✅ Unitテスト結果バンドルが見つかりました。"

$(UI_TEST_RESULTS_DIR):
	mkdir -p $(UI_TEST_RESULTS_DIR)

ui-test: build-for-testing ensure-simulator-id ## UIテストを実行
	@echo ">>> UIテストを実行中 (シミュレータID: $(_SIMULATOR_ID))"
	set -o pipefail && $(XCODEBUILD) test-without-building \
		-project "$(PROJECT)" \
		-scheme $(SCHEME_UI_TESTS) \
		-destination $(DESTINATION_SIMULATOR) \
		-derivedDataPath "$(DERIVED_DATA_PATH)" \
		-enableCodeCoverage NO \
		-resultBundlePath "$(UI_TEST_RESULTS_DIR)/TestResults.xcresult" \
	| $(XCBEAUTIFY) --report junit --report-path "$(UI_TEST_RESULTS_DIR)/junit.xml"
	@echo "UIテスト結果バンドルを確認中..."
	@if [ ! -d "$(UI_TEST_RESULTS_DIR)/TestResults.xcresult" ]; then \
		echo "❌ エラー: UIテスト結果バンドルが $(UI_TEST_RESULTS_DIR)/TestResults.xcresult に見つかりません"; \
		exit 1; \
	fi
	@echo "✅ UIテスト結果バンドルが見つかりました。"


run-tests: unit-test ui-test ## 全てのテストを実行 (Unit と UI)

# === アーカイブ ===

$(ARCHIVE_OUTPUT_DIR):
	mkdir -p $(ARCHIVE_OUTPUT_DIR)

build-unsigned-archive: $(ARCHIVE_OUTPUT_DIR) ## 署名なしのリリースアーカイブをビルド (ci-outputs/production/archives)
	@echo ">>> 署名なしリリースアーカイブをビルド中"
	set -o pipefail && $(XCODEBUILD) archive \
		-project "$(PROJECT)" \
		-scheme $(SCHEME_WATCH_APP) \
		-configuration $(CONFIGURATION_RELEASE) \
		-destination $(DESTINATION_GENERIC_WATCHOS) \
		-archivePath "$(ARCHIVE_PATH)" \
		-derivedDataPath "$(ARCHIVE_OUTPUT_DIR)/DerivedData" \
		-skipMacroValidation \
		CODE_SIGNING_ALLOWED=NO \
	| $(XCBEAUTIFY)
	$(MAKE) verify-archive

verify-archive: ## 署名なしアーカイブの内容を検証
	@echo ">>> アーカイブ内容を検証中"
	@EXPECTED_APP_NAME="$(SCHEME_WATCH_APP).app"; \
	EXPECTED_APP_PATH="$(ARCHIVE_PATH)/Products/Applications/$$EXPECTED_APP_NAME"; \
	echo "パスを確認中: '$$EXPECTED_APP_PATH'"; \
	if [ ! -d "$$EXPECTED_APP_PATH" ]; then \
		echo "❌ エラー: '$$EXPECTED_APP_NAME' が期待されるアーカイブ場所 ('$$EXPECTED_APP_PATH') に見つかりません。"; \
		echo "--- アーカイブ内容（エラー時） ---"; \
		ls -lR "$(ARCHIVE_PATH)" || echo "アーカイブディレクトリが見つからないか空です。"; \
		exit 1; \
	fi
	@echo "✅ アーカイブ内容が検証されました。"

# === コード品質 ===
lint: ## SwiftLintを実行
	@echo ">>> SwiftLintを実行中"
	$(MINT) run swiftlint --strict

format-check: ## SwiftFormatでフォーマットをチェック
	@echo ">>> SwiftFormatでフォーマットを確認中"
	$(MINT) run swiftformat --lint .
	@echo "フォーマット変更を確認中..."
	@if ! git diff --quiet; then \
		echo "❌ エラー: SwiftFormatがフォーマット違反を発見しました。ローカルで 'make format' を実行してください。"; \
		git diff; \
		exit 1; \
	fi
	@echo "✅ コードフォーマットは正しいです。"

format: ## SwiftFormatでフォーマットを適用
	@echo ">>> SwiftFormatでフォーマットを適用中"
	$(MINT) run swiftformat .

code-quality-check: lint format-check ## 全てのコード品質チェックを実行 (lint と format-check)

# === クリーンアップ ===
clean-derived-data: ## DerivedDataディレクトリを削除
	@echo ">>> Derived Data をクリーンアップ中"
	rm -rf "$(DERIVED_DATA_PATH)"
	rm -rf "$(ARCHIVE_OUTPUT_DIR)/DerivedData"

clean: clean-derived-data clean-release ## 全てのビルド成果物と出力ディレクトリを削除
	@echo ">>> 全ての出力をクリーンアップ中"
	rm -rf "$(OUTPUT_DIR)"

# === リリースターゲット ===

RELEASE_ARCHIVE_DIR := build
RELEASE_ARCHIVE_PATH := $(RELEASE_ARCHIVE_DIR)/SilentCue.xcarchive
RELEASE_DERIVED_DATA_PATH := $(RELEASE_ARCHIVE_DIR)/DerivedData
EXPORT_DIR := ./ipa_export
EXPORT_OPTIONS_PLIST := ./ExportOptions.plist

$(RELEASE_ARCHIVE_DIR):
	mkdir -p $(RELEASE_ARCHIVE_DIR) $(RELEASE_DERIVED_DATA_PATH)

release-archive: $(RELEASE_ARCHIVE_DIR) ## リリース用の署名なしアーカイブをビルド (出力先: ./build)
	@echo ">>> 署名なしリリースアーカイブをビルド中 (出力先: $(RELEASE_ARCHIVE_PATH))"
	set -o pipefail && $(XCODEBUILD) archive \
		-project "$(PROJECT)" \
		-scheme $(SCHEME_WATCH_APP) \
		-configuration $(CONFIGURATION_RELEASE) \
		-destination $(DESTINATION_GENERIC_WATCHOS) \
		-archivePath "$(RELEASE_ARCHIVE_PATH)" \
		-derivedDataPath "$(RELEASE_DERIVED_DATA_PATH)" \
		-skipMacroValidation \
		CODE_SIGNING_ALLOWED=NO \
	| $(XCBEAUTIFY)
	@echo ">>> リリースアーカイブ内容を検証中"
	@EXPECTED_APP_NAME="$(SCHEME_WATCH_APP).app"; \
	EXPECTED_APP_PATH="$(RELEASE_ARCHIVE_PATH)/Products/Applications/$$EXPECTED_APP_NAME"; \
	echo "パスを確認中: '$$EXPECTED_APP_PATH'"; \
	if [ ! -d "$$EXPECTED_APP_PATH" ]; then \
		echo "❌ エラー: '$$EXPECTED_APP_NAME' が期待されるリリースアーカイブ場所 ('$$EXPECTED_APP_PATH') に見つかりません。"; \
		ls -lR "$(RELEASE_ARCHIVE_PATH)" || echo "リリースアーカイブディレクトリが見つからないか空です。"; \
		exit 1; \
	fi
	@echo "✅ リリースアーカイブ内容が検証されました。"

$(EXPORT_DIR):
	mkdir -p $(EXPORT_DIR)

export-ipa: release-archive $(EXPORT_DIR) ## 署名済みIPAをエクスポート
	@echo ">>> 署名済みIPAをエクスポート中 (アーカイブ: $(RELEASE_ARCHIVE_PATH))"
	@if [ ! -f "$(EXPORT_OPTIONS_PLIST)" ]; then \
		echo "❌ エラー: ExportOptions.plistが $(EXPORT_OPTIONS_PLIST) に見つかりません。先に生成してください。"; \
		exit 1; \
	fi
	$(XCODEBUILD) -exportArchive \
		-archivePath "$(RELEASE_ARCHIVE_PATH)" \
		-exportPath "$(EXPORT_DIR)" \
		-exportOptionsPlist "$(EXPORT_OPTIONS_PLIST)" \
		-allowProvisioningUpdates
	@echo "✅ IPAが $$RELEASE_IPA_PATH に正常にエクスポートされました。"

validate-ipa: export-ipa ## IPAをApp Store Connectで検証
	@echo ">>> App Store ConnectでIPAを検証中"
	@RELEASE_IPA_PATH=$$(find $(EXPORT_DIR) -name "*.ipa" -print -quit); \
	if [ -z "$$RELEASE_IPA_PATH" ]; then echo "❌ エラー: 検証するIPAが $(EXPORT_DIR) に見つかりません。"; exit 1; fi; \
	if [ -z "$$APP_STORE_CONNECT_API_KEY_ID" ] || [ -z "$$APP_STORE_CONNECT_ISSUER_ID" ] || [ -z "$$APP_STORE_CONNECT_API_PRIVATE_KEY" ]; then \
		echo "❌ エラー: App Store Connect APIシークレット (ID, Issuer, Key) が環境変数として設定されている必要があります。"; \
		exit 1; \
	fi
	xcrun altool --validate-app -f "$$RELEASE_IPA_PATH" --type watchos \
		--apiKey "$$APP_STORE_CONNECT_API_KEY_ID" \
		--apiIssuer "$$APP_STORE_CONNECT_ISSUER_ID" \
		--apiPrivateKey <(echo "$$APP_STORE_CONNECT_API_PRIVATE_KEY")
	@echo "✅ IPA検証コマンドが実行されました。"

upload-ipa: validate-ipa ## IPAをApp Store Connectにアップロード
	@echo ">>> IPAをApp Store Connectにアップロード中"
	@RELEASE_IPA_PATH=$$(find $(EXPORT_DIR) -name "*.ipa" -print -quit); \
	if [ -z "$$RELEASE_IPA_PATH" ]; then echo "❌ エラー: アップロードするIPAが $(EXPORT_DIR) に見つかりません。"; exit 1; fi; \
	if [ -z "$$APP_STORE_CONNECT_API_KEY_ID" ] || [ -z "$$APP_STORE_CONNECT_ISSUER_ID" ] || [ -z "$$APP_STORE_CONNECT_API_PRIVATE_KEY" ]; then \
		echo "❌ エラー: App Store Connect APIシークレット (ID, Issuer, Key) が環境変数として設定されている必要があります。"; \
		exit 1; \
	fi
	xcrun altool --upload-app -f "$$RELEASE_IPA_PATH" --type watchos \
		--apiKey "$$APP_STORE_CONNECT_API_KEY_ID" \
		--apiIssuer "$$APP_STORE_CONNECT_ISSUER_ID" \
		--apiPrivateKey <(echo "$$APP_STORE_CONNECT_API_PRIVATE_KEY")
	@echo "✅ IPAアップロードコマンドが実行されました。"

release: export-ipa upload-ipa ## リリースアーカイブをビルドし、IPAをエクスポート、検証、App Store Connectにアップロード

# === リリースクリーンアップ ===
clean-release: ## リリース関連の出力ファイルを削除
	@echo ">>> リリース関連の出力をクリーンアップ中"
	rm -rf "$(RELEASE_ARCHIVE_DIR)" "$(EXPORT_DIR)" "$(EXPORT_OPTIONS_PLIST)"