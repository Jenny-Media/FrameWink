#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
xcode_developer_dir=${FRAMEWINK_XCODE_DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}
simulator_id=${FRAMEWINK_IPAD_LANDSCAPE_SIMULATOR_ID:-1BDA7ABF-4236-406E-8ACD-7E3B10569753}
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-website-pair.XXXXXX")
result_bundle="$working_directory/FrameWink-Website-Pair.xcresult"
attachment_directory="$working_directory/attachments"
derived_data="$working_directory/DerivedData"
booted_by_script=""

export DEVELOPER_DIR="$xcode_developer_dir"

cleanup() {
    xcrun simctl status_bar "$simulator_id" clear >/dev/null 2>&1 || true
    if [ -n "$booted_by_script" ]; then
        xcrun simctl shutdown "$simulator_id" >/dev/null 2>&1 || true
    fi
    rm -rf "$working_directory"
}
trap cleanup EXIT INT TERM

for tool in jq magick; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "Required tool is unavailable: $tool" >&2
        exit 1
    }
done

simulator_line=$(xcrun simctl list devices | sed -n "/($simulator_id)/p" | head -1)
[ -n "$simulator_line" ] || {
    echo "Simulator is unavailable: $simulator_id" >&2
    exit 1
}
case "$simulator_line" in
    *"(Booted)"*) ;;
    *)
        xcrun simctl boot "$simulator_id"
        booted_by_script="1"
        ;;
esac
xcrun simctl bootstatus "$simulator_id" -b
xcrun simctl ui "$simulator_id" appearance light
xcrun simctl status_bar "$simulator_id" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --batteryState discharging \
    --batteryLevel 100

mkdir -p "$attachment_directory" "$repo_root/website/public/images"
xcodebuild -quiet \
    -project "$repo_root/FrameWink.xcodeproj" \
    -scheme FrameWink \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath "$derived_data" \
    -resultBundlePath "$result_bundle" \
    -only-testing:FrameWinkUITests/MarketingLandscapeScreenshotTests/testCaptureWebsiteFrameScreens \
    test

xcrun xcresulttool export attachments \
    --path "$result_bundle" \
    --output-path "$attachment_directory" >/dev/null

for capture_name in frame mosaic pair; do
    case "$capture_name" in
        frame) output="$repo_root/website/public/images/ipad-landscape-frame-clean-v2.webp" ;;
        mosaic) output="$repo_root/website/public/images/ipad-landscape-mosaic-clean-v2.webp" ;;
        pair) output="$repo_root/website/public/images/ipad-landscape-pair-clean-v1.webp" ;;
    esac
    exported_filename=$(jq -r --arg prefix "website-landscape-${capture_name}_" '
        .[].attachments[]
        | select(.suggestedHumanReadableName | startswith($prefix))
        | .exportedFileName
    ' "$attachment_directory/manifest.json")
    [ -n "$exported_filename" ] && [ "$exported_filename" != null ] || {
        echo "Missing website ${capture_name} screenshot attachment." >&2
        exit 1
    }

    # XCUIScreen exports the landscape device buffer in its natural portrait
    # orientation. Rotate once, then create the bounded website source derivative.
    magick "$attachment_directory/$exported_filename" \
        -rotate -90 \
        -resize '1600x1200!' \
        -strip \
        -quality 86 \
        "$output"

    dimensions=$(identify -format '%wx%h' "$output")
    [ "$dimensions" = "1600x1200" ] || {
        echo "Invalid website ${capture_name} screenshot dimensions: $dimensions" >&2
        exit 1
    }
    echo "Captured the native FrameWink ${capture_name} iPad screen:"
    echo "  $output"
done
