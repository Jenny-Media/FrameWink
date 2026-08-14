#!/bin/sh

set -eu

FRAMEWINK_REPOSITORY_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FRAMEWINK_XCODE_DEVELOPER_DIR=${FRAMEWINK_XCODE_DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}
FRAMEWINK_DERIVED_DATA=${FRAMEWINK_DERIVED_DATA:-/private/tmp/FrameWink-iPhone-AppStore-DerivedData}
FRAMEWINK_SCREENSHOT_DIRECTORY=${FRAMEWINK_SCREENSHOT_DIRECTORY:-$FRAMEWINK_REPOSITORY_ROOT/AppStore/Screenshots/Submission/iPhone-6.9-inch}
FRAMEWINK_SIMULATOR_ID=${FRAMEWINK_SIMULATOR_ID:-}

if [ -z "$FRAMEWINK_SIMULATOR_ID" ]; then
    FRAMEWINK_SIMULATOR_ID=$(
        DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun simctl list devices booted \
            | sed -nE '/iPhone 17 Pro Max/{s/.*\(([0-9A-F-]{36})\).*/\1/p;q;}'
    )
fi

if [ -z "$FRAMEWINK_SIMULATOR_ID" ]; then
    echo "No booted 6.9-inch iPhone Simulator was found. Boot one or set FRAMEWINK_SIMULATOR_ID." >&2
    exit 1
fi

FRAMEWINK_ORIGINAL_APPEARANCE=$(
    DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun simctl ui \
        "$FRAMEWINK_SIMULATOR_ID" appearance
)

restore_simulator_chrome() {
    DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun simctl status_bar \
        "$FRAMEWINK_SIMULATOR_ID" clear >/dev/null 2>&1 || true
    case "$FRAMEWINK_ORIGINAL_APPEARANCE" in
        light|dark)
            DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun simctl ui \
                "$FRAMEWINK_SIMULATOR_ID" appearance \
                "$FRAMEWINK_ORIGINAL_APPEARANCE" >/dev/null 2>&1 || true
            ;;
    esac
}
trap restore_simulator_chrome EXIT INT TERM

mkdir -p "$FRAMEWINK_SCREENSHOT_DIRECTORY"

DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcodebuild -quiet \
    -project "$FRAMEWINK_REPOSITORY_ROOT/FrameWink.xcodeproj" \
    -scheme FrameWink \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$FRAMEWINK_SIMULATOR_ID" \
    -derivedDataPath "$FRAMEWINK_DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    build

FRAMEWINK_APP_PATH="$FRAMEWINK_DERIVED_DATA/Build/Products/Debug-iphonesimulator/FrameWink.app"
DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun simctl install \
    "$FRAMEWINK_SIMULATOR_ID" "$FRAMEWINK_APP_PATH"
DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun simctl ui \
    "$FRAMEWINK_SIMULATOR_ID" appearance light
DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun simctl status_bar \
    "$FRAMEWINK_SIMULATOR_ID" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --batteryState discharging \
    --batteryLevel 100

capture_scenario() {
    FRAMEWINK_SCENARIO=$1
    FRAMEWINK_FILENAME=$2

    SIMCTL_CHILD_FRAMEWINK_SCREENSHOT_SCENARIO="$FRAMEWINK_SCENARIO" \
        DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" \
        xcrun simctl launch --terminate-running-process \
        "$FRAMEWINK_SIMULATOR_ID" media.jenny.FrameWink >/dev/null
    sleep 3
    DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun simctl io \
        "$FRAMEWINK_SIMULATOR_ID" screenshot \
        "$FRAMEWINK_SCREENSHOT_DIRECTORY/$FRAMEWINK_FILENAME"
}

# App Store Connect accepts at most ten screenshots. Keep Free first, then Paid.
capture_scenario sample 01-free-sample.jpg
capture_scenario free-review-grid 02-free-review-grid.jpg
capture_scenario smart-frame 03-free-frame-mode.jpg
capture_scenario paywall 04-paid-lifetime-purchase.jpg
capture_scenario album-picker 05-paid-automatic-album.jpg
capture_scenario frame-controls 06-paid-frame-controls.jpg
capture_scenario mosaic-frame 07-paid-responsive-frame.jpg
capture_scenario wall-schedule 08-paid-night-schedule.jpg
capture_scenario wall-checklist 09-paid-display-guidance.jpg
capture_scenario paywall-features 10-paid-lifetime-features.jpg

FRAMEWINK_SCREENSHOT_COUNT=$(
    find "$FRAMEWINK_SCREENSHOT_DIRECTORY" -maxdepth 1 -type f \
        \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' \) \
        | wc -l | tr -d ' '
)
if [ "$FRAMEWINK_SCREENSHOT_COUNT" -ne 10 ]; then
    echo "Expected exactly ten iPhone submission screenshots, found $FRAMEWINK_SCREENSHOT_COUNT." >&2
    exit 1
fi

for FRAMEWINK_SCREENSHOT in "$FRAMEWINK_SCREENSHOT_DIRECTORY"/*.jpg; do
    FRAMEWINK_SCREENSHOT_METADATA=$(sips \
        -g format -g pixelWidth -g pixelHeight -g hasAlpha \
        "$FRAMEWINK_SCREENSHOT")
    case "$FRAMEWINK_SCREENSHOT_METADATA" in
        *"format: jpeg"*"pixelWidth: 1320"*"pixelHeight: 2868"*"hasAlpha: no"*)
            ;;
        *)
            echo "Invalid 6.9-inch iPhone submission screenshot: $FRAMEWINK_SCREENSHOT" >&2
            echo "$FRAMEWINK_SCREENSHOT_METADATA" >&2
            exit 1
            ;;
    esac
done

echo "Captured ten FrameWink iPhone submission screenshots in $FRAMEWINK_SCREENSHOT_DIRECTORY"
