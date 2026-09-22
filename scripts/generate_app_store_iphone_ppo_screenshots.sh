#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
font_file=${FRAMEWINK_SCREENSHOT_FONT:-/System/Library/Fonts/SFNSRounded.ttf}
source_root="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPhone-6.9-inch/Sources"
output_root="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPhone-6.9-inch/Final"
contact_sheet="$repo_root/AppStore/Screenshots/Review/ContactSheets/iPhone-PPO-Bezel-Proposed.jpg"
sample_photo="$repo_root/FrameWink/Resources/SamplePhotos/sample-autumn-cyclist.jpg"
product_background="$source_root/wall-closeup-portrait-v1.png"
official_iphone=${FRAMEWINK_IPHONE_BEZEL:-'/Volumes/Bezel-iPhone-18/PNG/iPhone 18 Pro Max/iPhone 18 Pro Max - Black - Portrait.png'}
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-iphone-ppo.XXXXXX")

trap 'rm -rf "$working_directory"' EXIT

[ -n "$magick_bin" ] && [ -x "$magick_bin" ] || {
    echo "ImageMagick 7 is required." >&2
    exit 1
}
[ -f "$font_file" ] || { echo "Screenshot font not found: $font_file" >&2; exit 1; }
if [ -f "$official_iphone" ]; then
    [ "$("$magick_bin" identify -format '%wx%h' "$official_iphone")" = '1470x3000' ] || {
        echo "Expected Apple's original 1470x3000 iPhone bezel." >&2
        exit 1
    }
fi

mkdir -p "$output_root" "$(dirname "$contact_sheet")"
find "$output_root" -maxdepth 1 -type f -name '*.jpg' -delete

make_eyebrow() {
    "$magick_bin" -background none -fill '#a8513e' \
        -font "$font_file" -weight 700 -pointsize 27 \
        -kerning 2 -gravity northwest -size '1160x' \
        'caption:FRAMEWINK · PRIVATE SMART PHOTO FRAME' "$1"
}

make_headline() {
    "$magick_bin" -background none -fill '#171719' \
        -font "$font_file" -weight 700 -pointsize 98 \
        -kerning -2 -interline-spacing 5 -gravity northwest \
        -size '1160x' "caption:$1" "$2"
}

render_lifestyle() {
    local scene=$1
    local destination=$2
    local headline=$3
    local zoom=${4:-100}
    local prefix="$working_directory/$(basename "$destination" .jpg)"
    "$magick_bin" "$scene" -resize '1320x2868^' -resize "${zoom}%" \
        -gravity center -extent '1320x2868' "$prefix-scene.png"
    make_eyebrow "$prefix-eyebrow.png"
    make_headline "$headline" "$prefix-headline.png"
    "$magick_bin" "$prefix-scene.png" \
        "$prefix-eyebrow.png" -gravity northwest -geometry '+80+95' -composite \
        "$prefix-headline.png" -gravity northwest -geometry '+80+180' -composite \
        -strip -sampling-factor 4:2:0 -quality 94 "$destination"
}

make_device() {
    local screen=$1
    local destination=$2
    local prefix="$working_directory/$(basename "$destination" .png)"
    "$magick_bin" "$screen" -resize '1320x2868^' -gravity center -extent '1320x2868' "$prefix-fitted.png"
    "$magick_bin" -size '1320x2868' xc:none -fill white -stroke none \
        -draw 'roundrectangle 0,0 1319,2867 190,190' "$prefix-mask.png"
    "$magick_bin" "$prefix-fitted.png" "$prefix-mask.png" -alpha off -compose CopyOpacity -composite "$prefix-screen.png"
    if [ -f "$official_iphone" ]; then
        "$magick_bin" -size '1470x3000' xc:none \
            "$prefix-screen.png" -geometry '+75+66' -compose over -composite \
            "$official_iphone" -geometry '+0+0' -compose over -composite \
            -resize '1080x' "$prefix-device.png"
    else
        "$magick_bin" -size '1470x3000' xc:none \
            -fill '#10141b' -stroke '#30435f' -strokewidth 10 \
            -draw 'roundrectangle 5,5 1464,2994 230,230' \
            "$prefix-screen.png" -geometry '+75+66' -compose over -composite \
            -resize '1080x' "$prefix-device.png"
    fi
    "$magick_bin" "$prefix-device.png" \
        \( +clone -background '#2f211a55' -shadow '24x12+0+18' \) \
        +swap -background none -layers merge +repage "$destination"
}

render_product() {
    local screen=$1
    local destination=$2
    local headline=$3
    local prefix="$working_directory/$(basename "$destination" .jpg)"
    "$magick_bin" "$product_background" -resize '1320x2868^' -gravity west -extent '1320x2868' \
        -channel R -evaluate subtract 6.3% \
        -channel G -evaluate subtract 0.8% \
        -channel B -evaluate add 3.5% +channel \
        "$prefix-background.png"
    make_device "$screen" "$prefix-device-shadow.png"
    make_eyebrow "$prefix-eyebrow.png"
    make_headline "$headline" "$prefix-headline.png"
    "$magick_bin" "$prefix-background.png" \
        "$prefix-eyebrow.png" -gravity northwest -geometry '+80+95' -composite \
        "$prefix-headline.png" -gravity northwest -geometry '+80+180' -composite \
        "$prefix-device-shadow.png" -gravity northwest -geometry '+200+620' -composite \
        -strip -sampling-factor 4:2:0 -quality 94 "$destination"
}

render_lifestyle "$source_root/lifestyle-portrait-integrated-v2.png" \
    "$output_root/01-beautifully-framed.jpg" $'Your photos.\nBeautifully framed.'
render_product "$sample_photo" \
    "$output_root/02-made-for-every-screen.jpg" $'Made for\nevery screen.'
render_product "$source_root/native-album-picker-v1.jpg" \
    "$output_root/03-choose-an-album.jpg" $'Choose an album.\nKeep it fresh.'
render_lifestyle "$source_root/lifestyle-landscape-integrated-v4.png" \
    "$output_root/04-portrait-or-landscape.jpg" $'Portrait or landscape.\nRight at home.' 125
render_product "$source_root/native-controls-v1.jpg" \
    "$output_root/05-simple-controls.jpg" $'Simple timing.\nEasy control.'
render_product "$source_root/native-sample-setup-v1.jpg" \
    "$output_root/06-see-it-first.jpg" $'See it first.\nChoose photos later.'

count=$(find "$output_root" -maxdepth 1 -type f -name '*.jpg' | wc -l | tr -d ' ')
[ "$count" = 6 ] || { echo "Expected six screenshots; found $count." >&2; exit 1; }
for screenshot in "$output_root"/*.jpg; do
    metadata=$(sips -g format -g pixelWidth -g pixelHeight -g hasAlpha "$screenshot")
    case "$metadata" in
        *"format: jpeg"*"pixelWidth: 1320"*"pixelHeight: 2868"*"hasAlpha: no"*) ;;
        *) echo "Invalid screenshot: $screenshot" >&2; exit 1 ;;
    esac
done

"$magick_bin" montage "$output_root"/*.jpg \
    -thumbnail '420x912' -set label '%t' \
    -font "$font_file" -pointsize 26 -fill '#171719' -background '#eeeae2' \
    -gravity north -geometry '420x970+22+26' -tile '3x2' \
    -quality 94 "$contact_sheet"

echo "Generated six iPhone screenshots and contact sheet."
