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

render_benefit_card() {
    local source=$1
    local destination=$2
    local headline=$3
    local background=$4
    local accent=$5
    local prefix="$working_directory/$(basename "$destination" .jpg)"

    "$magick_bin" -size '2752x2064' "xc:$background" \
        -fill "${accent}24" -draw 'circle 150,1940 500,1940' \
        -fill '#1717190d' -draw 'rectangle 760,0 762,2064' \
        "$prefix-background.png"
    "$magick_bin" "$source" -resize '1810x1358!' \
        -bordercolor '#ffffff' -border 18 \
        -background black -shadow '28x10+0+12' "$prefix-shadow.png"
    "$magick_bin" "$source" -resize '1810x1358!' \
        -bordercolor '#ffffff' -border 18 "$prefix-screen.png"
    make_headline "$headline" 620 94 "$prefix-headline.png"

    "$magick_bin" "$prefix-background.png" \
        "$prefix-shadow.png" -gravity northwest -geometry '+860+355' -composite \
        "$prefix-screen.png" -gravity northwest -geometry '+860+337' -composite \
        "$prefix-headline.png" -gravity northwest -geometry '+105+255' -composite \
        -fill '#a93618' -font "$font_file" -weight 700 -pointsize 28 \
        -kerning 3 -gravity northwest -annotate '+110+145' 'FRAMEWINK' \
        -strip -sampling-factor 4:2:0 -quality 94 "$destination"
}

render_wall_scene "$output_root/01-beautifully-framed.jpg"
render_table_scene "$output_root/02-wall-or-table.jpg"
render_benefit_card \
    "$capture_root/04-landscape-album-picker.jpg" \
    "$output_root/03-choose-an-album.jpg" \
    $'Choose an album.\nKeep it fresh.' '#edf6f6' '#12606a'
render_benefit_card \
    "$capture_root/02-landscape-mosaic.jpg" \
    "$output_root/04-smart-highlights.jpg" \
    $'Beautiful highlights.\nChosen on\nyour device.' '#fff8e9' '#ffc94d'
render_benefit_card \
    "$capture_root/03-landscape-review.jpg" \
    "$output_root/05-review-before-display.jpg" \
    $'Review every photo.\nThen press play.' '#fff1eb' '#f45e36'
render_benefit_card \
    "$capture_root/01-landscape-frame.jpg" \
    "$output_root/06-private-by-design.jpg" \
    $'No account.\nNo ads.\nNo tracking.' '#f2f6ea' '#a9bf7b'

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
