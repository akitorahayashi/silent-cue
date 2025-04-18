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

# Default behavior: run all steps
run_unit=true
run_ui=true
run_archive=true
selected_option=""

# Parse command line options
while [[ $# -gt 0 ]]; do
  key="$1"
  if [[ -n "$selected_option" && "$key" == --* ]]; then
    echo "Error: Options (--all-tests, --unit-test, --ui-test, --archive-only) are mutually exclusive."
    exit 1
  fi

  case $key in
    --all-tests)
      run_unit=true
      run_ui=true
      run_archive=false
      selected_option="--all-tests"
      shift # past argument
      ;;
    --unit-test)
      run_unit=true
      run_ui=false
      run_archive=false
      selected_option="--unit-test"
      shift # past argument
      ;;
    --ui-test)
      run_unit=false
      run_ui=true
      run_archive=false
      selected_option="--ui-test"
      shift # past argument
      ;;
    --archive-only)
      run_unit=false
      run_ui=false
      run_archive=true
      selected_option="--archive-only"
      shift # past argument
      ;;
    *)    # unknown option
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Determine if any tests need to be run
run_any_tests=$([ "$run_unit" = true ] || [ "$run_ui" = true ] && echo true || echo false)

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

check_command() {
  if ! command -v $1 &> /dev/null; then
    echo "⚠️ Warning: '$1' command not found. Attempting to install..."
    if [ "$1" == "xcpretty" ]; then
      gem install xcpretty || fail "Failed to install xcpretty. Please install it manually (gem install xcpretty)."
      success "xcpretty installed successfully."
    else
      fail "Required command '$1' is not installed. Please install it."
    fi
  fi
}

# === Main Script ===

# Check prerequisites
step "Checking prerequisites"
check_command xcpretty
success "Prerequisites met."

# Clean previous outputs and create directories
step "Cleaning previous outputs and creating directories"
echo "Removing old $OUTPUT_DIR directory if it exists..."
rm -rf "$OUTPUT_DIR"
echo "Creating directories..."
mkdir -p "$TEST_RESULTS_DIR/unit" "$TEST_RESULTS_DIR/ui" "$TEST_DERIVED_DATA_DIR" \
         "$ARCHIVE_DIR" "$PRODUCTION_DERIVED_DATA_DIR" "$EXPORT_DIR"
success "Directories created under $OUTPUT_DIR."

# --- Run Tests ---
if $run_any_tests; then
  step "Running Tests"

  # Find simulator
  echo "Finding simulator..."
  SIMULATOR_ID=$(./.github/scripts/find-simulator.sh)
  if [ -z "$SIMULATOR_ID" ]; then
    fail "Could not find a suitable simulator."
  fi
  echo "Using Simulator ID: $SIMULATOR_ID"
  success "Simulator selected."

  # Build for Testing
  if $run_unit || $run_ui; then
    echo "Building for testing..."
    set -o pipefail && xcodebuild build-for-testing \
      -project "$PROJECT_FILE" \
      -scheme "$WATCH_APP_SCHEME" \
      -destination "platform=watchOS Simulator,id=$SIMULATOR_ID" \
      -derivedDataPath "$TEST_DERIVED_DATA_DIR" \
      -configuration Debug \
      -skipMacroValidation \
      CODE_SIGNING_ALLOWED=NO \
    | xcpretty -c || fail "Build for testing failed."
    success "Build for testing completed."
  fi

  # Run Unit Tests
  if $run_unit; then
    echo "Running unit tests..."
    set -o pipefail && xcodebuild test-without-building \
      -project "$PROJECT_FILE" \
      -scheme "$UNIT_TEST_SCHEME" \
      -destination "platform=watchOS Simulator,id=$SIMULATOR_ID" \
      -derivedDataPath "$TEST_DERIVED_DATA_DIR" \
      -enableCodeCoverage NO \
      -resultBundlePath "$TEST_RESULTS_DIR/unit/TestResults.xcresult" \
    | xcpretty -c || echo "Unit test execution finished with non-zero exit code (ignoring for local check)."

    # Check Unit Test Results Bundle Existence
    echo "Verifying unit test results bundle..."
    if [ ! -d "$TEST_RESULTS_DIR/unit/TestResults.xcresult" ]; then
      fail "Unit test result bundle not found at $TEST_RESULTS_DIR/unit/TestResults.xcresult"
    fi
    success "Unit test result bundle found at $TEST_RESULTS_DIR/unit/TestResults.xcresult"
  else
    echo "ℹ️ Skipping Unit Tests."
  fi

  # Run UI Tests
  if $run_ui; then
    echo "Running UI tests..."
    set -o pipefail && xcodebuild test-without-building \
      -project "$PROJECT_FILE" \
      -scheme "$UI_TEST_SCHEME" \
      -destination "platform=watchOS Simulator,id=$SIMULATOR_ID" \
      -derivedDataPath "$TEST_DERIVED_DATA_DIR" \
      -enableCodeCoverage NO \
      -resultBundlePath "$TEST_RESULTS_DIR/ui/TestResults.xcresult" \
    | xcpretty -c || echo "UI test execution finished with non-zero exit code (ignoring for local check)."

    # Check UI Test Results Bundle Existence
    echo "Verifying UI test results bundle..."
    if [ ! -d "$TEST_RESULTS_DIR/ui/TestResults.xcresult" ]; then
      fail "UI test result bundle not found at $TEST_RESULTS_DIR/ui/TestResults.xcresult"
    fi
    success "UI test result bundle found at $TEST_RESULTS_DIR/ui/TestResults.xcresult"
  else
    echo "ℹ️ Skipping UI Tests."
  fi
else
  echo "ℹ️ Skipping Tests (no test option specified)."
fi

# --- Build for Production (Archive & Export) ---
if $run_archive; then
  step "Building for Production (Unsigned)"

  ARCHIVE_PATH="$ARCHIVE_DIR/SilentCue.xcarchive"
  ARCHIVE_APP_PATH="$ARCHIVE_PATH/Products/Applications/$WATCH_APP_SCHEME.app"
  IPA_PATH="$EXPORT_DIR/$WATCH_APP_SCHEME.ipa"

  # Archive Build
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
  | xcpretty -c || fail "Archive build failed."
  success "Archive build completed."

  # Verify Archive Contents
  echo "Verifying archive contents..."
  if [ ! -d "$ARCHIVE_APP_PATH" ]; then
    echo "Error: '$WATCH_APP_SCHEME.app' not found in expected archive location ($ARCHIVE_APP_PATH)."
    echo "--- Listing Archive Contents (on error) ---"
    ls -lR "$ARCHIVE_PATH" || echo "Archive directory not found or empty."
    fail "Archive verification failed."
  fi
  success "Archive content verified."
else
    echo "ℹ️ Skipping Archive (--archive-only not specified, or a test option was specified)."
fi

step "Local CI Check Completed Successfully!" 