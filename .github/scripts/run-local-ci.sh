#!/bin/bash
set -euo pipefail

# === Configuration ===
OUTPUT_DIR="ci-outputs"
TEST_RESULTS_DIR="$OUTPUT_DIR/test-results"
TEST_DERIVED_DATA_DIR="$TEST_RESULTS_DIR/DerivedData"
PRODUCTION_DIR="$OUTPUT_DIR/production"
ARCHIVE_DIR="$PRODUCTION_DIR/archives"
PRODUCTION_DERIVED_DATA_DIR="$ARCHIVE_DIR/DerivedData"
EXPORT_DIR="$PRODUCTION_DIR/Export"
PROJECT_FILE="SilentCue.xcodeproj"
WATCH_APP_SCHEME="SilentCue Watch App"
UNIT_TEST_SCHEME="SilentCue Watch AppTests"
UI_TEST_SCHEME="SilentCue Watch AppUITests"

# === Default Flags ===
run_unit_tests=false
run_ui_tests=false
run_archive=false
skip_build_for_testing=false
run_all=true # 引数指定がない場合は全ステップを実行

# === Argument Parsing ===
specific_action_requested=false
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --all-tests)
      run_unit_tests=true
      run_ui_tests=true
      run_archive=false # このフラグ指定時はテストのみ実行
      run_all=false
      specific_action_requested=true
      shift
      ;;
    --unit-test)
      run_unit_tests=true
      run_archive=false # このフラグ指定時はテストのみ実行
      run_all=false
      specific_action_requested=true
      shift
      ;;
    --ui-test)
      run_ui_tests=true
      run_archive=false # このフラグ指定時はテストのみ実行
      run_all=false
      specific_action_requested=true
      shift
      ;;
    --archive-only)
      run_unit_tests=false
      run_ui_tests=false
      run_archive=true
      run_all=false
      specific_action_requested=true
      shift
      ;;
    --test-without-building)
      skip_build_for_testing=true
      run_archive=false # ビルドなしではアーカイブ不可
      run_all=false
      # 他のフラグによる specific_action_requested の状態を維持
      shift
      ;;
    *)    # 不明なオプション
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# 特定のアクションが要求されなかった場合、全て実行
if [ "$specific_action_requested" = false ]; then
  run_unit_tests=true
  run_ui_tests=true
  run_archive=true
fi

# === Helper Functions ===
step() {
  echo ""
  echo "──────────────────────────────────────────────────────────────────────"
  echo "▶️  $1"
  echo "──────────────────────────────────────────────────────────────────────"
}

success() {
  echo "✅ $1"
}

fail() {
  echo "❌ Error: $1"
  exit 1
}


# === XcodeGen ===
# プロジェクト生成 (アーカイブ時 or ビルドを伴うテスト実行時)
if [[ "$skip_build_for_testing" = false && ( "$run_archive" = true || "$run_unit_tests" = true || "$run_ui_tests" = true ) ]]; then
  step "Generating Xcode project using XcodeGen"
  # mint の存在確認
  if ! command -v mint &> /dev/null; then
      fail "Mint がインストールされていません。先に mint をインストールしてください。(brew install mint)"
  fi
  # xcodegen の存在確認 (なければ bootstrap)
  if ! mint list | grep -q 'XcodeGen'; then
      echo "mint で XcodeGen が見つかりません。'mint bootstrap' を実行します..."
      mint bootstrap || fail "mint パッケージの bootstrap に失敗しました。"
  fi
  echo "Running xcodegen..."
  mint run xcodegen || fail "XcodeGen によるプロジェクト生成に失敗しました。"
  # プロジェクトファイルの存在確認
  if [ ! -d "$PROJECT_FILE" ]; then
    fail "XcodeGen 実行後、プロジェクトファイル '$PROJECT_FILE' が見つかりません。"
  fi
  success "Xcode project generated successfully."
fi

# === Main Script ===

# 前回の出力削除とディレクトリ作成 (ビルドスキップ時以外)
if [ "$skip_build_for_testing" = false ] || [ "$run_archive" = true ]; then
  step "Cleaning previous outputs and creating directories"
  echo "Removing old $OUTPUT_DIR directory if it exists..."
  rm -rf "$OUTPUT_DIR"
  echo "Creating directories..."
  mkdir -p "$TEST_RESULTS_DIR/unit" "$TEST_RESULTS_DIR/ui" "$TEST_DERIVED_DATA_DIR" \
           "$ARCHIVE_DIR" "$PRODUCTION_DERIVED_DATA_DIR" "$EXPORT_DIR"
  success "Directories created under $OUTPUT_DIR."
else
  step "Skipping cleanup and directory creation (reusing existing build outputs)"
  # ビルドなしでテストを実行する場合、必要なディレクトリが存在するか確認
  if [ "$run_unit_tests" = true ] || [ "$run_ui_tests" = true ]; then
      if [ ! -d "$TEST_DERIVED_DATA_DIR" ]; then
          fail "Cannot run tests without building: DerivedData directory not found at $TEST_DERIVED_DATA_DIR. Run a full build first."
      fi
      mkdir -p "$TEST_RESULTS_DIR/unit" "$TEST_RESULTS_DIR/ui"
      success "Required test directories exist or created."
  fi
fi

# --- Run Tests ---
if [ "$run_unit_tests" = true ] || [ "$run_ui_tests" = true ]; then
  step "Running Tests"

  echo "Finding simulator..."
  SIMULATOR_ID=$(./.github/scripts/find-simulator.sh)
  if [ -z "$SIMULATOR_ID" ]; then
    fail "Could not find a suitable simulator."
  fi
  echo "Using Simulator ID: $SIMULATOR_ID"
  success "Simulator selected."

  # Build for Testing (スキップされていない場合)
  if [ "$skip_build_for_testing" = false ]; then
    echo "Building for testing..."
    set -o pipefail && xcodebuild build-for-testing \
      -project "$PROJECT_FILE" \
      -scheme "$WATCH_APP_SCHEME" \
      -destination "platform=watchOS Simulator,id=$SIMULATOR_ID" \
      -derivedDataPath "$TEST_DERIVED_DATA_DIR" \
      -configuration Debug \
      -skipMacroValidation \
      CODE_SIGNING_ALLOWED=NO \
    | xcpretty -c
    success "Build for testing completed."
  else
      echo "Skipping build for testing as requested (--test-without-building)."
      if [ ! -d "$TEST_DERIVED_DATA_DIR/Build/Intermediates.noindex/XCBuildData" ]; then
         fail "Cannot skip build: No existing build artifacts found in $TEST_DERIVED_DATA_DIR. Run a full build first."
      fi
      success "Using existing build artifacts."
  fi

  # Run Unit Tests
  if [ "$run_unit_tests" = true ]; then
    echo "Running unit tests..."
    set -o pipefail && xcodebuild test-without-building \
      -project "$PROJECT_FILE" \
      -scheme "$UNIT_TEST_SCHEME" \
      -destination "platform=watchOS Simulator,id=$SIMULATOR_ID" \
      -derivedDataPath "$TEST_DERIVED_DATA_DIR" \
      -enableCodeCoverage NO \
      -resultBundlePath "$TEST_RESULTS_DIR/unit/TestResults.xcresult" \
    | xcbeautify --report junit --report-path "$TEST_RESULTS_DIR/unit/junit.xml"

    echo "Verifying unit test results bundle..."
    if [ ! -d "$TEST_RESULTS_DIR/unit/TestResults.xcresult" ]; then
      fail "Unit test result bundle not found at $TEST_RESULTS_DIR/unit/TestResults.xcresult"
    fi
    success "Unit test result bundle found at $TEST_RESULTS_DIR/unit/TestResults.xcresult"
  fi

  # Run UI Tests
  if [ "$run_ui_tests" = true ]; then
    echo "Running UI tests..."
    set -o pipefail && xcodebuild test-without-building \
      -project "$PROJECT_FILE" \
      -scheme "$UI_TEST_SCHEME" \
      -destination "platform=watchOS Simulator,id=$SIMULATOR_ID" \
      -derivedDataPath "$TEST_DERIVED_DATA_DIR" \
      -enableCodeCoverage NO \
      -resultBundlePath "$TEST_RESULTS_DIR/ui/TestResults.xcresult" \
    | xcbeautify --report junit --report-path "$TEST_RESULTS_DIR/ui/junit.xml"

    echo "Verifying UI test results bundle..."
    if [ ! -d "$TEST_RESULTS_DIR/ui/TestResults.xcresult" ]; then
      fail "UI test result bundle not found at $TEST_RESULTS_DIR/ui/TestResults.xcresult"
    fi
    success "UI test result bundle found at $TEST_RESULTS_DIR/ui/TestResults.xcresult"
  fi
fi

# --- Build for Production (Archive) ---
if [ "$run_archive" = true ]; then
  step "Building for Production (Unsigned)"

  ARCHIVE_PATH="$ARCHIVE_DIR/SilentCue.xcarchive"
  ARCHIVE_APP_PATH="$ARCHIVE_PATH/Products/Applications/$WATCH_APP_SCHEME.app"

  echo "Building archive..."
  set -o pipefail && xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$WATCH_APP_SCHEME" \
    -configuration Release \
    -destination "generic/platform=watchOS" \
    -archivePath "$ARCHIVE_PATH" \
    -derivedDataPath "$PRODUCTION_DERIVED_DATA_DIR" \
    -skipMacroValidation \
    CODE_SIGNING_ALLOWED=NO \
    archive \
  | xcpretty -c
  success "Archive build completed."

  echo "Verifying archive contents..."
  if [ ! -d "$ARCHIVE_APP_PATH" ]; then
    echo "Error: '$WATCH_APP_SCHEME.app' not found in expected archive location ($ARCHIVE_APP_PATH)."
    echo "--- Listing Archive Contents (on error) ---"
    ls -lR "$ARCHIVE_PATH" || echo "Archive directory not found or empty."
    fail "Archive verification failed."
  fi
  success "Archive content verified."
fi

step "Local CI Check Completed Successfully!" 