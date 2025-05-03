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

# === Check if make command exists ===
if ! command -v make &> /dev/null; then
    fail "'make' command not found. Please install build essentials or Xcode Command Line Tools."
fi

# === Default Flags ===
run_unit_tests=false
run_ui_tests=false
run_archive=false
run_all=true # Default: Run all primary targets if no specific action requested

# === Argument Parsing ===
specific_action_requested=false
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --all-tests)
      run_unit_tests=true
      run_ui_tests=true
      run_archive=false
      run_all=false
      specific_action_requested=true
      shift
      ;;
    --unit-test)
      run_unit_tests=true
      run_archive=false
      run_all=false
      specific_action_requested=true
      shift
      ;;
    --ui-test)
      run_ui_tests=true
      run_archive=false
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
      echo "Warning: --test-without-building flag is ignored." >&2
      echo "         Makefile now handles build dependencies automatically." >&2
      shift
      ;;
    *)    # Unknown option
      echo "Unknown option: $1"
      echo "Usage: $0 [--all-tests | --unit-test | --ui-test | --archive-only]"
      exit 1
      ;;
  esac
done

# If no specific action was requested, run default targets
if [ "$specific_action_requested" = false ]; then
  run_unit_tests=true
  run_ui_tests=true
  run_archive=true
fi

# === Initial Setup (Common for most targets) ===
step "Running initial setup (make codegen)"
make codegen || fail "make codegen failed."
success "Initial setup (make codegen) complete."

# === Execute make targets based on flags ===

if [ "$run_unit_tests" = true ]; then
  step "Running Unit Tests (make unit-test)"
  make unit-test || fail "make unit-test failed."
  success "Unit tests completed."
fi

if [ "$run_ui_tests" = true ]; then
  step "Running UI Tests (make ui-test)"
  make ui-test || fail "make ui-test failed."
  success "UI tests completed."
fi

if [ "$run_archive" = true ]; then
  step "Building Archive (make archive)"
  make archive || fail "make archive failed."
  success "Archive build completed."
fi

step "Local CI Check Completed Successfully!" 