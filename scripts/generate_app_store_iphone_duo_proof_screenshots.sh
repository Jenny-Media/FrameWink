#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
font_file=${FRAMEWINK_SCREENSHOT_FONT:-/System/Library/Fonts/SFNSRounded.ttf}
proof_root="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPhone-Duo"
source_root="$proof_root/Sources"
output_root="$proof_root/Final"
contact_sheet="$repo_root/AppStore/Screenshots/Review/ContactSheets/iPhone-Duo-Proof.jpg"
background="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPhone-6.9-inch/Sources/wall-closeup-portrait-v1.png"
outer_bezel=${FRAMEWINK_DUO_OUTER_BEZEL:-'/Volumes/Bezel-iPhone-Duo/PNG/iPhone Duo - Night Sky - Outer Closed Portrait.png'}
inner_bezel=${FRAMEWINK_DUO_INNER_BEZEL:-'/Volumes/Bezel-iPhone-Duo/PNG/iPhone Duo - Night Sky - Inner Open Portrait.png'}
proof_family=${FRAMEWINK_DUO_PROOF_FAMILY:-all}
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-duo-proof.XXXXXX")

trap 'rm -rf "$working_directory"' EXIT

[ -n "$magick_bin" ] && [ -x "$magick_bin" ] || {
    echo "ImageMagick 7 is required." >&2
    exit 1
}
[ -f "$font_file" ] || { echo "Screenshot font not found: $font_file" >&2; exit 1; }
[ -f "$outer_bezel" ] || { echo "Official iPhone Duo outer bezel not found: $outer_bezel" >&2; exit 1; }
[ -f "$inner_bezel" ] || { echo "Official iPhone Duo inner bezel not found: $inner_bezel" >&2; exit 1; }
case "$proof_family" in
    all|outer|inner) ;;
    *) echo "FRAMEWINK_DUO_PROOF_FAMILY must be all, outer, or inner." >&2; exit 1 ;;
esac
[ "$("$magick_bin" identify -format '%wx%h' "$outer_bezel")" = '1574x2194' ] || {
    echo "Expected Apple's original 1574x2194 iPhone Duo outer portrait bezel." >&2
    exit 1
}
[ "$("$magick_bin" identify -format '%wx%h' "$inner_bezel")" = '2247x3093' ] || {
    echo "Expected Apple's original 2247x3093 iPhone Duo inner portrait bezel." >&2
    exit 1
}

clean_bezel_exterior() {
    local bezel=$1
    local width=$2
    local height=$3
    local silhouette=$4
    local destination=$5
    local prefix="$working_directory/$(basename "$destination" .png)"

    "$magick_bin" -size "${width}x${height}" xc:black \
        -fill white -stroke none -draw "$silhouette" \
        "$prefix-silhouette.png"
    "$magick_bin" "$bezel" -alpha extract \
        "$prefix-silhouette.png" -compose multiply -composite \
        "$prefix-alpha.png"
    "$magick_bin" "$bezel" "$prefix-alpha.png" \
        -alpha off -compose CopyOpacity -composite "$destination"
}

extract_screen_opening() {
    local bezel=$1
    local screen_width=$2
    local screen_height=$3
    local screen_x=$4
    local screen_y=$5
    local destination=$6

    # The outside background and screen opening are separate transparent
    # components. Remove the outside component, crop the exact screen bounds,
    # and extend two pixels under the bezel's antialiased inner edge.
    "$magick_bin" "$bezel" -alpha extract -threshold 0 -negate \
        -fill black -draw 'color 0,0 floodfill' \
        -crop "${screen_width}x${screen_height}+${screen_x}+${screen_y}" +repage \
        -morphology Dilate Disk:2 "$destination"
}

clean_outer_bezel="$working_directory/outer-bezel-clean.png"
clean_inner_bezel="$working_directory/inner-bezel-clean.png"
outer_screen_mask="$working_directory/outer-screen-mask.png"
inner_screen_mask="$working_directory/inner-screen-mask.png"

clean_bezel_exterior "$outer_bezel" 1574 2194 \
    'roundrectangle 47,32 1535,2162 70,70' "$clean_outer_bezel"
clean_bezel_exterior "$inner_bezel" 2247 3093 \
    'roundrectangle 58,50 2188,3040 250,250' "$clean_inner_bezel"
extract_screen_opening "$outer_bezel" 1398 2034 88 80 "$outer_screen_mask"
extract_screen_opening "$inner_bezel" 2007 2853 120 120 "$inner_screen_mask"

mkdir -p "$output_root/Outer" "$output_root/Inner" "$(dirname "$contact_sheet")"
find "$output_root" -type f -name '*.jpg' -delete

make_text() {
    local canvas_width=$1
    local eyebrow_size=$2
    local headline_size=$3
    local headline=$4
    local prefix=$5
    "$magick_bin" -background none -fill '#a8513e' \
        -font "$font_file" -weight 700 -pointsize "$eyebrow_size" \
        -kerning 2 -gravity northwest -size "${canvas_width}x" \
        'caption:FRAMEWINK · PRIVATE SMART PHOTO FRAME' "$prefix-eyebrow.png"
    "$magick_bin" -background none -fill '#171719' \
        -font "$font_file" -weight 700 -pointsize "$headline_size" \
        -kerning -2 -interline-spacing 5 -gravity northwest \
        -size "${canvas_width}x" "caption:$headline" "$prefix-headline.png"
}

make_device() {
    local screen=$1
    local bezel=$2
    local bezel_width=$3
    local bezel_height=$4
    local screen_width=$5
    local screen_height=$6
    local screen_x=$7
    local screen_y=$8
    local screen_mask=$9
    local target_width=${10}
    local destination=${11}
    local prefix="$working_directory/$(basename "$destination" .png)"

    "$magick_bin" "$screen" -resize "${screen_width}x${screen_height}!" "$prefix-fitted.png"
    "$magick_bin" "$prefix-fitted.png" "$screen_mask" \
        -alpha off -compose CopyOpacity -composite "$prefix-screen.png"
    "$magick_bin" -size "${bezel_width}x${bezel_height}" xc:none \
        "$prefix-screen.png" -geometry "+${screen_x}+${screen_y}" -compose over -composite \
        "$bezel" -geometry '+0+0' -compose over -composite \
        -resize "${target_width}x" "$prefix-device.png"
    "$magick_bin" "$prefix-device.png" \
        \( +clone -background '#2f211a55' -shadow '24x12+0+18' \) \
        +swap -background none -layers merge +repage "$destination"
}

render_card() {
    local family=$1
    local screen=$2
    local destination=$3
    local headline=$4
    local prefix="$working_directory/$(basename "$destination" .jpg)-$family"

    if [ "$family" = outer ]; then
        local width=1398 height=2034 margin=80 device_width=1000 device_y=560
        make_device "$screen" "$clean_outer_bezel" 1574 2194 1398 2034 88 80 \
            "$outer_screen_mask" \
            "$device_width" "$prefix-device-shadow.png"
        make_text 1238 29 90 "$headline" "$prefix"
    else
        local width=2007 height=2853 margin=110 device_width=1500 device_y=720
        make_device "$screen" "$clean_inner_bezel" 2247 3093 2007 2853 120 120 \
            "$inner_screen_mask" \
            "$device_width" "$prefix-device-shadow.png"
        make_text 1787 38 118 "$headline" "$prefix"
    fi

    "$magick_bin" "$background" -resize "${width}x${height}^" -gravity center \
        -extent "${width}x${height}" \
        -channel R -evaluate subtract 6.3% \
        -channel G -evaluate subtract 0.8% \
        -channel B -evaluate add 3.5% +channel \
        "$prefix-background.png"
    "$magick_bin" "$prefix-background.png" \
        "$prefix-eyebrow.png" -gravity northwest -geometry "+${margin}+$((margin + 15))" -composite \
        "$prefix-headline.png" -gravity northwest -geometry "+${margin}+$((margin + 100))" -composite \
        "$prefix-device-shadow.png" -gravity north -geometry "+0+${device_y}" -composite \
        -strip -sampling-factor 4:2:0 -quality 94 "$destination"
}

if [ "$proof_family" = all ] || [ "$proof_family" = outer ]; then
    render_card outer "$source_root/Outer/01-frame.jpg" \
        "$output_root/Outer/01-beautifully-framed.jpg" $'Your photos.\nBeautifully framed.'
fi
if [ "$proof_family" = all ] || [ "$proof_family" = inner ]; then
    render_card inner "$source_root/Inner/01-gallery.jpg" \
        "$output_root/Inner/01-bigger-frame.jpg" $'Open to a\nbigger frame.'
    render_card inner "$source_root/Inner/02-album-picker.jpg" \
        "$output_root/Inner/02-choose-an-album.jpg" $'Choose an album.\nKeep it fresh.'
    render_card inner "$source_root/Inner/03-frame-controls.jpg" \
        "$output_root/Inner/03-simple-controls.jpg" $'Simple timing.\nEasy control.'
fi

if [ "$proof_family" = all ] || [ "$proof_family" = outer ]; then
    for screenshot in "$output_root/Outer"/*.jpg; do
        metadata=$(sips -g format -g pixelWidth -g pixelHeight -g hasAlpha "$screenshot")
        case "$metadata" in
            *"format: jpeg"*"pixelWidth: 1398"*"pixelHeight: 2034"*"hasAlpha: no"*) ;;
            *) echo "Invalid iPhone Duo outer proof: $screenshot" >&2; exit 1 ;;
        esac
    done
fi
if [ "$proof_family" = all ] || [ "$proof_family" = inner ]; then
    for screenshot in "$output_root/Inner"/*.jpg; do
        metadata=$(sips -g format -g pixelWidth -g pixelHeight -g hasAlpha "$screenshot")
        case "$metadata" in
            *"format: jpeg"*"pixelWidth: 2007"*"pixelHeight: 2853"*"hasAlpha: no"*) ;;
            *) echo "Invalid iPhone Duo inner proof: $screenshot" >&2; exit 1 ;;
        esac
    done
fi

if [ "$proof_family" = all ]; then
    "$magick_bin" montage "$output_root/Outer"/*.jpg "$output_root/Inner"/*.jpg \
        -thumbnail '390x560' -set label '%t' \
        -font "$font_file" -pointsize 24 -fill '#171719' -background '#eeeae2' \
        -gravity north -geometry '420x625+20+24' -tile '2x2' \
        -quality 94 "$contact_sheet"
fi

echo "Generated iPhone Duo $proof_family proof screenshots."
