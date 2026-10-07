#!/bin/bash
set -euo pipefail
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_root="$repo_root/AppStore/Version-1.6/CaptureSources/iPhone-Duo"
output_root="$repo_root/AppStore/Version-1.6/Screenshots/iPhone-Duo"
background="$repo_root/AppStore/Screenshots/ProductPageOptimization/iPhone-6.9-inch/Sources/wall-closeup-portrait-v1.png"
font_file=${FRAMEWINK_SCREENSHOT_FONT:-/System/Library/Fonts/SFNSRounded.ttf}
inner_bezel=${FRAMEWINK_DUO_INNER_BEZEL:-'/Volumes/Bezel-iPhone-Duo/PNG/iPhone Duo - Night Sky - Inner Open Portrait.png'}
outer_bezel=${FRAMEWINK_DUO_OUTER_BEZEL:-'/Volumes/Bezel-iPhone-Duo/PNG/iPhone Duo - Night Sky - Outer Closed Portrait.png'}
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-duo-release.XXXXXX")
trap 'rm -rf "$working_directory"' EXIT
command -v magick >/dev/null || { echo "ImageMagick 7 is required." >&2; exit 1; }
for required in "$font_file" "$background" "$inner_bezel" "$outer_bezel"; do
    [ -f "$required" ] || { echo "Required source missing: $required" >&2; exit 1; }
done

render_card() {
    local family=$1 screen=$2 destination=$3 headline=$4
    local width height margin device_width device_y bezel bezel_width bezel_height screen_width screen_height screen_x screen_y
    if [ "$family" = inner ]; then
        width=2007 height=2853 margin=110 device_width=1500 device_y=720
        bezel="$inner_bezel" bezel_width=2247 bezel_height=3093
        screen_width=2007 screen_height=2853 screen_x=120 screen_y=120
    else
        width=1398 height=2034 margin=80 device_width=1000 device_y=560
        bezel="$outer_bezel" bezel_width=1574 bezel_height=2194
        screen_width=1398 screen_height=2034 screen_x=88 screen_y=80
    fi
    [ "$(magick identify -format '%wx%h' "$bezel")" = "${bezel_width}x${bezel_height}" ] || { echo "Official artwork dimensions changed." >&2; exit 1; }
    [ "$(magick identify -format '%wx%h' "$screen")" = "${screen_width}x${screen_height}" ] || { echo "Wrong native capture dimensions: $screen" >&2; exit 1; }
    local deviation
    deviation=$(magick "$screen" -colorspace gray -format '%[fx:standard_deviation]' info:)
    awk -v deviation="$deviation" 'BEGIN { exit !(deviation >= 0.05) }' || { echo "Rejected inactive display." >&2; exit 1; }
    local prefix="$working_directory/$(basename "$destination" .jpg)"
    # Only the separate, enclosed screen opening receives app pixels. The
    # complete original Apple artwork is kept intact and uniformly resized.
    # No shell trimming, hardware drawing, shadows, rotation, or perspective.
    magick "$bezel" -alpha extract -threshold 0 -negate \
        -fill black -draw 'color 0,0 floodfill' \
        -crop "${screen_width}x${screen_height}+${screen_x}+${screen_y}" +repage \
        -morphology Dilate Disk:2 "$prefix-mask.png"
    magick "$screen" "$prefix-mask.png" -alpha off -compose CopyOpacity -composite "$prefix-screen.png"
    magick -size "${bezel_width}x${bezel_height}" xc:none \
        "$prefix-screen.png" -geometry "+${screen_x}+${screen_y}" -compose Over -composite \
        "$bezel" -geometry +0+0 -compose Over -composite \
        -resize "${device_width}x" "$prefix-device.png"
    local eyebrow_size headline_size text_width
    if [ "$family" = inner ]; then eyebrow_size=38 headline_size=118; else eyebrow_size=29 headline_size=90; fi
    text_width=$((width - 2 * margin))
    magick -background none -fill '#a8513e' -font "$font_file" \
        -pointsize "$eyebrow_size" -kerning 2 -gravity northwest -size "${text_width}x" \
        'caption:FRAMEWINK · PRIVATE SMART PHOTO FRAME' "$prefix-eyebrow.png"
    magick -background none -fill '#171719' -font "$font_file" \
        -pointsize "$headline_size" -kerning -2 -interline-spacing 5 -gravity northwest \
        -size "${text_width}x" "caption:$headline" "$prefix-headline.png"
    magick "$background" -resize "${width}x${height}^" -gravity center -extent "${width}x${height}" \
        -channel R -evaluate subtract 6.3% -channel G -evaluate subtract 0.8% \
        -channel B -evaluate add 3.5% +channel "$prefix-background.png"
    magick "$prefix-background.png" \
        "$prefix-eyebrow.png" -gravity northwest -geometry "+${margin}+$((margin + 15))" -composite \
        "$prefix-headline.png" -gravity northwest -geometry "+${margin}+$((margin + 100))" -composite \
        "$prefix-device.png" -gravity north -geometry "+0+${device_y}" -composite \
        -alpha off -strip -sampling-factor 4:2:0 -quality 94 "$destination"
}
mkdir -p "$output_root"
render_card inner "$source_root/Inner/01-gallery.jpg" "$output_root/01-bigger-frame.jpg" $'Open to a\nbigger frame.'
render_card inner "$source_root/Inner/02-album-picker.jpg" "$output_root/02-choose-an-album.jpg" $'Choose an album.\nKeep it fresh.'
render_card inner "$source_root/Inner/03-frame-controls.jpg" "$output_root/03-simple-controls.jpg" $'Simple timing.\nEasy control.'
render_card outer "$source_root/outer-frame-portrait.png" "$output_root/04-compact-frame.jpg" $'Your photos.\nBeautifully framed.'
magick montage "$output_root/01-bigger-frame.jpg" "$output_root/02-choose-an-album.jpg" \
    "$output_root/03-simple-controls.jpg" "$output_root/04-compact-frame.jpg" \
    -font "$font_file" -thumbnail 350x500 -background '#eeeae2' -gravity north -geometry 370x520+12+16 -tile 4x1 \
    -quality 94 "$repo_root/AppStore/Version-1.6/ContactSheet-iPhone-Duo.jpg"
echo "Generated four native Duo release screenshots with headlines and intact official Apple artwork."
