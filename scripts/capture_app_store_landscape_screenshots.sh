#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
xcode_developer_dir=${FRAMEWINK_XCODE_DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}
ipad_simulator_id=${FRAMEWINK_IPAD_LANDSCAPE_SIMULATOR_ID:-1BDA7ABF-4236-406E-8ACD-7E3B10569753}
iphone_simulator_id=${FRAMEWINK_IPHONE_LANDSCAPE_SIMULATOR_ID:-B41C6094-A3CA-48E6-AA25-1E08D0B98BCE}
ipad_output="$repo_root/AppStore/Screenshots/Landscape/iPad-13-inch"
iphone_output="$repo_root/AppStore/Screenshots/Landscape/iPhone-6.9-inch"
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-landscape-capture.XXXXXX")
booted_by_script=""

export DEVELOPER_DIR="$xcode_developer_dir"

cleanup() {
    xcrun simctl status_bar "$ipad_simulator_id" clear >/dev/null 2>&1 || true
    xcrun simctl status_bar "$iphone_simulator_id" clear >/dev/null 2>&1 || true
    for simulator_id in $booted_by_script; do
        xcrun simctl shutdown "$simulator_id" >/dev/null 2>&1 || true
    done
    rm -rf "$working_directory"
}
trap cleanup EXIT INT TERM

require_tool() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Required tool is unavailable: $1" >&2
        exit 1
    }
}

require_tool jq
require_tool magick

ensure_booted() {
    simulator_id=$1
    simulator_line=$(xcrun simctl list devices | sed -n "/($simulator_id)/p" | head -1)
    [ -n "$simulator_line" ] || {
        echo "Simulator is unavailable: $simulator_id" >&2
        exit 1
    }
    case "$simulator_line" in
        *"(Booted)"*) ;;
        *)
            xcrun simctl boot "$simulator_id"
            booted_by_script="$booted_by_script $simulator_id"
            ;;
    esac
    xcrun simctl bootstatus "$simulator_id" -b
}

export_attachment() {
    manifest=$1
    attachment_directory=$2
    screenshot_name=$3
    destination=$4

    exported_filename=$(jq -r --arg name "$screenshot_name" '
        .[].attachments[]
        | select(.suggestedHumanReadableName | startswith($name + "_"))
        | .exportedFileName
    ' "$manifest")
    [ -n "$exported_filename" ] && [ "$exported_filename" != null ] || {
        echo "Missing screenshot attachment: $screenshot_name" >&2
        exit 1
    }

    # XCUIScreen preserves every rendered pixel but exports the device buffer in
    # its natural portrait orientation. Rotate once to produce the native
    # App Store landscape dimensions without scaling or cropping.
    magick "$attachment_directory/$exported_filename" \
        -rotate -90 \
        -strip \
        -sampling-factor 4:2:0 \
        -quality 94 \
        "$destination"
}

capture_family() {
    family=$1
    simulator_id=$2
    output_directory=$3
    expected_width=$4
    expected_height=$5

    ensure_booted "$simulator_id"

    family_directory="$working_directory/$family"
    result_bundle="$family_directory/FrameWink-Landscape.xcresult"
    attachment_directory="$family_directory/attachments"
    derived_data="$family_directory/DerivedData"
    mkdir -p "$family_directory" "$attachment_directory" "$output_directory"
    find "$output_directory" -maxdepth 1 -type f -name '*.jpg' -delete

    xcrun simctl ui "$simulator_id" appearance light
    xcrun simctl status_bar "$simulator_id" override \
        --time "9:41" \
        --dataNetwork wifi \
        --wifiMode active \
        --wifiBars 3 \
        --batteryState discharging \
        --batteryLevel 100

    test_attempt=1
    while :; do
        rm -rf "$result_bundle"
        if xcodebuild -quiet \
            -project "$repo_root/FrameWink.xcodeproj" \
            -scheme FrameWink \
            -configuration Debug \
            -destination "platform=iOS Simulator,id=$simulator_id" \
            -derivedDataPath "$derived_data" \
            -resultBundlePath "$result_bundle" \
            -only-testing:FrameWinkUITests/MarketingLandscapeScreenshotTests/testCaptureLandscapeMarketingScreens \
            test
        then
            break
        fi
        if [ "$test_attempt" -ge 2 ]; then
            echo "$family landscape UI capture failed twice." >&2
            exit 1
        fi
        echo "$family landscape UI capture hit a transient Simulator failure; retrying once." >&2
        test_attempt=$((test_attempt + 1))
        xcrun simctl terminate "$simulator_id" media.jenny.FrameWink >/dev/null 2>&1 || true
        sleep 2
    done

    xcrun xcresulttool export attachments \
        --path "$result_bundle" \
        --output-path "$attachment_directory" >/dev/null

    if [ "$family" = ipad ]; then
        screenshot_map='01-landscape-frame:01-landscape-frame
02-landscape-mosaic:02-landscape-mosaic
03-landscape-controls:03-landscape-controls
04-landscape-review:04-landscape-review'
        expected_count=4
    else
        screenshot_map='01-landscape-frame:01-landscape-frame
03-landscape-controls:02-landscape-controls
04-landscape-review:03-landscape-review'
        expected_count=3
    fi

    while IFS=: read -r attachment_name output_name; do
        export_attachment \
            "$attachment_directory/manifest.json" \
            "$attachment_directory" \
            "$attachment_name" \
            "$output_directory/$output_name.jpg"
    done <<EOF
$screenshot_map
EOF

    screenshot_count=$(find "$output_directory" -maxdepth 1 -type f -name '*.jpg' | wc -l | tr -d ' ')
    [ "$screenshot_count" = "$expected_count" ] || {
        echo "$family produced $screenshot_count screenshots; expected $expected_count." >&2
        exit 1
    }
    for screenshot in "$output_directory"/*.jpg; do
        dimensions=$(sips -g pixelWidth -g pixelHeight "$screenshot" 2>/dev/null \
            | awk '/pixelWidth:/{width=$2}/pixelHeight:/{height=$2}END{print width "x" height}')
        [ "$dimensions" = "${expected_width}x${expected_height}" ] || {
            echo "Invalid $family landscape screenshot: $screenshot ($dimensions)" >&2
            exit 1
        }
    done
}

capture_family ipad "$ipad_simulator_id" "$ipad_output" 2752 2064
capture_family iphone "$iphone_simulator_id" "$iphone_output" 2868 1320

echo "Captured native FrameWink landscape screenshots:"
echo "  $ipad_output"
echo "  $iphone_output"
