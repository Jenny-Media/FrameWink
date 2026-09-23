#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -z "${DEVELOPER_DIR:-}" ]]; then
    if [[ -d /Applications/Xcode-27.1-beta.app/Contents/Developer ]]; then
        export DEVELOPER_DIR=/Applications/Xcode-27.1-beta.app/Contents/Developer
    else
        export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    fi
fi

RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUTPUT_ROOT="${FRAMEWINK_TEST_OUTPUT_ROOT:-/private/tmp/FrameWink-LocalTests-$RUN_ID}"
IPHONE_DESTINATION="${FRAMEWINK_IPHONE_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest}"
IPAD_DESTINATION="${FRAMEWINK_IPAD_DESTINATION:-platform=iOS Simulator,name=iPad (A16),OS=latest}"

run_suite() {
    local label="$1"
    local destination="$2"
    local derived_data="$OUTPUT_ROOT/$label-DerivedData"
    local result_bundle="$OUTPUT_ROOT/$label.xcresult"

    echo "Running FrameWink tests on $label"
    xcodebuild -quiet \
        -project "$REPO_ROOT/FrameWink.xcodeproj" \
        -scheme FrameWink \
        -configuration Debug \
        -destination "$destination" \
        -derivedDataPath "$derived_data" \
        -resultBundlePath "$result_bundle" \
        -collect-test-diagnostics never \
        CODE_SIGNING_ALLOWED=NO \
        -skip-testing:FrameWinkTests/StoreKitConfigurationTests/testStoreKitTestAskToBuyReturnsPendingWithoutUnlocking \
        -skip-testing:FrameWinkUITests/MarketingLandscapeScreenshotTests \
        test

    xcrun xcresulttool get test-results summary --path "$result_bundle"
}

mkdir -p "$OUTPUT_ROOT"
cd "$REPO_ROOT"

run_suite iPhone "$IPHONE_DESTINATION"
run_suite iPad "$IPAD_DESTINATION"

/bin/bash "$REPO_ROOT/scripts/verify_locked_app_store_screenshots.sh"

echo "Local FrameWink validation passed. Results: $OUTPUT_ROOT"
