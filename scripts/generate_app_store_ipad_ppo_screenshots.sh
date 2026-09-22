#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
font_file=${FRAMEWINK_SCREENSHOT_FONT:-/System/Library/Fonts/SFNSRounded.ttf}
source_root="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPad-13-inch/Sources"
output_root="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPad-13-inch/Final"
capture_root="$repo_root/AppStore/Screenshots/Landscape/iPad-13-inch"
sample_photo="$repo_root/FrameWink/Resources/SamplePhotos/sample-yellowstone-falls.jpg"
product_background="$source_root/wall-closeup-v3.png"
official_ipad=${FRAMEWINK_IPAD_BEZEL:-'/Volumes/Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 13" - Space Black - Landscape.png'}
contact_sheet="$repo_root/AppStore/Screenshots/Review/ContactSheets/iPad-PPO-Bezel-Proposed.jpg"
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-ipad-ppo.XXXXXX")

trap 'rm -rf "$working_directory"' EXIT

[ -n "$magick_bin" ] && [ -x "$magick_bin" ] || {
    echo "ImageMagick 7 is required." >&2
    exit 1
}
[ -f "$font_file" ] || { echo "Screenshot font not found: $font_file" >&2; exit 1; }
[ -f "$product_background" ] || { echo "Product background not found: $product_background" >&2; exit 1; }
[ -f "$official_ipad" ] || { echo "Official Apple iPad bezel not found: $official_ipad" >&2; exit 1; }
[ "$("$magick_bin" identify -format '%wx%h' "$official_ipad")" = '3000x2300' ] || {
    echo "Expected Apple's original 3000x2300 iPad bezel." >&2
    exit 1
}

mkdir -p "$output_root" "$(dirname "$contact_sheet")"
find "$output_root" -maxdepth 1 -type f -name '*.jpg' -delete

make_eyebrow() {
    "$magick_bin" -background none -fill '#a8513e' \
        -font "$font_file" -weight 700 -pointsize 27 \
        -kerning 2 -gravity northwest -size '620x' \
        'caption:FRAMEWINK · PRIVATE SMART PHOTO FRAME' "$1"
}

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

make_official_ipad() {
    local screen=$1
    local destination=$2
    local prefix="$working_directory/$(basename "$destination" .png)"

    "$magick_bin" "$screen" -auto-orient -resize '2752x2064^' \
        -gravity center -extent '2752x2064' "$prefix-fitted.png"
    "$magick_bin" -size '2752x2064' xc:none -fill white -stroke none \
        -draw 'roundrectangle 0,0 2751,2063 48,48' "$prefix-mask.png"
    "$magick_bin" "$prefix-fitted.png" "$prefix-mask.png" \
        -alpha off -compose CopyOpacity -composite "$prefix-screen.png"
    "$magick_bin" -size '3000x2300' xc:none \
        "$prefix-screen.png" -geometry '+124+118' -compose over -composite \
        "$official_ipad" -geometry '+0+0' -compose over -composite \
        -resize '2050x' "$prefix-device.png"
    "$magick_bin" "$prefix-device.png" \
        \( +clone -background '#3e291f55' -shadow '28x14+0+24' \) \
        +swap -background none -layers merge +repage "$destination"
}

render_product() {
    local screen=$1
    local destination=$2
    local headline=$3
    local prefix="$working_directory/$(basename "$destination" .jpg)"

    "$magick_bin" "$product_background" -resize '2752x2064!' \
        -channel R -evaluate subtract 3.5% \
        -channel G -evaluate add 1.6% \
        -channel B -evaluate add 5.1% +channel \
        "$prefix-background.png"
    make_official_ipad "$screen" "$prefix-device-shadow.png"
    make_eyebrow "$prefix-eyebrow.png"
    make_headline "$headline" 600 98 "$prefix-headline.png"

    "$magick_bin" "$prefix-background.png" \
        "$prefix-eyebrow.png" -gravity northwest -geometry '+125+125' -composite \
        "$prefix-headline.png" -gravity northwest -geometry '+125+205' -composite \
        "$prefix-device-shadow.png" -gravity northwest -geometry '+640+390' -composite \
        -strip -sampling-factor 4:2:0 -quality 94 "$destination"
}

render_wall_scene "$output_root/01-beautifully-framed.jpg"
render_table_scene "$output_root/02-wall-or-table.jpg"
render_product "$capture_root/01-landscape-frame.jpg" \
    "$output_root/03-beautifully-framed.jpg" $'Your photos.\nBeautifully framed.'
render_product "$capture_root/02-landscape-mosaic.jpg" \
    "$output_root/04-beautifully-arranged.jpg" $'More photos,\nbeautifully arranged.'
render_product "$capture_root/04-landscape-album-picker.jpg" \
    "$output_root/05-choose-an-album.jpg" $'Choose an album.\nKeep it fresh.'
render_product "$capture_root/05-landscape-controls.jpg" \
    "$output_root/06-simple-controls.jpg" $'Simple timing.\nDirect sharing.'
render_product "$capture_root/11-landscape-sample-setup.jpg" \
    "$output_root/07-see-it-first.jpg" $'See it first.\nChoose photos later.'

count=$(find "$output_root" -maxdepth 1 -type f -name '*.jpg' | wc -l | tr -d ' ')
[ "$count" = 7 ] || { echo "Expected seven screenshots; found $count." >&2; exit 1; }
for screenshot in "$output_root"/*.jpg; do
    metadata=$(sips -g format -g pixelWidth -g pixelHeight -g hasAlpha "$screenshot")
    case "$metadata" in
        *"format: jpeg"*"pixelWidth: 2752"*"pixelHeight: 2064"*"hasAlpha: no"*) ;;
        *) echo "Invalid iPad screenshot: $screenshot" >&2; exit 1 ;;
    esac
done

"$magick_bin" montage "$output_root"/*.jpg \
    -thumbnail '620x465' -set label '%t' \
    -font "$font_file" -pointsize 24 -fill '#171719' -background '#eeeae2' \
    -gravity north -geometry '620x520+22+28' -tile '4x2' \
    -strip -quality 94 "$contact_sheet"

echo "Generated seven iPad screenshots and contact sheet."
