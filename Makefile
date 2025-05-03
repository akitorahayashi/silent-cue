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

# Simulator ID Finding Command (doesn't execute immediately)
FIND_SIM_CMD := \
	DESTINATIONS=$$($$(XCODEBUILD) -showdestinations -project "$(PROJECT)" -scheme $(SCHEME_WATCH_APP) 2>/dev/null); \
	SIM_INFO=$$($$(echo "$$DESTINATIONS" | grep 'platform:watchOS Simulator' | grep 'name:Apple Watch' | head -n 1)); \
	if [ -z "$$SIM_INFO" ]; then \
		echo "Error: Could not find a suitable 'Apple Watch' simulator." >&2; \
		exit 1; \
	fi; \
	SIM_ID=$$($$(echo "$$SIM_INFO" | sed -nE 's/.*id:([0-9A-F-]+).*/\1/p')); \
	if [ -z "$$SIM_ID" ]; then \
		echo "Error: Could not extract simulator ID from: $$SIM_INFO" >&2; \
		exit 1; \
	fi; \
	UI_DEST_CHECK=$$($$(XCODEBUILD) -showdestinations -project "$(PROJECT)" -scheme $(SCHEME_UI_TESTS) 2>/dev/null | grep "id:$$SIM_ID" || echo "not found"); \
	if [[ "$$UI_DEST_CHECK" == "not found" ]]; then \
		echo "Error: Simulator ID $$SIM_ID not valid for UI test scheme $(SCHEME_UI_TESTS)." >&2; \
		exit 1; \
	fi; \
	echo $$SIM_ID

# Variable to cache the found Simulator ID (initially empty)
_SIMULATOR_ID :=

# Target to find and cache the simulator ID if not already found
.PHONY: ensure-simulator-id
ensure-simulator-id:
	$(if $(_SIMULATOR_ID),,\
		@echo "Finding simulator ID..."; \
		export _SIMULATOR_ID := $(shell $(FIND_SIM_CMD)); \
		$(if $(_SIMULATOR_ID),@echo "Using Simulator ID: $(_SIMULATOR_ID)",$(error Could not find simulator ID. FIND_SIM_CMD output: $(shell $(FIND_SIM_CMD) 2>&1)))
	)

# Define destination using the potentially cached simulator ID
DESTINATION_SIMULATOR := "platform=watchOS Simulator,id=$(_SIMULATOR_ID)"

.PHONY: all setup-mint codegen build-for-testing unit-test ui-test run-tests build-unsigned-archive verify-archive lint format-check code-quality-check clean clean-derived-data help release-archive setup-signing export-ipa validate-ipa upload-ipa github-release release clean-release

help: ## ヘルプメッセージを表示
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

all: code-quality-check run-tests build-unsigned-archive ## 品質チェック、テスト、アーカイブを実行

# === Setup ===
setup-mint: ## Mintをインストールし、依存関係をブートストラップ
	brew install mint
	$(MINT) bootstrap

codegen:
	$(MINT) run xcodegen generate

# === Build & Test ===

$(DERIVED_DATA_PATH):
	mkdir -p $(DERIVED_DATA_PATH)

build-for-testing: $(DERIVED_DATA_PATH) ensure-simulator-id ## シミュレータでのテスト用にアプリをビルド
	@echo ">>> Building for Testing (Simulator ID: $(_SIMULATOR_ID))"
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
	@echo ">>> Running Unit Tests (Simulator ID: $(_SIMULATOR_ID))"
	set -o pipefail && $(XCODEBUILD) test-without-building \
		-project "$(PROJECT)" \
		-scheme $(SCHEME_UNIT_TESTS) \
		-destination $(DESTINATION_SIMULATOR) \
		-derivedDataPath "$(DERIVED_DATA_PATH)" \
		-enableCodeCoverage NO \
		-resultBundlePath "$(UNIT_TEST_RESULTS_DIR)/TestResults.xcresult" \
	| $(XCBEAUTIFY) --report junit --report-path "$(UNIT_TEST_RESULTS_DIR)/junit.xml"
	@echo "Checking for Unit Test results bundle..."
	@if [ ! -d "$(UNIT_TEST_RESULTS_DIR)/TestResults.xcresult" ]; then \
		echo "❌ Error: Unit test result bundle not found at $(UNIT_TEST_RESULTS_DIR)/TestResults.xcresult"; \
		exit 1; \
	fi
	@echo "✅ Unit test result bundle found."

$(UI_TEST_RESULTS_DIR):
	mkdir -p $(UI_TEST_RESULTS_DIR)

ui-test: build-for-testing ensure-simulator-id ## UIテストを実行
	@echo ">>> Running UI Tests (Simulator ID: $(_SIMULATOR_ID))"
	set -o pipefail && $(XCODEBUILD) test-without-building \
		-project "$(PROJECT)" \
		-scheme $(SCHEME_UI_TESTS) \
		-destination $(DESTINATION_SIMULATOR) \
		-derivedDataPath "$(DERIVED_DATA_PATH)" \
		-enableCodeCoverage NO \
		-resultBundlePath "$(UI_TEST_RESULTS_DIR)/TestResults.xcresult" \
	| $(XCBEAUTIFY) --report junit --report-path "$(UI_TEST_RESULTS_DIR)/junit.xml"
	@echo "Checking for UI Test results bundle..."
	@if [ ! -d "$(UI_TEST_RESULTS_DIR)/TestResults.xcresult" ]; then \
		echo "❌ Error: UI test result bundle not found at $(UI_TEST_RESULTS_DIR)/TestResults.xcresult"; \
		exit 1; \
	fi
	@echo "✅ UI test result bundle found."


run-tests: unit-test ui-test ## 全てのテストを実行 (Unit と UI)

# === Archive ===

$(ARCHIVE_OUTPUT_DIR):
	mkdir -p $(ARCHIVE_OUTPUT_DIR)

build-unsigned-archive: $(ARCHIVE_OUTPUT_DIR) ## 署名なしのリリースアーカイブをビルド (ci-outputs/production/archives)
	@echo ">>> Building Unsigned Release Archive"
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
	@echo ">>> Verifying Archive Contents"
	@EXPECTED_APP_NAME="$(SCHEME_WATCH_APP).app"; \
	EXPECTED_APP_PATH="$(ARCHIVE_PATH)/Products/Applications/$$EXPECTED_APP_NAME"; \
	echo "Checking path: '$$EXPECTED_APP_PATH'"; \
	if [ ! -d "$$EXPECTED_APP_PATH" ]; then \
		echo "❌ Error: '$$EXPECTED_APP_NAME' not found in expected archive location ('$$EXPECTED_APP_PATH')."; \
		echo "--- Archive Contents (on error) ---"; \
		ls -lR "$(ARCHIVE_PATH)" || echo "Archive directory not found or empty."; \
		exit 1; \
	fi
	@echo "✅ Archive content verified."

# === Code Quality ===
lint: ## SwiftLintを実行
	@echo ">>> Running SwiftLint"
	$(MINT) run swiftlint --strict

format-check: ## SwiftFormatでフォーマットをチェック
	@echo ">>> Checking formatting with SwiftFormat"
	$(MINT) run swiftformat --lint .
	@echo "Checking for formatting changes..."
	@if ! git diff --quiet; then \
		echo "❌ Error: SwiftFormat found formatting violations. Please run 'make format' locally."; \
		git diff; \
		exit 1; \
	fi
	@echo "✅ Code formatting is correct."

format: ## SwiftFormatでフォーマットを適用
	@echo ">>> Applying formatting with SwiftFormat"
	$(MINT) run swiftformat .

code-quality-check: lint format-check ## 全てのコード品質チェックを実行 (lint と format-check)

# === Clean ===
clean-derived-data: ## DerivedDataディレクトリを削除
	@echo ">>> Cleaning Derived Data"
	rm -rf "$(DERIVED_DATA_PATH)"
	rm -rf "$(ARCHIVE_OUTPUT_DIR)/DerivedData"

clean: clean-derived-data clean-release ## 全てのビルド成果物と出力ディレクトリを削除
	@echo ">>> Cleaning all outputs"
	rm -rf "$(OUTPUT_DIR)"

# === Release Targets ===

RELEASE_ARCHIVE_DIR := build
RELEASE_ARCHIVE_PATH := $(RELEASE_ARCHIVE_DIR)/SilentCue.xcarchive
RELEASE_DERIVED_DATA_PATH := $(RELEASE_ARCHIVE_DIR)/DerivedData
EXPORT_DIR := ./ipa_export
EXPORT_OPTIONS_PLIST := ./ExportOptions.plist

$(RELEASE_ARCHIVE_DIR):
	mkdir -p $(RELEASE_ARCHIVE_DIR) $(RELEASE_DERIVED_DATA_PATH)

release-archive: $(RELEASE_ARCHIVE_DIR) ## リリース用の署名なしアーカイブをビルド (出力先: ./build)
	@echo ">>> Building Unsigned Release Archive (Output: $(RELEASE_ARCHIVE_PATH))"
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
	@echo ">>> Verifying Release Archive Contents"
	@EXPECTED_APP_NAME="$(SCHEME_WATCH_APP).app"; \
	EXPECTED_APP_PATH="$(RELEASE_ARCHIVE_PATH)/Products/Applications/$$EXPECTED_APP_NAME"; \
	echo "Checking path: '$$EXPECTED_APP_PATH'"; \
	if [ ! -d "$$EXPECTED_APP_PATH" ]; then \
		echo "❌ Error: '$$EXPECTED_APP_NAME' not found in expected release archive location ('$$EXPECTED_APP_PATH')."; \
		ls -lR "$(RELEASE_ARCHIVE_PATH)" || echo "Release archive directory not found or empty."; \
		exit 1; \
	fi
	@echo "✅ Release archive content verified."

$(EXPORT_DIR):
	mkdir -p $(EXPORT_DIR)

export-ipa: release-archive $(EXPORT_DIR)
	@echo ">>> Exporting Signed IPA (Archive: $(RELEASE_ARCHIVE_PATH))"
	@if [ ! -f "$(EXPORT_OPTIONS_PLIST)" ]; then \
		echo "❌ Error: ExportOptions.plist not found at $(EXPORT_OPTIONS_PLIST). Generate it first."; \
		exit 1; \
	fi
	$(XCODEBUILD) -exportArchive \
		-archivePath "$(RELEASE_ARCHIVE_PATH)" \
		-exportPath "$(EXPORT_DIR)" \
		-exportOptionsPlist "$(EXPORT_OPTIONS_PLIST)" \
		-allowProvisioningUpdates
	@echo "✅ IPA exported successfully to $$RELEASE_IPA_PATH"

validate-ipa: export-ipa
	@echo ">>> Validating IPA with App Store Connect"
	@RELEASE_IPA_PATH=$$(find $(EXPORT_DIR) -name "*.ipa" -print -quit); \
	if [ -z "$$RELEASE_IPA_PATH" ]; then echo "❌ Error: No IPA found in $(EXPORT_DIR) to validate."; exit 1; fi; \
	if [ -z "$$APP_STORE_CONNECT_API_KEY_ID" ] || [ -z "$$APP_STORE_CONNECT_ISSUER_ID" ] || [ -z "$$APP_STORE_CONNECT_API_PRIVATE_KEY" ]; then \
		echo "❌ Error: App Store Connect API secrets (ID, Issuer, Key) must be set as environment variables."; \
		exit 1; \
	fi
	xcrun altool --validate-app -f "$$RELEASE_IPA_PATH" --type watchos \
		--apiKey "$$APP_STORE_CONNECT_API_KEY_ID" \
		--apiIssuer "$$APP_STORE_CONNECT_ISSUER_ID" \
		--apiPrivateKey <(echo "$$APP_STORE_CONNECT_API_PRIVATE_KEY")
	@echo "✅ IPA validation command executed."

upload-ipa: validate-ipa
	@echo ">>> Uploading IPA to App Store Connect"
	@RELEASE_IPA_PATH=$$(find $(EXPORT_DIR) -name "*.ipa" -print -quit); \
	if [ -z "$$RELEASE_IPA_PATH" ]; then echo "❌ Error: No IPA found in $(EXPORT_DIR) to upload."; exit 1; fi; \
	if [ -z "$$APP_STORE_CONNECT_API_KEY_ID" ] || [ -z "$$APP_STORE_CONNECT_ISSUER_ID" ] || [ -z "$$APP_STORE_CONNECT_API_PRIVATE_KEY" ]; then \
		echo "❌ Error: App Store Connect API secrets (ID, Issuer, Key) must be set as environment variables."; \
		exit 1; \
	fi
	xcrun altool --upload-app -f "$$RELEASE_IPA_PATH" --type watchos \
		--apiKey "$$APP_STORE_CONNECT_API_KEY_ID" \
		--apiIssuer "$$APP_STORE_CONNECT_ISSUER_ID" \
		--apiPrivateKey <(echo "$$APP_STORE_CONNECT_API_PRIVATE_KEY")
	@echo "✅ IPA upload command executed."

release: export-ipa upload-ipa ## リリースアーカイブをビルドし、IPAをエクスポート、検証、App Store Connectにアップロード

# === Clean Release ===
clean-release:
	@echo ">>> Cleaning release outputs"
	rm -rf "$(RELEASE_ARCHIVE_DIR)" "$(EXPORT_DIR)" "$(EXPORT_OPTIONS_PLIST)"