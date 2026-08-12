#!/bin/sh

set -eu

FRAMEWINK_REPOSITORY_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FRAMEWINK_XCODE_DEVELOPER_DIR=${FRAMEWINK_XCODE_DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}
FRAMEWINK_DERIVED_DATA=${FRAMEWINK_DERIVED_DATA:-/private/tmp/FrameWink-Screenshot-DerivedData}
FRAMEWINK_SCREENSHOT_DIRECTORY=${FRAMEWINK_SCREENSHOT_DIRECTORY:-$FRAMEWINK_REPOSITORY_ROOT/AppStore/Screenshots/iPad}
FRAMEWINK_SIMULATOR_ID=${FRAMEWINK_SIMULATOR_ID:-}

if [ -z "$FRAMEWINK_SIMULATOR_ID" ]; then
    FRAMEWINK_SIMULATOR_ID=$(
        DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun simctl list devices booted \
            | sed -nE '/iPad/{s/.*\(([0-9A-F-]{36})\).*/\1/p;q;}'
    )
fi

if [ -z "$FRAMEWINK_SIMULATOR_ID" ]; then
    echo "No booted iPad Simulator was found. Boot one or set FRAMEWINK_SIMULATOR_ID." >&2
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

capture_scenario sample 01-free-sample.png
capture_scenario smart-frame 02-free-frame-mode.png
capture_scenario paywall-features 03-paid-wall-mode-features.png
capture_scenario paywall 04-paid-wall-mode-purchase.png
capture_scenario wall-mode-setup 05-paid-automatic-album.png
capture_scenario saved-configurations 06-paid-saved-configurations.png
capture_scenario wall-schedule 07-paid-night-schedule.png
capture_scenario wall-checklist 08-paid-commissioning-checklist.png
capture_scenario automatic-album-review 09-paid-review-grid.png
capture_scenario mosaic-frame 10-paid-mosaic-frame.png
capture_scenario free-review-grid 11-free-review-grid.png

echo "Captured FrameWink screenshots in $FRAMEWINK_SCREENSHOT_DIRECTORY"
