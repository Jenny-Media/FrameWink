#!/bin/bash
# Exact native composition around generated room plates; never regenerate app/device pixels.
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
font_file=${FRAMEWINK_SCREENSHOT_FONT:-/System/Library/Fonts/SFNSRounded.ttf}
official_ipad=${FRAMEWINK_IPAD_BEZEL:-'/Volumes/Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 13" - Space Black - Landscape.png'}
asset_root=${FRAMEWINK_IPAD_CPP_OUTPUT_ROOT:-"$repo_root/AppStore/CustomProductPages/Spare-iPad/Review-v1"}
source_root="$repo_root/AppStore/CustomProductPages/Spare-iPad/Sources"
output_root="$asset_root/Upload"
proof_root="$asset_root/Proofs"
capture="$repo_root/AppStore/Screenshots/Landscape/iPad-13-inch/01-landscape-frame.jpg"
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-creative-final.XXXXXX")
trap 'rm -rf "$working_directory"' EXIT

[ -x "$magick_bin" ] || { echo "ImageMagick 7 is required." >&2; exit 1; }
for required in "$font_file" "$official_ipad" "$capture" "$source_root/header-empty-room-v1.png" "$source_root/search-empty-room-v1.png"; do
    [ -f "$required" ] || { echo "Missing input: $required" >&2; exit 1; }
done
[ "$("$magick_bin" identify -format '%wx%h' "$official_ipad")" = '3000x2300' ]
[ "$("$magick_bin" identify -format '%wx%h' "$capture")" = '2752x2064' ]
mkdir -p "$output_root" "$proof_root"

# Derive the actual opening from Apple's alpha, rather than approximating its corners.
"$magick_bin" "$official_ipad" -alpha extract -threshold 0 -negate \
    -fill black -draw 'color 0,0 floodfill' \
    -crop '2752x2064+124+118' +repage -morphology Dilate Disk:2 \
    "$working_directory/screen-mask.png"
"$magick_bin" "$capture" "$working_directory/screen-mask.png" \
    -alpha off -compose CopyOpacity -composite "$working_directory/screen.png"
"$magick_bin" -size '3000x2300' xc:none \
    "$working_directory/screen.png" -geometry '+124+118' -compose Over -composite \
    "$official_ipad" -geometry '+0+0' -compose Over -composite \
    "$working_directory/device-native.png"

# Prove the fully opaque hardware and unobstructed screen interior are original pixels.
"$magick_bin" "$official_ipad" -alpha extract -threshold 99.99% "$working_directory/hardware-mask.png"
hardware_error=$("$magick_bin" "$official_ipad" "$working_directory/device-native.png" \
    -alpha off -compose Difference -composite "$working_directory/hardware-mask.png" \
    -compose Multiply -composite -format '%[fx:maxima]' info:)
"$magick_bin" "$capture" -crop '2520x1800+116+132' +repage "$working_directory/source-interior.png"
"$magick_bin" "$working_directory/device-native.png" -crop '2520x1800+240+250' +repage \
    "$working_directory/composite-interior.png"
screen_error=$("$magick_bin" "$working_directory/source-interior.png" \
    "$working_directory/composite-interior.png" -alpha off -compose Difference -composite \
    -format '%[fx:maxima]' info:)
[ "$hardware_error" = 0 ] && [ "$screen_error" = 0 ] || {
    echo "Native source integrity check failed." >&2; exit 1;
}

render_asset() {
    local name=$1 canvas=$2 plate=$3 device_width=$4 device_x=$5 device_y=$6
    local rail_polygon=$7 point_size=$8 text_x=$9 text_y=${10} second_y=${11}
    local first_line=${12} second_line=${13} export_name=${14}
    local prefix="$working_directory/$name"

    # Cover-fit is uniform; never stretch either a room or a device.
    "$magick_bin" "$source_root/$plate" -filter Lanczos -resize "${canvas}^" \
        -gravity center -extent "$canvas" -colorspace sRGB "$prefix-background.png"
    "$magick_bin" "$working_directory/device-native.png" -filter Lanczos \
        -resize "${device_width}x" "$prefix-device.png"
    "$magick_bin" -size "$canvas" xc:none "$prefix-device.png" \
        -gravity northwest -geometry "+${device_x}+${device_y}" \
        -compose Over -composite "$prefix-device-layer.png"
    "$magick_bin" "$prefix-device-layer.png" -alpha extract -blur 0x12 \
        -evaluate Multiply 0.16 -roll '+0+8' "$prefix-shadow-mask.png"
    "$magick_bin" -size "$canvas" xc:'#3c291f' "$prefix-shadow-mask.png" \
        -alpha off -compose CopyOpacity -composite "$prefix-shadow.png"

    # Reuse the room's real wooden front rail to put the iPad behind the holder.
    "$magick_bin" -size "$canvas" xc:black -fill white -stroke none \
        -draw "polygon $rail_polygon" "$prefix-rail-mask.png"
    "$magick_bin" "$prefix-background.png" "$prefix-rail-mask.png" \
        -alpha off -compose CopyOpacity -composite "$prefix-rail.png"
    "$magick_bin" "$prefix-background.png" "$prefix-shadow.png" \
        -geometry '+0+0' -compose Over -composite "$prefix-device-layer.png" \
        -geometry '+0+0' -compose Over -composite "$prefix-rail.png" \
        -geometry '+0+0' -compose Over -composite "$prefix-scene.png"

    "$magick_bin" -background none -fill '#171719' -font "$font_file" \
        -weight 400 -pointsize "$point_size" "label:$first_line" "$prefix-type-1.png"
    "$magick_bin" -background none -fill '#171719' -font "$font_file" \
        -weight 400 -pointsize "$point_size" "label:$second_line" "$prefix-type-2.png"
    "$magick_bin" "$prefix-scene.png" "$prefix-type-1.png" -gravity northwest \
        -geometry "+${text_x}+${text_y}" -compose Over -composite \
        "$prefix-type-2.png" -geometry "+${text_x}+${second_y}" \
        -compose Over -composite -colorspace sRGB -alpha off -depth 8 -strip \
        -define png:color-type=2 -define png:compression-level=9 \
        "$output_root/$export_name"

    # Export detail crops from the final image, with the surrounding room retained.
    local detail_y=$((device_y - 40))
    local detail_width=$((device_width + 120))
    local device_height=$("$magick_bin" identify -format '%h' "$prefix-device.png")
    local detail_height=$((device_height + 160))
    local detail_x=$((device_x - 60))
    "$magick_bin" "$output_root/$export_name" \
        -crop "${detail_width}x${detail_height}+${detail_x}+${detail_y}" +repage -strip -define png:exclude-chunks=all \
        "$proof_root/$name-device-detail.png"
    local text_width_1=$("$magick_bin" identify -format '%w' "$prefix-type-1.png")
    local text_width_2=$("$magick_bin" identify -format '%w' "$prefix-type-2.png")
    local type_width=$text_width_1
    [ "$text_width_2" -le "$type_width" ] || type_width=$text_width_2
    local gap=$((device_x - text_x - type_width))
    [ "$gap" -ge "$point_size" ] || {
        echo "Headline/device gap below one font size." >&2; exit 1;
    }
    [ "$("$magick_bin" identify -format '%wx%h' "$output_root/$export_name")" = "$canvas" ]
    [ "$("$magick_bin" identify -format '%[opaque]' "$output_root/$export_name")" = True ]
    local interior_width=$((device_width - 160))
    local interior_height=$((device_height - 200))
    "$magick_bin" "$prefix-device.png" -crop "${interior_width}x${interior_height}+80+100" \
        +repage -alpha off -depth 8 "$prefix-expected-interior.png"
    "$magick_bin" "$output_root/$export_name" \
        -crop "${interior_width}x${interior_height}+$((device_x + 80))+$((device_y + 100))" \
        +repage "$prefix-final-interior.png"
    local final_screen_error
    final_screen_error=$("$magick_bin" "$prefix-expected-interior.png" "$prefix-final-interior.png" \
        -alpha off -compose Difference -composite -format '%[fx:maxima]' info:)
    local rail_y=$((device_y + device_height - 20))
    "$magick_bin" "$prefix-background.png" -crop "400x20+$((device_x + 250))+${rail_y}" \
        +repage -alpha off -depth 8 "$prefix-expected-rail.png"
    "$magick_bin" "$output_root/$export_name" -crop "400x20+$((device_x + 250))+${rail_y}" \
        +repage "$prefix-final-rail.png"
    local rail_error
    rail_error=$("$magick_bin" "$prefix-expected-rail.png" "$prefix-final-rail.png" \
        -alpha off -compose Difference -composite -format '%[fx:maxima]' info:)
    [ "$final_screen_error" = 0 ] && [ "$rail_error" = 0 ] || {
        echo "Final check failed: screen=$final_screen_error rail=$rail_error" >&2; exit 1;
    }
    printf '{"scaled_screen_interior_max_difference":%s,"foreground_rail_max_difference":%s,"text_to_device_gap_pixels":%s,"font_point_size":%s,"device_width":%s,"device_height":%s,"device_x":%s,"device_y":%s}\n' \
        "$final_screen_error" "$rail_error" "$gap" "$point_size" "$device_width" "$device_height" \
        "$device_x" "$device_y" > "$proof_root/$name-alignment-checks.json"
    printf '%s: %s, device %sx%s at +%s+%s, headline gap %spx\n' \
        "$name" "$canvas" "$device_width" "$device_height" "$device_x" "$device_y" "$gap"
}

# Apple's landscape iPad preview center-crops this Header to about 3.9:1.
# This separate preset keeps the device top inside that crop and its bottom
# behind the original rail. The original preset remains reproducible.
if [ "${FRAMEWINK_HEADER_CROP_SAFE:-1}" = 1 ]; then
    render_asset header '3840x1646' 'header-empty-room-v1.png' 1060 1900 365 \
        '1794,1203 1804,1163 1824,1147 1868,1143 3038,1143 3058,1161 3074,1194 3074,1320 1794,1320' \
        100 774 666 780 'Your spare iPad.' 'A new purpose.' 'FrameWink-Spare-iPad-Header-3840x1646.png'
    header_export='FrameWink-Spare-iPad-Header-3840x1646.png'
else
    render_asset header '3840x1646' 'header-empty-room-v1.png' 1180 1840 275 \
        '1794,1203 1804,1163 1824,1147 1868,1143 3038,1143 3058,1161 3074,1194 3074,1320 1794,1320' \
        100 774 666 780 'Your spare iPad.' 'A new purpose.' 'FrameWink-Spare-iPad-Header-original-placement.png'
    header_export='FrameWink-Spare-iPad-Header-original-placement.png'
fi
render_asset search '3840x2560' 'search-empty-room-v1.png' 1400 1693 610 \
    '1660,1710 1663,1675 1675,1657 1695,1645 3062,1645 3110,1648 3130,1670 3140,1710 3140,1850 1660,1850' \
    112 750 1025 1150 'Your spare iPad.' 'A new purpose.' 'FrameWink-Spare-iPad-Search-3840x2560.png'

"$magick_bin" montage "$output_root/$header_export" \
    "$output_root/FrameWink-Spare-iPad-Search-3840x2560.png" \
    -font "$font_file" -thumbnail '1400x934' -background '#eee8df' -gravity center \
    -geometry '1400x950+20+20' -tile '1x2' -strip -quality 96 \
    "$proof_root/Final-Upload-Contact-Sheet.jpg"
printf '{"original_opaque_bezel_max_difference": %s, "original_screen_interior_max_difference": %s}\n' \
    "$hardware_error" "$screen_error" > "$asset_root/native-pixel-verification.json"
# Export upload-friendly Search JPEG and the opening iPad screenshot from this
# same scene. The 4:3 crop retains the complete headline and wooden holder.
"$magick_bin" "$output_root/FrameWink-Spare-iPad-Search-3840x2560.png" \
    -colorspace sRGB -alpha off -sampling-factor 4:4:4 -quality 98 -strip \
    "$output_root/FrameWink-Spare-iPad-Search-3840x2560.jpg"
mkdir -p "$asset_root/Screenshots/iPad-13-inch"
"$magick_bin" "$output_root/FrameWink-Spare-iPad-Search-3840x2560.png" \
    -resize '2752x2064^' -gravity center -extent '2752x2064' \
    -colorspace sRGB -alpha off -sampling-factor 4:4:4 -quality 98 -strip \
    "$asset_root/Screenshots/iPad-13-inch/01-your-spare-ipad.jpg"
for pair in '02:03-beautifully-framed' '03:04-beautifully-arranged' \
    '04:07-see-it-first' '05:05-choose-an-album' '06:06-simple-controls' \
    '07:02-wall-or-table'; do
    cp "$repo_root/AppStore/Screenshots/ProductPageOptimization/iPad-13-inch/Final/${pair#*:}.jpg" \
        "$asset_root/Screenshots/iPad-13-inch/${pair%%:*}-${pair#*:}.jpg"
done
"$magick_bin" "$output_root/$header_export" -gravity center \
    -crop '3840x984+0+0' +repage -strip -define png:exclude-chunks=all "$proof_root/Header-landscape-center-crop.png"
"$magick_bin" montage "$asset_root/Screenshots/iPad-13-inch/01-your-spare-ipad.jpg" \
    "$asset_root/Screenshots/iPad-13-inch/02-03-beautifully-framed.jpg" \
    "$asset_root/Screenshots/iPad-13-inch/03-04-beautifully-arranged.jpg" \
    -font "$font_file" -thumbnail '700x525' -background '#eee8df' \
    -geometry '700x525+18+18' -tile '3x1' -strip -quality 96 \
    "$proof_root/Opening-iPad-gallery.jpg"
echo "Final creative assets exported; no App Store action performed."
