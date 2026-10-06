#!/bin/bash
set -euo pipefail
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
: "${FRAMEWINK_SIMULATOR_ID:?Set a dedicated iPhone Duo Simulator ID and select Open landscape in Device Hub.}"
export DEVELOPER_DIR=${FRAMEWINK_XCODE_DEVELOPER_DIR:-/Applications/Xcode-27.1-RC.app/Contents/Developer}
derived_data=${FRAMEWINK_DERIVED_DATA:-/private/tmp/FrameWink-Duo-Website-DerivedData}
output="$repo_root/Design/Website/iPhone-Duo/Sources"
mkdir -p "$output"
xcodebuild -quiet -project "$repo_root/FrameWink.xcodeproj" -scheme FrameWink \
    -configuration Debug -destination "platform=iOS Simulator,id=$FRAMEWINK_SIMULATOR_ID" \
    -derivedDataPath "$derived_data" build
xcrun simctl install "$FRAMEWINK_SIMULATOR_ID" "$derived_data/Build/Products/Debug-iphonesimulator/FrameWink.app"
xcrun simctl ui "$FRAMEWINK_SIMULATOR_ID" appearance light
xcrun simctl status_bar "$FRAMEWINK_SIMULATOR_ID" override --time 9:41 \
    --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState discharging --batteryLevel 100
trap 'xcrun simctl status_bar "$FRAMEWINK_SIMULATOR_ID" clear >/dev/null 2>&1 || true' EXIT
for item in 'duo-gallery-frame:open-landscape' 'frame-controls:open-controls-landscape'; do
    scenario=${item%%:*}
    name=${item#*:}
    temporary="$output/.$name.png"
    SIMCTL_CHILD_FRAMEWINK_SCREENSHOT_SCENARIO="$scenario" xcrun simctl launch \
        --terminate-running-process "$FRAMEWINK_SIMULATOR_ID" media.jenny.FrameWink >/dev/null
    sleep 6
    xcrun simctl io "$FRAMEWINK_SIMULATOR_ID" screenshot --display=LCD-1 "$temporary"
    [ "$(magick identify -format '%wx%h' "$temporary")" = '2853x2007' ] || {
        rm -f "$temporary"; echo "Select Open landscape, full screen, then retry." >&2; exit 1;
    }
    deviation=$(magick "$temporary" -colorspace gray -format '%[fx:standard_deviation]' info:)
    awk -v deviation="$deviation" 'BEGIN { exit !(deviation >= 0.05) }' || {
        rm -f "$temporary"; echo "Rejected inactive display." >&2; exit 1;
    }
    mv "$temporary" "$output/$name.png"
done
echo "Saved two authentic native Duo website captures. Update the provenance hashes after recapturing."
