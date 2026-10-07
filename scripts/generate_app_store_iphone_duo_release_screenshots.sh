#!/bin/bash
set -euo pipefail
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_root="$repo_root/AppStore/Version-1.6/CaptureSources/iPhone-Duo"
background_root="$source_root/MarketingBackgrounds"
output_root=${FRAMEWINK_DUO_OUTPUT_ROOT:-"$repo_root/AppStore/Version-1.6/Screenshots/iPhone-Duo"}
bezel_root=${FRAMEWINK_DUO_BEZEL_ROOT:-/Volumes/Bezel-iPhone-Duo/PNG}
wall_background="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPhone-6.9-inch/Sources/wall-closeup-portrait-v1.png"
font=${FRAMEWINK_SCREENSHOT_FONT:-/System/Library/Fonts/SFNSRounded.ttf}
work=$(mktemp -d "${TMPDIR:-/tmp}/framewink-duo-approved.XXXXXX")
trap 'rm -rf "$work"' EXIT
command -v magick >/dev/null || { echo 'ImageMagick 7 is required.' >&2; exit 1; }
mkdir -p "$output_root" "$work/Devices"
# Standalone licensed Apple hardware remains outside the repository.
for required in "$font" "$wall_background" \
    "$bezel_root/iPhone Duo - Night Sky - Inner Open Portrait.png" \
    "$bezel_root/iPhone Duo - Night Sky - Inner Open Landscape.png" \
    "$bezel_root/iPhone Duo - Night Sky - Outer Closed Portrait.png"; do
    test -f "$required" || { echo "Required source missing: $required" >&2; exit 1; }
done

make_device() {
    local bezel=$1 screen=$2 width=$3 height=$4 sx=$5 sy=$6 output=$7
    local prefix="$work/$(basename "$output" .png)"
    test "$(magick identify -format '%wx%h' "$screen")" = "${width}x${height}"
    local deviation
    deviation=$(magick "$screen" -colorspace gray -format '%[fx:standard_deviation]' info:)
    awk -v v="$deviation" 'BEGIN { exit !(v > 0.05) }'
    magick "$bezel" -alpha extract -threshold 0 -negate \
        -fill black -draw 'color 0,0 floodfill' \
        -crop "${width}x${height}+${sx}+${sy}" +repage \
        -morphology Dilate Disk:2 "$prefix-mask.png"
    magick "$screen" "$prefix-mask.png" -alpha off -compose CopyOpacity -composite "$prefix-screen.png"
    local dimensions
    dimensions=$(magick identify -format '%wx%h' "$bezel")
    magick -size "$dimensions" xc:none \
        "$prefix-screen.png" -geometry "+${sx}+${sy}" -compose Over -composite \
        "$bezel" -geometry +0+0 -compose Over -composite "$output"
    # Preserve all fully opaque original hardware pixels before uniform resizing.
    magick "$bezel" -alpha extract -threshold 99.99% "$prefix-hardware-mask.png"
    magick "$bezel" "$output" -alpha off -compose Difference -composite \
        "$prefix-hardware-mask.png" -compose Multiply -composite \
        -format '%[fx:maxima]' info: > "$prefix-hardware-error.txt"
    awk 'BEGIN {bad=0} {if ($1 != 0) bad=1} END {exit bad}' "$prefix-hardware-error.txt"
    printf '%s: original opaque artwork pixel difference = 0\n' "$(basename "$output")"
}

make_text() {
    local width=$1 margin=$2 eyebrow=$3 headline_size=$4 headline=$5 prefix=$6
    local text_width=$((width - 2 * margin))
    magick -background none -fill '#a8513e' -font "$font" -weight 700 \
        -pointsize "$eyebrow" -kerning 2 -gravity northwest -size "${text_width}x" \
        'caption:FRAMEWINK · PRIVATE SMART PHOTO FRAME' "$prefix-eyebrow.png"
    magick -background none -fill '#171719' -font "$font" -weight 700 \
        -pointsize "$headline_size" -kerning -2 -interline-spacing 5 -gravity northwest \
        -size "${text_width}x" "caption:$headline" "$prefix-headline.png"
}


make_device "$bezel_root/iPhone Duo - Night Sky - Inner Open Landscape.png" \
    "$source_root/open-landscape.png" 2853 2007 120 120 \
    "$work/Devices/01-open-landscape.png"
make_device "$bezel_root/iPhone Duo - Night Sky - Outer Closed Portrait.png" \
    "$source_root/outer-frame-portrait.png" 1398 2034 88 80 \
    "$work/Devices/04-closed-bird.png"

# Newly generated empty walnut cradles. Extract the real front rail from
# each saved background; the complete phone sits behind it inside the slot.
front_rail() {
    local source=$1 polygon=$2 width=$3 height=$4 prefix=$5
    test "$(magick identify -format '%wx%h' "$source")" = 1051x1496
    magick -size 1051x1496 xc:black -fill white -draw "polygon $polygon" "$prefix-mask.png"
    magick "$source" "$prefix-mask.png" -alpha off -compose CopyOpacity -composite \
        -compose Over -background none -resize "${width}x${height}^" \
        -gravity center -extent "${width}x${height}" "$prefix.png"
}
front_rail "$background_root/room-open-cradle-v5.png" \
    '309,1040 309,1035 313,1027 322,1023 669,1023 678,1024 684,1027 688,1036 688,1074 308,1074' \
    2007 2853 "$work/open-front-rail"
front_rail "$background_root/room-closed-cradle-v5.png" \
    '384,1040 384,1036 388,1028 395,1024 594,1023 603,1025 609,1029 613,1039 613,1074 383,1074' \
    1398 2034 "$work/closed-front-rail"

make_text 2007 120 40 150 $'Your photos.\nBeautifully framed.' "$work/open"
magick "$work/Devices/01-open-landscape.png" -resize 720x "$work/open-device.png"
magick "$background_root/room-open-cradle-v5.png" -resize '2007x2853^' \
    -gravity center -extent 2007x2853 \
    "$work/open-device.png" -gravity northwest -geometry +591+1470 -compose Over -composite \
    "$work/open-front-rail.png" -geometry +0+0 -composite \
    "$work/open-eyebrow.png" -geometry +120+145 -composite \
    "$work/open-headline.png" -geometry +120+274 -composite \
    -colorspace sRGB -alpha off -strip -sampling-factor 4:2:0 -quality 95 \
    "$output_root/01-your-photos-beautifully-framed.jpg"

make_text 1398 84 29 104 $'Open or closed.\nRight at home.' "$work/closed"
magick "$work/Devices/04-closed-bird.png" -resize 267x "$work/closed-device.png"
magick "$background_root/room-closed-cradle-v5.png" -resize '1398x2034^' \
    -gravity center -extent 1398x2034 \
    "$work/closed-device.png" -gravity northwest -geometry +528+1039 -compose Over -composite \
    "$work/closed-front-rail.png" -geometry +0+0 -composite \
    "$work/closed-eyebrow.png" -geometry +84+101 -composite \
    "$work/closed-headline.png" -geometry +84+191 -composite \
    -colorspace sRGB -alpha off -strip -sampling-factor 4:2:0 -quality 95 \
    "$output_root/04-open-or-closed.jpg"

inner="$bezel_root/iPhone Duo - Night Sky - Inner Open Portrait.png"
make_device "$inner" "$source_root/open-single-portrait.png" 2007 2853 120 120 "$work/Devices/02-open-single-portrait.png"
make_device "$inner" "$source_root/Inner/02-album-picker.jpg" 2007 2853 120 120 "$work/Devices/03-open-album-picker.png"
make_device "$inner" "$source_root/Inner/03-frame-controls.jpg" 2007 2853 120 120 "$work/Devices/05-open-controls.png"
make_device "$inner" "$source_root/Inner/04-sample-setup.jpg" 2007 2853 120 120 "$work/Devices/06-open-sample-setup.png"
make_wall() {
    local width=$1 height=$2 output=$3
    magick "$wall_background" \
        -resize "${width}x${height}^" -gravity west -extent "${width}x${height}" \
        -channel R -evaluate subtract 6.3% -channel G -evaluate subtract 0.8% \
        -channel B -evaluate add 3.5% +channel "$output"
}
make_wall 2007 2853 "$work/wall-inner.png"
make_wall 1398 2034 "$work/wall-outer.png"

inner_closeup() {
    local device=$1 headline=$2 output=$3 key=$4
    make_text 2007 120 40 150 "$headline" "$work/$key"
    magick "$device" -resize 1500x "$work/$key-device.png"
    magick "$work/wall-inner.png" \
        "$work/$key-device.png" -gravity northwest -geometry +254+740 -composite \
        "$work/$key-eyebrow.png" -gravity northwest -geometry +120+145 -composite \
        "$work/$key-headline.png" -gravity northwest -geometry +120+274 -composite \
        -colorspace sRGB -alpha off -strip -sampling-factor 4:2:0 -quality 95 "$output"
}

inner_closeup "$work/Devices/02-open-single-portrait.png" $'Open to a\nbigger frame.' "$output_root/02-open-to-a-bigger-frame.jpg" gallery
inner_closeup "$work/Devices/03-open-album-picker.png" $'Choose an album.\nKeep it fresh.' "$output_root/03-choose-an-album.jpg" album
inner_closeup "$work/Devices/05-open-controls.png" $'Simple timing.\nEasy control.' "$output_root/05-simple-timing.jpg" controls
inner_closeup "$work/Devices/06-open-sample-setup.png" $'See it first.\nChoose photos later.' "$output_root/06-see-it-first.jpg" sample
magick identify -format '%f: %wx%h, %[channels]\n' "$output_root/"*.jpg
echo 'Generated six approved native Duo screenshots with original Apple hardware.'
