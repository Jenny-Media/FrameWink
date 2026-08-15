#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
font_file=${FRAMEWINK_SCREENSHOT_FONT:-/System/Library/Fonts/SFNSRounded.ttf}
ipad_source="$repo_root/AppStore/Screenshots/Landscape/iPad-13-inch"
iphone_source="$repo_root/AppStore/Screenshots/Landscape/iPhone-6.9-inch"
iphone_portrait_source="$repo_root/AppStore/Screenshots/Submission/iPhone-6.9-inch"
ipad_output="$repo_root/AppStore/Screenshots/Marketing-Landscape/iPad-13-inch"
iphone_output="$repo_root/AppStore/Screenshots/Marketing-Landscape/iPhone-6.9-inch"
website_images="$repo_root/website/public/images"
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-landscape-marketing.XXXXXX")

trap 'rm -rf "$working_directory"' EXIT

[ -n "$magick_bin" ] && [ -x "$magick_bin" ] || {
    echo "ImageMagick 7 is required (expected the 'magick' executable)." >&2
    exit 1
}
[ -f "$font_file" ] || { echo "Screenshot font not found: $font_file" >&2; exit 1; }

mkdir -p "$ipad_output" "$iphone_output" "$website_images"
find "$ipad_output" "$iphone_output" -maxdepth 1 -type f -name '*.jpg' -delete

render_card() {
    family=$1
    source=$2
    destination=$3
    headline=$4
    background=$5
    accent=$6

    if [ "$family" = ipad ]; then
        canvas_width=2752
        canvas_height=2064
        copy_width=760
        screen_width=1992
        screen_height=1494
        headline_width=610
        headline_size=104
        eyebrow_size=30
        screen_x=760
        screen_y=285
    else
        canvas_width=2868
        canvas_height=1320
        copy_width=900
        screen_width=1968
        screen_height=906
        headline_width=700
        headline_size=94
        eyebrow_size=28
        screen_x=900
        screen_y=207
    fi

    prefix="$working_directory/${family}-$(basename "$destination" .jpg)"

    "$magick_bin" -size "${canvas_width}x${canvas_height}" "xc:$background" \
        -fill "${accent}22" \
        -draw "circle 120,$((canvas_height - 90)) 430,$((canvas_height - 90))" \
        -fill '#1117350d' \
        -draw "rectangle $((copy_width - 1)),0 $copy_width,$canvas_height" \
        "$prefix-background.png"

    "$magick_bin" "$source" -resize "${screen_width}x${screen_height}!" \
        "$prefix-screen.png"

    "$magick_bin" "$prefix-background.png" "$prefix-screen.png" \
        -geometry "+${screen_x}+${screen_y}" -composite \
        "$prefix-composed.png"

    "$magick_bin" -background none -fill '#111735' \
        -font "$font_file" -weight 700 -pointsize "$headline_size" \
        -kerning -2 -interline-spacing 4 -gravity northwest \
        -size "${headline_width}x" "caption:$headline" \
        "$prefix-headline.png"

    "$magick_bin" "$prefix-composed.png" "$prefix-headline.png" \
        -gravity northwest -geometry "+96+250" -composite \
        -fill '#a93618' -font "$font_file" -weight 700 -pointsize "$eyebrow_size" \
        -kerning 3 -gravity northwest -annotate '+100+132' \
        'FRAMEWINK · PRIVATE SMART PHOTO FRAME' \
        -fill '#666b7d' -font "$font_file" -weight 600 -pointsize 28 \
        -kerning 0 -gravity southwest -annotate '+100+90' \
        'ACTUAL IN-APP SCREEN · PHOTOS STAY ON THIS DEVICE' \
        -strip -sampling-factor 4:2:0 -quality 94 "$destination"
}

render_card ipad "$ipad_source/01-landscape-frame.jpg" \
    "$ipad_output/01-private-ipad-frame.jpg" \
    $'Your photos.\nBeautifully framed.' '#fff8e9' '#ffc94d'
render_card ipad "$ipad_source/02-landscape-mosaic.jpg" \
    "$ipad_output/02-automatic-landscape-layouts.jpg" \
    $'More photos,\nbeautifully arranged' '#f2f6ea' '#a9bf7b'
render_card ipad "$ipad_source/03-landscape-review.jpg" \
    "$ipad_output/03-review-before-display.jpg" \
    $'Review first.\nEnjoy with confidence.' '#fff1eb' '#f45e36'
render_card ipad "$ipad_source/04-landscape-album-picker.jpg" \
    "$ipad_output/04-automatic-album.jpg" \
    $'Choose an album.\nKeep it fresh.' '#edf6f6' '#12606a'
render_card ipad "$ipad_source/05-landscape-controls.jpg" \
    "$ipad_output/05-landscape-controls.jpg" \
    $'Simple timing.\nDirect sharing.' '#fff8e9' '#ffc94d'
render_card ipad "$ipad_source/06-landscape-sample.jpg" \
    "$ipad_output/06-sample-before-access.jpg" \
    $'See it first.\nChoose photos later.' '#f2f6ea' '#a9bf7b'
render_card ipad "$ipad_source/07-landscape-night-schedule.jpg" \
    "$ipad_output/07-night-schedule.jpg" \
    $'Quiet at night,\nwhile the app is open.' '#eef0f6' '#111735'
render_card ipad "$ipad_source/08-landscape-mounted-tips.jpg" \
    "$ipad_output/08-mounted-display.jpg" \
    $'Mounted iPad\ntips included.' '#edf6f6' '#12606a'
render_card ipad "$ipad_source/09-landscape-lifetime-purchase.jpg" \
    "$ipad_output/09-lifetime-upgrade.jpg" \
    $'Just $4.99.\nNo subscription.' '#fff1eb' '#f45e36'
render_card ipad "$ipad_source/10-landscape-lifetime-features.jpg" \
    "$ipad_output/10-free-stays-useful.jpg" \
    $'Free stays useful.\nUpgrade when ready.' '#fff8e9' '#ffc94d'

render_card iphone "$iphone_source/01-landscape-frame.jpg" \
    "$iphone_output/01-private-iphone-frame.jpg" \
    $'A private frame\nfor any room.' '#fff8e9' '#ffc94d'
render_card iphone "$iphone_source/02-landscape-controls.jpg" \
    "$iphone_output/02-landscape-controls.jpg" \
    $'Simple controls.\nNothing to learn.' '#edf6f6' '#12606a'
render_card iphone "$iphone_source/03-landscape-review.jpg" \
    "$iphone_output/03-review-before-display.jpg" \
    $'Review first.\nThen press play.' '#fff1eb' '#f45e36'

copy_website_image() {
    source=$1
    destination=$2
    "$magick_bin" "$source" -resize '1600x1200!' -strip -quality 86 "$destination"
}

copy_website_image "$ipad_source/01-landscape-frame.jpg" \
    "$website_images/ipad-landscape-frame-clean-v2.webp"
copy_website_image "$ipad_source/02-landscape-mosaic.jpg" \
    "$website_images/ipad-landscape-mosaic-clean-v2.webp"
copy_website_image "$ipad_source/03-landscape-review.jpg" \
    "$website_images/ipad-landscape-review-v2.webp"
copy_website_image "$ipad_source/05-landscape-controls.jpg" \
    "$website_images/ipad-landscape-controls-v3.webp"
for source_name in frame controls review; do
    source_file=$(find "$iphone_source" -maxdepth 1 -type f -name "*-${source_name}.jpg" | head -1)
    "$magick_bin" "$source_file" -resize '1600x736!' -strip -quality 86 \
        "$website_images/iphone-landscape-${source_name}.webp"
done

"$magick_bin" "$iphone_portrait_source/03-free-frame-mode.jpg" \
    -resize '660x1434!' -strip -quality 86 \
    "$website_images/iphone-portrait-single-clean-v2.webp"
"$magick_bin" "$iphone_portrait_source/06-paid-frame-controls.jpg" \
    -resize '660x1434!' -strip -quality 86 \
    "$website_images/iphone-portrait-controls.webp"
"$magick_bin" "$iphone_portrait_source/02-free-review-grid.jpg" \
    -resize '660x1434!' -strip -quality 86 \
    "$website_images/iphone-portrait-review-v2.webp"
"$magick_bin" "$iphone_portrait_source/07-paid-responsive-frame.jpg" \
    -resize '660x1434!' -strip -quality 86 \
    "$website_images/iphone-portrait-tower-clean-v1.webp"

echo "Generated landscape App Store and website assets:"
echo "  $ipad_output"
echo "  $iphone_output"
echo "  $website_images"
