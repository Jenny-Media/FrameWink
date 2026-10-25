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
iphone_ppo_dir="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPhone-6.9-inch/Final"
duo_dir="$repo_root/AppStore/Version-1.6/Screenshots/iPhone-Duo"
ipad_ppo_dir="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPad-13-inch/Final"
release_artwork_dir="$repo_root/AppStore/Version-1.6.1/Screenshots"
release_capture_dir="$repo_root/AppStore/Version-1.6.1/CaptureSources"
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

# Source libraries and final galleries have separate explicit inventories. The
# eleven-image iPad landscape library is not an eleven-image upload gallery.
validate_inventory() {
    directory=$1
    shift

    [ -d "$directory" ] || fail "missing $directory"
    actual_count=$(find "$directory" -maxdepth 1 -type f -name '*.jpg' | wc -l | tr -d ' ')
    [ "$actual_count" = "$#" ] \
        || fail "$directory contains $actual_count JPEGs; expected $#"

    for filename in "$@"; do
        [ -f "$directory/$filename" ] || fail "missing $directory/$filename"
    done

    unique_count=$(find "$directory" -maxdepth 1 -type f -name '*.jpg' -exec shasum -a 256 {} \; \
        | awk '{ print $1 }' | sort -u | wc -l | tr -d ' ')
    [ "$unique_count" = "$actual_count" ] \
        || fail "$directory contains duplicate screenshot files"
}

validate_screenshot_set() {
    directory=$1
    expected_width=$2
    expected_height=$3
    shift 3

    validate_inventory "$directory" "$@"
    for filename in "$@"; do
        validate_raster "$directory/$filename" "$expected_width" "$expected_height"
    done
}

validate_screenshot_set "$iphone_dir" 1320 2868 \
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

validate_screenshot_set "$ipad_dir" 2064 2752 \
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

validate_screenshot_set "$iphone_marketing_dir" 1320 2868 \
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

validate_screenshot_set "$ipad_marketing_dir" 2064 2752 \
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

validate_screenshot_set "$iphone_landscape_dir" 2868 1320 \
    01-landscape-frame.jpg \
    02-landscape-controls.jpg \
    03-landscape-review.jpg

validate_screenshot_set "$ipad_landscape_dir" 2752 2064 \
    01-landscape-frame.jpg \
    02-landscape-mosaic.jpg \
    03-landscape-review.jpg \
    04-landscape-album-picker.jpg \
    05-landscape-controls.jpg \
    06-landscape-privacy-data.jpg \
    07-landscape-night-schedule.jpg \
    08-landscape-mounted-tips.jpg \
    09-landscape-lifetime-purchase.jpg \
    10-landscape-lifetime-features.jpg \
    11-landscape-sample-setup.jpg

validate_screenshot_set "$iphone_landscape_marketing_dir" 2868 1320 \
    01-private-iphone-frame.jpg \
    02-landscape-controls.jpg \
    03-review-before-display.jpg

validate_screenshot_set "$ipad_landscape_marketing_dir" 2752 2064 \
    01-private-ipad-frame.jpg \
    02-automatic-landscape-layouts.jpg \
    03-review-before-display.jpg \
    04-automatic-album.jpg \
    05-landscape-controls.jpg \
    06-storage-controls.jpg \
    07-night-schedule.jpg \
    08-mounted-display.jpg \
    09-lifetime-upgrade.jpg \
    10-free-stays-useful.jpg

# Validate both approved baselines and the version-specific build-80 review set.
for gallery_root in "$iphone_ppo_dir" "$release_artwork_dir/iPhone-6.9-inch"; do
    validate_screenshot_set "$gallery_root" 1320 2868 \
        01-beautifully-framed.jpg \
        02-made-for-every-screen.jpg \
        03-choose-an-album.jpg \
        04-portrait-or-landscape.jpg \
        05-simple-controls.jpg \
        06-see-it-first.jpg
done

for gallery_root in "$ipad_ppo_dir" "$release_artwork_dir/iPad-13-inch"; do
    validate_screenshot_set "$gallery_root" 2752 2064 \
        01-beautifully-framed.jpg \
        02-wall-or-table.jpg \
        03-beautifully-framed.jpg \
        04-beautifully-arranged.jpg \
        05-choose-an-album.jpg \
        06-simple-controls.jpg \
        07-see-it-first.jpg
done

for gallery_root in "$duo_dir" "$release_artwork_dir/iPhone-Duo"; do
    # Duo card 4 uses the approved closed-display size; the other five use open.
    validate_inventory "$gallery_root" \
        01-your-photos-beautifully-framed.jpg \
        02-open-to-a-bigger-frame.jpg \
        03-choose-an-album.jpg \
        04-open-or-closed.jpg \
        05-simple-timing.jpg \
        06-see-it-first.jpg
    for screenshot in "$gallery_root"/*.jpg; do
            case "$(basename "$screenshot")" in
                04-open-or-closed.jpg) validate_raster "$screenshot" 1398 2034 ;;
                *) validate_raster "$screenshot" 2007 2853 ;;
            esac
    done
done

validate_raster "$iap_review" 1242 2688
validate_raster "$icon" 1024 1024
jq empty "$icon_contents"
jq -e '.images | any(.filename == "AppIcon-1024.png" and .idiom == "universal" and .platform == "ios" and .size == "1024x1024")' \
    "$icon_contents" >/dev/null \
    || fail "AppIcon Contents.json does not reference the universal 1024px iOS master"

# Also enforce the existing approvals, including the six current Duo cards.
bash "$repo_root/scripts/verify_locked_app_store_screenshots.sh"

# Candidate checksums record reproducibility, not a new artwork approval.
(cd "$release_artwork_dir" && shasum -a 256 -c SHA256SUMS)
(cd "$release_capture_dir" && shasum -a 256 -c SHA256SUMS)

echo "FrameWink App Store assets are valid (105 screenshots, IAP review and icon; 19 build-80 review cards)."
