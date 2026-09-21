#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
font_file=${FRAMEWINK_SCREENSHOT_FONT:-/System/Library/Fonts/SFNSRounded.ttf}
source_root="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPad-13-inch/Sources"
output_root="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPad-13-inch/Final"
capture_root="$repo_root/AppStore/Screenshots/Landscape/iPad-13-inch"
sample_photo="$repo_root/FrameWink/Resources/SamplePhotos/sample-yellowstone-falls.jpg"
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

make_headline() {
    local text=$1
    local width=$2
    local size=$3
    local destination=$4

    "$magick_bin" -background none -fill '#171719' \
        -font "$font_file" -weight 700 -pointsize "$size" \
        -kerning -2 -interline-spacing 5 -gravity northwest \
        -size "${width}x" "caption:$text" "$destination"
}

render_wall_scene() {
    local destination=$1
    local prefix="$working_directory/wall"

    "$magick_bin" "$sample_photo" -resize '168x119^' \
        -gravity center -extent '168x119' \
        \( +clone -alpha extract -fill black -colorize 100 \
           -fill white -draw 'roundrectangle 0,0 167,118 8,8' \) \
        -alpha off -compose CopyOpacity -composite "$prefix-screen.png"
    "$magick_bin" "$source_root/wall-integrated-v1.png" \
        "$prefix-screen.png" -geometry '+932+306' -compose over -composite \
        -resize '2752x2064!' "$prefix-background.png"
    make_headline $'Your photos.\nBeautifully framed.' 940 116 \
        "$prefix-headline.png"

    "$magick_bin" "$prefix-background.png" \
        "$prefix-headline.png" -gravity northwest -geometry '+165+150' -composite \
        -strip -sampling-factor 4:2:0 -quality 94 "$destination"
}

render_table_scene() {
    local destination=$1
    local prefix="$working_directory/table"

    "$magick_bin" "$sample_photo" -resize '320x240^' \
        -gravity center -extent '320x240' \
        \( +clone -alpha extract -fill black -colorize 100 \
           -fill white -draw 'roundrectangle 0,0 319,239 12,12' \) \
        -alpha off -compose CopyOpacity -composite -alpha set \
        -virtual-pixel transparent \
        -set option:distort:viewport '1448x1086+0+0' \
        -distort Perspective \
        '0,0 423,428 320,0 730,422 320,240 773,649 0,240 453,659' \
        "$prefix-screen.png"
    "$magick_bin" "$source_root/table-integrated-v1.png" \
        "$prefix-screen.png" -compose over -composite \
        -resize '2752x2064!' "$prefix-background.png"
    make_headline $'At home on a wall\nor table.' 920 112 \
        "$prefix-headline.png"

    "$magick_bin" "$prefix-background.png" \
        "$prefix-headline.png" -gravity northwest -geometry '+150+130' -composite \
        -strip -sampling-factor 4:2:0 -quality 94 "$destination"
}

make_focused_screen() {
    local source=$1
    local modal_geometry=$2
    local modal_position=$3
    local destination=$4
    local prefix="$working_directory/focus-$(basename "$destination" .png)"

    "$magick_bin" "$source" -blur '0x28' -modulate '72,82,100' \
        "$prefix-background.png"
    "$magick_bin" "$source" -crop "$modal_geometry" +repage \
        "$prefix-modal.png"
    "$magick_bin" "$prefix-background.png" "$prefix-modal.png" \
        -geometry "$modal_position" -compose over -composite "$destination"
}

render_close_scene() {
    local source=$1
    local destination=$2
    local headline=$3
    local prefix="$working_directory/$(basename "$destination" .jpg)"

    "$magick_bin" "$source" -resize '1000x750!' \
        \( +clone -alpha extract -fill black -colorize 100 \
           -fill white -draw 'roundrectangle 0,0 999,749 36,36' \) \
        -alpha off -compose CopyOpacity -composite -alpha set \
        -virtual-pixel transparent \
        -set option:distort:viewport '1448x1086+0+0' \
        -distort Perspective \
        '0,0 365,294 1000,0 969,281 1000,750 1040,729 0,750 423,770' \
        "$prefix-screen.png"
    "$magick_bin" "$source_root/table-close-integrated-v1.png" \
        "$prefix-screen.png" -compose over -composite \
        -resize '2752x2064!' "$prefix-background.png"
    make_headline "$headline" 1100 104 "$prefix-headline.png"

    "$magick_bin" "$prefix-background.png" \
        "$prefix-headline.png" -gravity northwest -geometry '+430+115' -composite \
        -strip -sampling-factor 4:2:0 -quality 94 "$destination"
}

render_wall_scene "$output_root/01-beautifully-framed.jpg"
render_table_scene "$output_root/02-wall-or-table.jpg"
make_focused_screen \
    "$capture_root/04-landscape-album-picker.jpg" \
    '1160x1290+795+390' '+795+390' \
    "$working_directory/album-focused.png"
make_focused_screen \
    "$capture_root/03-landscape-review.jpg" \
    '1160x1300+795+390' '+795+390' \
    "$working_directory/review-focused.png"
render_close_scene \
    "$working_directory/album-focused.png" \
    "$output_root/03-choose-an-album.jpg" \
    $'Choose an album.\nFrameWink keeps it fresh.'
render_close_scene \
    "$capture_root/02-landscape-mosaic.jpg" \
    "$output_root/04-smart-highlights.jpg" \
    $'Smart highlights.\nBeautifully arranged.'
render_close_scene \
    "$working_directory/review-focused.png" \
    "$output_root/05-review-before-display.jpg" \
    $'Review every photo.\nYou decide what plays.'
render_close_scene \
    "$capture_root/01-landscape-frame.jpg" \
    "$output_root/06-private-by-design.jpg" \
    $'Private by design.\nYour photos stay\non your device.'

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

[ "$(find "$output_root" -maxdepth 1 -type f -name '*.jpg' | wc -l | tr -d ' ')" = 6 ]

"$magick_bin" montage "$output_root"/*.jpg \
    -thumbnail '620x465' -tile '3x2' -geometry '+22+52' \
    -background '#ebe8df' -fill '#111735' -font "$font_file" \
    -pointsize 24 -set label '%t' -strip -quality 92 "$contact_sheet"

echo "Generated the cohesive six-image iPad screenshot treatment:"
echo "  $output_root"
echo "  $contact_sheet"
