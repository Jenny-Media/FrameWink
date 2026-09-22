#!/bin/sh

set -eu

FRAMEWINK_REPOSITORY_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FRAMEWINK_XCODE_DEVELOPER_DIR=${FRAMEWINK_XCODE_DEVELOPER_DIR:-/Applications/Xcode-27.1-beta.app/Contents/Developer}
FRAMEWINK_DERIVED_DATA=${FRAMEWINK_DERIVED_DATA:-/private/tmp/FrameWink-iPhone-Duo-Proof-DerivedData}
FRAMEWINK_SIMULATOR_ID=${FRAMEWINK_SIMULATOR_ID:-}
FRAMEWINK_DUO_DISPLAY=${FRAMEWINK_DUO_DISPLAY:-outer}
FRAMEWINK_SCREENSHOT_SETTLE_SECONDS=${FRAMEWINK_SCREENSHOT_SETTLE_SECONDS:-6}

command -v magick >/dev/null 2>&1 || {
    echo "ImageMagick 7 is required to reject blank captures." >&2
    exit 1
}

if [ -z "$FRAMEWINK_SIMULATOR_ID" ]; then
    FRAMEWINK_SIMULATOR_ID=$(
        DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun simctl list devices booted \
            | sed -nE '/iPhone Duo/{s/.*\(([0-9A-F-]{36})\).*/\1/p;q;}'
    )
fi

if [ -z "$FRAMEWINK_SIMULATOR_ID" ]; then
    echo "No booted iPhone Duo Simulator was found. Boot one or set FRAMEWINK_SIMULATOR_ID." >&2
    exit 1
fi

case "$FRAMEWINK_DUO_DISPLAY" in
    outer)
        FRAMEWINK_DISPLAY_NAME=LCD
        FRAMEWINK_EXPECTED_WIDTH=1398
        FRAMEWINK_EXPECTED_HEIGHT=2034
        FRAMEWINK_DISPLAY_DIRECTORY=Outer
        ;;
    inner)
        FRAMEWINK_DISPLAY_NAME=LCD-1
        FRAMEWINK_EXPECTED_WIDTH=2007
        FRAMEWINK_EXPECTED_HEIGHT=2853
        FRAMEWINK_DISPLAY_DIRECTORY=Inner
        ;;
    *)
        echo "FRAMEWINK_DUO_DISPLAY must be outer or inner." >&2
        exit 1
        ;;
esac

FRAMEWINK_SCREENSHOT_DIRECTORY=${FRAMEWINK_SCREENSHOT_DIRECTORY:-$FRAMEWINK_REPOSITORY_ROOT/AppStore/Screenshots/ProductPageOptimization/iPhone-Duo/Sources/$FRAMEWINK_DISPLAY_DIRECTORY}
mkdir -p "$FRAMEWINK_SCREENSHOT_DIRECTORY"
find "$FRAMEWINK_SCREENSHOT_DIRECTORY" -maxdepth 1 -type f -name '*.jpg' -delete

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
    FRAMEWINK_DESTINATION="$FRAMEWINK_SCREENSHOT_DIRECTORY/$FRAMEWINK_FILENAME"

    SIMCTL_CHILD_FRAMEWINK_SCREENSHOT_SCENARIO="$FRAMEWINK_SCENARIO" \
        DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" \
        xcrun simctl launch --terminate-running-process \
        "$FRAMEWINK_SIMULATOR_ID" media.jenny.FrameWink >/dev/null
    sleep "$FRAMEWINK_SCREENSHOT_SETTLE_SECONDS"
    DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun simctl io \
        "$FRAMEWINK_SIMULATOR_ID" screenshot \
        --type=jpeg --display "$FRAMEWINK_DISPLAY_NAME" \
        "$FRAMEWINK_DESTINATION"

    FRAMEWINK_DEVIATION=$(magick \
        "$FRAMEWINK_DESTINATION" \
        -colorspace gray -format '%[fx:standard_deviation]' info:)
    awk -v deviation="$FRAMEWINK_DEVIATION" \
        'BEGIN { exit !(deviation >= 0.05) }' || {
        echo "Rejected blank or inactive $FRAMEWINK_DUO_DISPLAY-display capture: $FRAMEWINK_FILENAME" >&2
        exit 1
    }
}

if [ "$FRAMEWINK_DUO_DISPLAY" = outer ]; then
    capture_scenario portrait-frame 01-frame.jpg
else
    capture_scenario duo-gallery-frame 01-gallery.jpg
fi
capture_scenario album-picker 02-album-picker.jpg
capture_scenario frame-controls 03-frame-controls.jpg
capture_scenario sample 04-sample-setup.jpg

FRAMEWINK_SCREENSHOT_COUNT=$(
    find "$FRAMEWINK_SCREENSHOT_DIRECTORY" -maxdepth 1 -type f -name '*.jpg' \
        | wc -l | tr -d ' '
)
[ "$FRAMEWINK_SCREENSHOT_COUNT" -eq 4 ] || {
    echo "Expected four iPhone Duo proof sources, found $FRAMEWINK_SCREENSHOT_COUNT." >&2
    exit 1
}

for FRAMEWINK_SCREENSHOT in "$FRAMEWINK_SCREENSHOT_DIRECTORY"/*.jpg; do
    FRAMEWINK_SCREENSHOT_METADATA=$(sips \
        -g format -g pixelWidth -g pixelHeight -g hasAlpha \
        "$FRAMEWINK_SCREENSHOT")
    case "$FRAMEWINK_SCREENSHOT_METADATA" in
        *"format: jpeg"*"pixelWidth: $FRAMEWINK_EXPECTED_WIDTH"*"pixelHeight: $FRAMEWINK_EXPECTED_HEIGHT"*"hasAlpha: no"*)
            ;;
        *)
            echo "Invalid iPhone Duo $FRAMEWINK_DUO_DISPLAY proof source: $FRAMEWINK_SCREENSHOT" >&2
            echo "$FRAMEWINK_SCREENSHOT_METADATA" >&2
            exit 1
            ;;
    esac
done

echo "Captured four iPhone Duo $FRAMEWINK_DUO_DISPLAY-display proof sources in $FRAMEWINK_SCREENSHOT_DIRECTORY"
