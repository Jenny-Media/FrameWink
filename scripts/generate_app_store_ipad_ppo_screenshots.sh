#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
font_file=${FRAMEWINK_SCREENSHOT_FONT:-/System/Library/Fonts/SFNSRounded.ttf}
source_root="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPad-13-inch/Sources"
output_root="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPad-13-inch/Final"
marketing_root="$repo_root/AppStore/Screenshots/Marketing-Landscape/iPad-13-inch"
bezel_root="$repo_root/website/public/images"
contact_sheet="$repo_root/AppStore/Screenshots/Review/ContactSheets/iPad-PPO-Bezel-Proposed.jpg"
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-ipad-ppo.XXXXXX")

trap 'rm -rf "$working_directory"' EXIT

[ -n "$magick_bin" ] && [ -x "$magick_bin" ] || {
    echo "ImageMagick 7 is required (expected the 'magick' executable)." >&2
    exit 1
}
[ -f "$font_file" ] || { echo "Screenshot font not found: $font_file" >&2; exit 1; }

mkdir -p "$output_root" "$(dirname "$contact_sheet")"
find "$output_root" -maxdepth 1 -type f -name '*.jpg' -delete

render_lifestyle_scene() {
    background=$1
    bezel=$2
    destination=$3
    headline=$4
    detail=$5
    device_y=$6

    prefix="$working_directory/$(basename "$destination" .jpg)"

    "$magick_bin" "$background" -resize '2752x2064!' \
        -fill '#fff8e9e8' \
        -draw 'roundrectangle 92,230 925,1315 54,54' \
        "$prefix-background.png"

    "$magick_bin" "$bezel" -resize '1650x1265' "$prefix-ipad.png"

    "$magick_bin" -background none -fill '#111735' \
        -font "$font_file" -weight 700 -pointsize 98 \
        -kerning -2 -interline-spacing 4 -gravity northwest \
        -size '700x' "caption:$headline" \
        "$prefix-headline.png"

    "$magick_bin" -background none -fill '#555b70' \
        -font "$font_file" -weight 500 -pointsize 38 \
        -kerning 0 -interline-spacing 8 -gravity northwest \
        -size '680x' "caption:$detail" \
        "$prefix-detail.png"

    "$magick_bin" "$prefix-background.png" \
        "$prefix-ipad.png" -gravity northwest -geometry "+1005+${device_y}" -composite \
        "$prefix-headline.png" -gravity northwest -geometry '+155+380' -composite \
        "$prefix-detail.png" -gravity northwest -geometry '+160+875' -composite \
        -fill '#a93618' -font "$font_file" -weight 700 -pointsize 28 \
        -kerning 3 -gravity northwest -annotate '+160+310' \
        'FRAMEWINK · PRIVATE SMART PHOTO FRAME' \
        -fill '#666b7d' -font "$font_file" -weight 600 -pointsize 25 \
        -kerning 0 -gravity northwest -annotate '+160+1215' \
        'ACTUAL FRAMEWINK SCREEN' \
        -strip -sampling-factor 4:2:0 -quality 94 \
        "$destination"
}

render_lifestyle_scene \
    "$source_root/wall-room-v1.png" \
    "$bezel_root/ipad-flat-frame-v1.webp" \
    "$output_root/01-wall-mounted-frame.jpg" \
    $'Your photos.\nAt home on the wall.' \
    $'A calm, private photo frame made for the iPad you already own.' \
    300

render_lifestyle_scene \
    "$source_root/table-room-v1.png" \
    "$bezel_root/ipad-flat-mosaic-v1.webp" \
    "$output_root/02-tabletop-frame.jpg" \
    $'More memories.\nBeautifully arranged.' \
    $'Automatic layouts make a tabletop iPad feel at home in the room.' \
    335

cp "$marketing_root/03-review-before-display.jpg" \
    "$output_root/03-review-before-display.jpg"
cp "$marketing_root/04-automatic-album.jpg" \
    "$output_root/04-automatic-album.jpg"
cp "$marketing_root/06-storage-controls.jpg" \
    "$output_root/05-storage-controls.jpg"
cp "$marketing_root/05-landscape-controls.jpg" \
    "$output_root/06-simple-controls.jpg"
cp "$marketing_root/07-night-schedule.jpg" \
    "$output_root/07-night-schedule.jpg"
cp "$marketing_root/08-mounted-display.jpg" \
    "$output_root/08-mounted-guidance.jpg"
cp "$marketing_root/09-lifetime-upgrade.jpg" \
    "$output_root/09-lifetime-upgrade.jpg"
cp "$marketing_root/10-free-stays-useful.jpg" \
    "$output_root/10-free-stays-useful.jpg"

for screenshot in "$output_root"/*.jpg; do
    metadata=$(sips -g format -g pixelWidth -g pixelHeight -g hasAlpha "$screenshot")
    case "$metadata" in
        *"format: jpeg"*"pixelWidth: 2752"*"pixelHeight: 2064"*"hasAlpha: no"*) ;;
        *)
            echo "Invalid iPad PPO screenshot: $screenshot" >&2
            echo "$metadata" >&2
            exit 1
            ;;
    esac
done

[ "$(find "$output_root" -maxdepth 1 -type f -name '*.jpg' | wc -l | tr -d ' ')" = 10 ]

"$magick_bin" montage "$output_root"/*.jpg \
    -thumbnail '520x390' \
    -tile '5x2' \
    -geometry '+18+42' \
    -background '#ebe8df' \
    -fill '#111735' \
    -font "$font_file" \
    -pointsize 22 \
    -set label '%t' \
    -strip -quality 92 \
    "$contact_sheet"

echo "Generated the iPad Product Page Optimization screenshot treatment:"
echo "  $output_root"
echo "  $contact_sheet"
