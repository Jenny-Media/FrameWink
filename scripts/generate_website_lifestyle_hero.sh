#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
default_bezel='/Volumes/Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 13" - Space Black - Landscape.png'
bezel=${FRAMEWINK_IPAD_BEZEL:-$default_bezel}
stand_plate="$repo_root/Design/Website/ipad-lifestyle-stand-plate-v2.png"
wall_plate="$repo_root/Design/Website/ipad-lifestyle-wall-plate-v1.png"
frame_capture="$repo_root/website/public/images/ipad-landscape-frame-clean-v2.webp"
mosaic_capture="$repo_root/website/public/images/ipad-landscape-mosaic-clean-v2.webp"
website_images="$repo_root/website/public/images"
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-lifestyle-scenes.XXXXXX")

trap 'rm -rf "$working_directory"' EXIT

[ -n "$magick_bin" ] && [ -x "$magick_bin" ] || {
    echo "ImageMagick 7 is required (expected the 'magick' executable)." >&2
    exit 1
}

for required_file in "$bezel" "$stand_plate" "$wall_plate" "$frame_capture" "$mosaic_capture"; do
    [ -f "$required_file" ] || {
        echo "Required lifestyle source is missing: $required_file" >&2
        exit 1
    }
done

# Apple's licensed 3000 x 2300 iPad Pro bezel has a 2752 x 2064 transparent
# screen opening at +124+118. The native 4:3 capture is rounded beneath the
# bezel, then the complete device is perspective-matched to the room plate.
"$magick_bin" -size 2752x2064 xc:none \
    -fill white \
    -stroke none \
    -draw "roundrectangle 0,0 2751,2063 58,58" \
    "$working_directory/screen-mask.png"

build_device() {
    capture=$1
    destination=$2
    fitted="$working_directory/$(basename "$destination" .png)-fitted.png"
    rounded="$working_directory/$(basename "$destination" .png)-rounded.png"

    "$magick_bin" "$capture" \
        -resize 2752x2064^ \
        -gravity center \
        -extent 2752x2064 \
        "$fitted"

    "$magick_bin" "$fitted" "$working_directory/screen-mask.png" \
        -alpha off \
        -compose CopyOpacity \
        -composite \
        "$rounded"

    "$magick_bin" -size 3000x2300 xc:none \
        "$rounded" -geometry +124+118 -compose over -composite \
        "$bezel" -geometry +0+0 -compose over -composite \
        "$destination"
}

render_scene() {
    plate=$1
    device=$2
    perspective=$3
    destination=$4
    warped="$working_directory/$(basename "$destination" .webp)-warped.png"

    "$magick_bin" "$device" \
        -alpha on \
        -virtual-pixel transparent \
        -define distort:viewport=1672x941+0+0 \
        -distort Perspective "$perspective" \
        "$warped"

    "$magick_bin" "$plate" "$warped" \
        -compose over \
        -composite \
        -strip \
        -quality 88 \
        "$destination"
}

build_device "$frame_capture" "$working_directory/frame-device.png"
build_device "$mosaic_capture" "$working_directory/mosaic-device.png"

# The target quadrilaterals are intentionally a few pixels larger than the
# generated placeholder devices. That guarantees no synthetic hardware edge
# remains visible beneath the licensed bezel in the final derivatives.
stand_perspective='0,0 448,297 3000,0 1117,303 3000,2300 1069,770 0,2300 444,722'
wall_perspective='0,0 791,220 3000,0 1258,173 3000,2300 1259,690 0,2300 790,648'

render_scene \
    "$stand_plate" \
    "$working_directory/frame-device.png" \
    "$stand_perspective" \
    "$website_images/hero-tabletop-frame-v1.webp"
render_scene \
    "$stand_plate" \
    "$working_directory/mosaic-device.png" \
    "$stand_perspective" \
    "$website_images/hero-tabletop-mosaic-v1.webp"
render_scene \
    "$wall_plate" \
    "$working_directory/mosaic-device.png" \
    "$wall_perspective" \
    "$website_images/ipad-wall-mounted-mosaic-v1.webp"

echo "Generated tabletop and wall-mounted FrameWink lifestyle scenes in $website_images"
