#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
SDK_VERSION="$(xcrun --sdk iphonesimulator --show-sdk-version)"

RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUTPUT_ROOT="${FRAMEWINK_TEST_OUTPUT_ROOT:-/private/tmp/FrameWink-LocalTests-$RUN_ID}"
IPHONE_DESTINATION="${FRAMEWINK_IPHONE_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest}"
DUO_DESTINATION="${FRAMEWINK_DUO_DESTINATION:-platform=iOS Simulator,name=iPhone Duo,OS=latest}"
IPAD_DESTINATION="${FRAMEWINK_IPAD_DESTINATION:-platform=iOS Simulator,name=iPad (A16),OS=latest}"

run_suite() {
    local label="$1"
    local destination="$2"
    shift 2
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
        -test-timeouts-enabled YES \
        -default-test-execution-time-allowance 120 \
        -maximum-test-execution-time-allowance 120 \
        CODE_SIGNING_ALLOWED=NO \
        -skip-testing:FrameWinkTests/StoreKitConfigurationTests/testStoreKitTestAskToBuyReturnsPendingWithoutUnlocking \
        -skip-testing:FrameWinkUITests/MarketingLandscapeScreenshotTests \
        "$@" \
        test

    xcrun xcresulttool get test-results summary --path "$result_bundle"
}

mkdir -p "$OUTPUT_ROOT"
cd "$REPO_ROOT"

run_suite iPhone "$IPHONE_DESTINATION"
run_suite iPad "$IPAD_DESTINATION"
case "$SDK_VERSION" in
    27.1*|27.2*)
        # Temporary Duo-only exclusion approved by the owner on 2026-10-01.
        # Restore after XCTest reliably drives Duo display rotation.
        run_suite iPhoneDuo "$DUO_DESTINATION" \
            -skip-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPersonalFrameRotatesAndSwipeAdvancesToTheNextPhoto
        ;;
    *) echo "SDK $SDK_VERSION: standard iPhone/iPad gate; native Duo gate deferred." ;;
esac

/bin/bash "$REPO_ROOT/scripts/verify_locked_app_store_screenshots.sh"

echo "Local FrameWink validation passed. Results: $OUTPUT_ROOT"
