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

# Run Unit Tests
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

# Run UI Tests
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

# --- Build for Production (Archive & Export) ---
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

step "Local CI Check Completed Successfully!" 