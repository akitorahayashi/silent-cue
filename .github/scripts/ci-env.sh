# CIスクリプト用の環境設定

# === 出力先ディレクトリ ===
export OUTPUT_DIR="ci-outputs"
export TEST_RESULTS_DIR="$OUTPUT_DIR/test-results"
export TEST_DERIVED_DATA_DIR="$TEST_RESULTS_DIR/DerivedData"
export PRODUCTION_DIR="$OUTPUT_DIR/production"
export ARCHIVE_DIR="$PRODUCTION_DIR/archives"
export PRODUCTION_DERIVED_DATA_DIR="$ARCHIVE_DIR/DerivedData"

# === プロジェクトファイルとスキーム ===
export PROJECT_FILE="SilentCue.xcodeproj"
export WATCH_APP_SCHEME="SilentCue Watch App"
export UNIT_TEST_SCHEME="SilentCue Watch AppTests"
export UI_TEST_SCHEME="SilentCue Watch AppUITests"