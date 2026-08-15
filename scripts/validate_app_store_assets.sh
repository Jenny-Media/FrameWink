#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
iphone_dir="$repo_root/AppStore/Screenshots/Submission/iPhone-6.9-inch"
ipad_dir="$repo_root/AppStore/Screenshots/Submission/iPad-13-inch"
iphone_marketing_dir="$repo_root/AppStore/Screenshots/Marketing/iPhone-6.9-inch"
ipad_marketing_dir="$repo_root/AppStore/Screenshots/Marketing/iPad-13-inch"
iphone_landscape_dir="$repo_root/AppStore/Screenshots/Landscape/iPhone-6.9-inch"
ipad_landscape_dir="$repo_root/AppStore/Screenshots/Landscape/iPad-13-inch"
iphone_landscape_marketing_dir="$repo_root/AppStore/Screenshots/Marketing-Landscape/iPhone-6.9-inch"
ipad_landscape_marketing_dir="$repo_root/AppStore/Screenshots/Marketing-Landscape/iPad-13-inch"
iap_review="$repo_root/AppStore/Screenshots/Review/IAP/FrameWink-Lifetime-review-1242x2688.jpg"
icon="$repo_root/FrameWink/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
icon_contents="$repo_root/FrameWink/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json"

fail() {
    echo "FrameWink App Store asset validation failed: $*" >&2
    exit 1
}

property() {
    file=$1
    name=$2
    sips -g "$name" "$file" 2>/dev/null | awk -v property="$name" '$1 == property ":" { print $2 }'
}

validate_raster() {
    file=$1
    expected_width=$2
    expected_height=$3

    [ -f "$file" ] || fail "missing $file"
    width=$(property "$file" pixelWidth)
    height=$(property "$file" pixelHeight)
    alpha=$(property "$file" hasAlpha)

    [ "$width" = "$expected_width" ] \
        || fail "$(basename "$file") is ${width}px wide; expected ${expected_width}px"
    [ "$height" = "$expected_height" ] \
        || fail "$(basename "$file") is ${height}px high; expected ${expected_height}px"
    [ "$alpha" = "no" ] \
        || fail "$(basename "$file") contains an alpha channel"
}

validate_submission_set() {
    directory=$1
    expected_width=$2
    expected_height=$3
    shift 3

    actual_count=$(find "$directory" -maxdepth 1 -type f -name '*.jpg' | wc -l | tr -d ' ')
    [ "$actual_count" = "$#" ] \
        || fail "$directory contains $actual_count JPEGs; expected $#"

    for filename in "$@"; do
        validate_raster "$directory/$filename" "$expected_width" "$expected_height"
    done

    unique_count=$(find "$directory" -maxdepth 1 -type f -name '*.jpg' -exec shasum -a 256 {} \; \
        | awk '{ print $1 }' | sort -u | wc -l | tr -d ' ')
    [ "$unique_count" = "$actual_count" ] \
        || fail "$directory contains duplicate screenshot files"
}

validate_submission_set "$iphone_dir" 1320 2868 \
    01-free-sample.jpg \
    02-free-review-grid.jpg \
    03-free-frame-mode.jpg \
    04-paid-lifetime-purchase.jpg \
    05-paid-automatic-album.jpg \
    06-paid-frame-controls.jpg \
    07-paid-responsive-frame.jpg \
    08-paid-night-schedule.jpg \
    09-paid-display-guidance.jpg \
    10-paid-lifetime-features.jpg

validate_submission_set "$ipad_dir" 2064 2752 \
    01-free-sample.jpg \
    02-free-review-grid.jpg \
    03-free-frame-mode.jpg \
    04-paid-wall-mode-purchase.jpg \
    05-paid-automatic-album.jpg \
    06-paid-frame-controls.jpg \
    07-paid-mosaic-frame.jpg \
    08-paid-night-schedule.jpg \
    09-paid-commissioning-checklist.jpg \
    10-paid-wall-mode-features.jpg

validate_submission_set "$iphone_marketing_dir" 1320 2868 \
    01-private-frame.jpg \
    02-automatic-layouts.jpg \
    03-smart-reel.jpg \
    04-fresh-album.jpg \
    05-simple-controls.jpg \
    06-night-schedule.jpg \
    07-private-by-design.jpg \
    08-mounted-display.jpg \
    09-lifetime-upgrade.jpg \
    10-free-stays-useful.jpg

validate_submission_set "$ipad_marketing_dir" 2064 2752 \
    01-private-frame.jpg \
    02-automatic-layouts.jpg \
    03-smart-reel.jpg \
    04-fresh-album.jpg \
    05-simple-controls.jpg \
    06-night-schedule.jpg \
    07-private-by-design.jpg \
    08-mounted-display.jpg \
    09-lifetime-upgrade.jpg \
    10-free-stays-useful.jpg

validate_submission_set "$iphone_landscape_dir" 2868 1320 \
    01-landscape-frame.jpg \
    02-landscape-controls.jpg \
    03-landscape-review.jpg

validate_submission_set "$ipad_landscape_dir" 2752 2064 \
    01-landscape-frame.jpg \
    02-landscape-mosaic.jpg \
    03-landscape-controls.jpg \
    04-landscape-review.jpg

validate_submission_set "$iphone_landscape_marketing_dir" 2868 1320 \
    01-private-iphone-frame.jpg \
    02-landscape-controls.jpg \
    03-review-before-display.jpg

validate_submission_set "$ipad_landscape_marketing_dir" 2752 2064 \
    01-private-ipad-frame.jpg \
    02-automatic-landscape-layouts.jpg \
    03-landscape-controls.jpg \
    04-review-before-display.jpg

validate_raster "$iap_review" 1242 2688
validate_raster "$icon" 1024 1024
jq empty "$icon_contents"
jq -e '.images | any(.filename == "AppIcon-1024.png" and .idiom == "universal" and .platform == "ios" and .size == "1024x1024")' \
    "$icon_contents" >/dev/null \
    || fail "AppIcon Contents.json does not reference the universal 1024px iOS master"

echo "FrameWink App Store assets are valid."
