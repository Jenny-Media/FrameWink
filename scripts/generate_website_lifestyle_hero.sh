#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
default_bezel='/Volumes/Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 13" - Space Black - Landscape.png'
bezel=${FRAMEWINK_IPAD_BEZEL:-$default_bezel}
frame_capture="$repo_root/website/public/images/ipad-landscape-frame-clean-v2.webp"
mosaic_capture="$repo_root/website/public/images/ipad-landscape-mosaic-clean-v2.webp"
website_images="$repo_root/website/public/images"
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-flat-ipad.XXXXXX")

trap 'rm -rf "$working_directory"' EXIT

[ -n "$magick_bin" ] && [ -x "$magick_bin" ] || {
    echo "ImageMagick 7 is required (expected the 'magick' executable)." >&2
    exit 1
}

for required_file in "$bezel" "$frame_capture" "$mosaic_capture"; do
    [ -f "$required_file" ] || {
        echo "Required iPad presentation source is missing: $required_file" >&2
        exit 1
    }
done

# Apple's licensed 3000 x 2300 iPad Pro bezel has a 2752 x 2064 transparent
# screen opening at +124+118. Keep the device flat and exact: the native 4:3
# capture is rounded beneath the bezel and the complete transparent device is
# resized only after compositing. No generated room, stand, wall, or hardware
# is represented as part of the product.
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
        -resize 1500x1150 \
        -strip \
        -quality 90 \
        "$destination"
}

build_device "$frame_capture" "$website_images/ipad-flat-frame-v1.webp"
build_device "$mosaic_capture" "$website_images/ipad-flat-mosaic-v1.webp"

echo "Generated flat FrameWink iPad presentation assets in $website_images"
