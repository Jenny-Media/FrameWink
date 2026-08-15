#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
font_file=${FRAMEWINK_SCREENSHOT_FONT:-/System/Library/Fonts/SFNSRounded.ttf}

if [ -z "$magick_bin" ] || [ ! -x "$magick_bin" ]; then
    echo "ImageMagick 7 is required (expected the 'magick' executable)." >&2
    exit 1
fi

if [ ! -f "$font_file" ]; then
    echo "Screenshot font not found: $font_file" >&2
    exit 1
fi

iphone_source="$repo_root/AppStore/Screenshots/Submission/iPhone-6.9-inch"
ipad_source="$repo_root/AppStore/Screenshots/Submission/iPad-13-inch"
iphone_output="$repo_root/AppStore/Screenshots/Marketing/iPhone-6.9-inch"
ipad_output="$repo_root/AppStore/Screenshots/Marketing/iPad-13-inch"
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-marketing.XXXXXX")

trap 'rm -rf "$working_directory"' EXIT

mkdir -p "$iphone_output" "$ipad_output"
find "$iphone_output" "$ipad_output" -type f -name '*.jpg' -delete

iphone_files=(
    03-free-frame-mode.jpg
    07-paid-responsive-frame.jpg
    02-free-review-grid.jpg
    05-paid-automatic-album.jpg
    06-paid-frame-controls.jpg
    08-paid-night-schedule.jpg
    01-free-sample.jpg
    09-paid-display-guidance.jpg
    04-paid-lifetime-purchase.jpg
    10-paid-lifetime-features.jpg
)

iphone_names=(
    01-private-frame.jpg
    02-automatic-layouts.jpg
    03-smart-reel.jpg
    04-fresh-album.jpg
    05-simple-controls.jpg
    06-night-schedule.jpg
    07-private-by-design.jpg
    08-mounted-display.jpg
    09-lifetime-upgrade.jpg
    10-free-stays-useful.jpg
)

iphone_headlines=(
    $'Your photos.\nBeautifully framed.'
    $'Made for\nevery screen.'
    $'Review first.\nThen press play.'
    $'Choose an album.\nKeep it fresh.'
    $'Choose your pace.\nShare in a tap.'
    $'Quiet at night,\nwhile the app is open.'
    $'Your photos\nstay yours.'
    $'Mount it with\nhelpful guidance.'
    $'$4.99 once.\nNo subscription.'
    $'Try it free.\nUpgrade when ready.'
)

ipad_files=(
    03-free-frame-mode.jpg
    07-paid-mosaic-frame.jpg
    02-free-review-grid.jpg
    05-paid-automatic-album.jpg
    06-paid-frame-controls.jpg
    08-paid-night-schedule.jpg
    01-free-sample.jpg
    09-paid-commissioning-checklist.jpg
    04-paid-wall-mode-purchase.jpg
    10-paid-wall-mode-features.jpg
)

ipad_names=(
    01-private-frame.jpg
    02-automatic-layouts.jpg
    03-smart-reel.jpg
    04-fresh-album.jpg
    05-simple-controls.jpg
    06-night-schedule.jpg
    07-private-by-design.jpg
    08-mounted-display.jpg
    09-lifetime-upgrade.jpg
    10-free-stays-useful.jpg
)

ipad_headlines=(
    $'Your photos.\nBeautifully framed.'
    $'More photos,\nbeautifully arranged'
    $'Review first.\nThen press play.'
    $'Choose an album.\nKeep it fresh.'
    $'Choose your pace.\nShare in a tap.'
    $'Quiet at night,\nwhile the app is open.'
    $'Your photos\nstay yours.'
    $'Mount it with\nhelpful guidance.'
    $'$4.99 once.\nNo subscription.'
    $'Try it free.\nUpgrade when ready.'
)

backgrounds=(
    '#fff8e9' '#f2f6ea' '#fff1eb' '#edf6f6' '#fff8e9'
    '#f2f3f8' '#f2f6ea' '#edf6f6' '#fff1eb' '#fff8e9'
)

accents=(
    '#ffc94d' '#a9bf7b' '#f45e36' '#12606a' '#ffc94d'
    '#111735' '#a9bf7b' '#12606a' '#f45e36' '#ffc94d'
)

render_card() {
    family=$1
    source_file=$2
    output_file=$3
    headline=$4
    background=$5
    accent=$6
    index=$7

    if [ "$family" = iphone ]; then
        canvas_width=1320
        canvas_height=2868
        screen_width=1060
        screen_height=2301
        headline_width=1120
        headline_point_size=94
        eyebrow_point_size=30
        headline_x=96
        headline_y=142
        eyebrow_x=100
        eyebrow_y=88
        screen_x=130
        screen_y=520
    else
        canvas_width=2064
        canvas_height=2752
        screen_width=1680
        screen_height=2240
        headline_width=1740
        headline_point_size=126
        eyebrow_point_size=38
        headline_x=142
        headline_y=150
        eyebrow_x=148
        eyebrow_y=92
        screen_x=192
        screen_y=480
    fi

    prefix="$working_directory/${family}-${index}"

    "$magick_bin" -size "${canvas_width}x${canvas_height}" "xc:$background" \
        -fill "${accent}22" \
        -draw "circle $((canvas_width - canvas_width / 9)),$((canvas_height / 12)) $((canvas_width - canvas_width / 3)),$((canvas_height / 12))" \
        -fill '#1117350d' \
        -draw "rectangle $((canvas_width / 14)),$((canvas_height / 7)) $((canvas_width / 14 + canvas_width / 28)),$((canvas_height / 7 + canvas_width / 28))" \
        -fill "${accent}55" \
        -draw "rectangle $((canvas_width - canvas_width / 10)),$((canvas_height / 4)) $((canvas_width - canvas_width / 18)),$((canvas_height / 4 + canvas_width / 24))" \
        "$prefix-background.png"

    "$magick_bin" "$source_file" -auto-orient \
        -resize "${screen_width}x${screen_height}!" \
        "$prefix-screen.png"

    "$magick_bin" "$prefix-background.png" "$prefix-screen.png" \
        -gravity northwest -geometry "+${screen_x}+${screen_y}" -composite \
        "$prefix-composed.png"

    "$magick_bin" -background none -fill '#111735' \
        -font "$font_file" -weight 700 -pointsize "$headline_point_size" \
        -kerning -2 -interline-spacing 5 -gravity northwest \
        -size "${headline_width}x" "caption:$headline" \
        "$prefix-headline.png"

    "$magick_bin" "$prefix-composed.png" "$prefix-headline.png" \
        -gravity northwest -geometry "+${headline_x}+${headline_y}" -composite \
        -fill '#a93618' -font "$font_file" -weight 700 -pointsize "$eyebrow_point_size" \
        -kerning 3 -gravity northwest \
        -annotate "+${eyebrow_x}+${eyebrow_y}" 'FRAMEWINK · PRIVATE SMART PHOTO FRAME' \
        -fill '#666b7d' -font "$font_file" -weight 600 -pointsize 24 \
        -kerning 0 -gravity southeast -annotate '+72+34' \
        'ACTUAL IN-APP SCREEN' \
        -strip -sampling-factor 4:2:0 -quality 94 \
        "$output_file"
}

for index in "${!iphone_files[@]}"; do
    render_card iphone \
        "$iphone_source/${iphone_files[$index]}" \
        "$iphone_output/${iphone_names[$index]}" \
        "${iphone_headlines[$index]}" \
        "${backgrounds[$index]}" \
        "${accents[$index]}" \
        "$index"
done

for index in "${!ipad_files[@]}"; do
    render_card ipad \
        "$ipad_source/${ipad_files[$index]}" \
        "$ipad_output/${ipad_names[$index]}" \
        "${ipad_headlines[$index]}" \
        "${backgrounds[$index]}" \
        "${accents[$index]}" \
        "$index"
done

for screenshot in "$iphone_output"/*.jpg; do
    dimensions=$(sips -g pixelWidth -g pixelHeight "$screenshot" 2>/dev/null | awk '/pixelWidth:/{width=$2}/pixelHeight:/{height=$2}END{print width "x" height}')
    [ "$dimensions" = '1320x2868' ] || { echo "Invalid iPhone marketing screenshot: $screenshot ($dimensions)" >&2; exit 1; }
done

for screenshot in "$ipad_output"/*.jpg; do
    dimensions=$(sips -g pixelWidth -g pixelHeight "$screenshot" 2>/dev/null | awk '/pixelWidth:/{width=$2}/pixelHeight:/{height=$2}END{print width "x" height}')
    [ "$dimensions" = '2064x2752' ] || { echo "Invalid iPad marketing screenshot: $screenshot ($dimensions)" >&2; exit 1; }
done

[ "$(find "$iphone_output" -type f -name '*.jpg' | wc -l | tr -d ' ')" = 10 ]
[ "$(find "$ipad_output" -type f -name '*.jpg' | wc -l | tr -d ' ')" = 10 ]

echo "Generated FrameWink marketing screenshot candidates:"
echo "  $iphone_output"
echo "  $ipad_output"
