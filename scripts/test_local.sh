#!/bin/bash

set -euo pipefail

. "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/build_cache.sh"
framewink_cached_workflow iphonesimulator unsigned "$@"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

export DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
SDK_VERSION="$(xcrun --sdk iphonesimulator --show-sdk-version)"

OUTPUT_ROOT="${FRAMEWINK_TEST_OUTPUT_ROOT:-$FRAMEWINK_BUILD_EVIDENCE/tests}"
IPHONE_DESTINATION="${FRAMEWINK_IPHONE_DESTINATION:-$(python3 "$REPO_ROOT/scripts/build_local.py" --simulator-destination iPhone)}"
IPAD_DESTINATION="${FRAMEWINK_IPAD_DESTINATION:-$(python3 "$REPO_ROOT/scripts/build_local.py" --simulator-destination iPad)}"

run_suite() {
    local label="$1"
    local destination="$2"
    shift 2
    local derived_data="$FRAMEWINK_DERIVED_DATA"
    local result_bundle="$OUTPUT_ROOT/$label.xcresult"

    echo "Running FrameWink tests on $label"
    xcodebuild -quiet \
        -project "$REPO_ROOT/FrameWink.xcodeproj" \
        -scheme FrameWink \
        -configuration Debug \
        -parallel-testing-enabled NO \
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
        DUO_DESTINATION="${FRAMEWINK_DUO_DESTINATION:-$(python3 "$REPO_ROOT/scripts/build_local.py" --simulator-destination Duo)}"
        # The UI runner now drives native Simulator rotation; keep the round trip in the gate.
        run_suite iPhoneDuo "$DUO_DESTINATION"
        ;;
    *) echo "SDK $SDK_VERSION: standard iPhone/iPad gate; native Duo gate deferred." ;;
esac

/bin/bash "$REPO_ROOT/scripts/verify_locked_app_store_screenshots.sh"

echo "Local FrameWink validation passed. Results: $OUTPUT_ROOT"
