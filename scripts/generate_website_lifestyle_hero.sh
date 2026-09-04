#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
default_bezel='/Volumes/Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 13" - Space Black - Landscape.png'
bezel=${FRAMEWINK_IPAD_BEZEL:-$default_bezel}
default_iphone_bezel='/Volumes/Bezel-iPhone-17/PNG/iPhone 17 Pro Max/iPhone 17 Pro Max - Deep Blue - Portrait.png'
iphone_bezel=${FRAMEWINK_IPHONE_BEZEL:-$default_iphone_bezel}
frame_capture="$repo_root/website/public/images/ipad-landscape-frame-clean-v2.webp"
mosaic_capture="$repo_root/website/public/images/ipad-landscape-mosaic-clean-v2.webp"
pair_capture="$repo_root/website/public/images/ipad-landscape-pair-clean-v1.webp"
iphone_capture="$repo_root/FrameWink/Resources/SamplePhotos/sample-autumn-cyclist.jpg"
website_images="$repo_root/website/public/images"
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-flat-ipad.XXXXXX")

trap 'rm -rf "$working_directory"' EXIT

[ -n "$magick_bin" ] && [ -x "$magick_bin" ] || {
    echo "ImageMagick 7 is required (expected the 'magick' executable)." >&2
    exit 1
}

for required_file in "$frame_capture" "$mosaic_capture" "$pair_capture" "$iphone_capture"; do
    [ -f "$required_file" ] || {
        echo "Required iPad presentation source is missing: $required_file" >&2
        exit 1
    }
done

if [ ! -f "$bezel" ]; then
    echo "Licensed bezel source is not mounted; preserving the bezel from the existing rendered website assets."
fi

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

    if [ -f "$bezel" ]; then
        "$magick_bin" -size 3000x2300 xc:none \
            "$rounded" -geometry +124+118 -compose over -composite \
            "$bezel" -geometry +0+0 -compose over -composite \
            -resize 1500x1150 \
            -strip \
            -quality 90 \
            "$destination"
        return
    fi

    [ -f "$destination" ] || {
        echo "Existing rendered bezel fallback is missing: $destination" >&2
        exit 1
    }
    template="$working_directory/$(basename "$destination" .webp)-template.webp"
    cp "$destination" "$template"
    "$magick_bin" "$template" \
        \( "$rounded" -resize 1376x1032! \) \
        -geometry +62+59 \
        -compose over \
        -composite \
        -strip \
        -quality 90 \
        "$destination"
}

build_device "$frame_capture" "$website_images/ipad-flat-frame-v1.webp"
build_device "$mosaic_capture" "$website_images/ipad-flat-mosaic-v1.webp"
build_device "$pair_capture" "$website_images/ipad-flat-pair-v2.webp"

iphone_destination="$website_images/iphone-17-pro-max-cyclist.webp"
if [ -f "$iphone_bezel" ]; then
    # Apple's official iPhone 17 Pro Max portrait bezel is 1470 x 3000 and
    # exposes the native 1320 x 2868 screen at +75+66. Keep the supplied bezel
    # unchanged and place FrameWink's real sample-frame content beneath it.
    "$magick_bin" "$iphone_capture" \
        -resize 1320x2868^ \
        -gravity center \
        -extent 1320x2868 \
        "$working_directory/iphone-screen.png"

    "$magick_bin" -size 1470x3000 xc:none \
        "$working_directory/iphone-screen.png" -geometry +75+66 -compose over -composite \
        "$iphone_bezel" -geometry +0+0 -compose over -composite \
        -resize 735x1500 \
        -strip \
        -quality 90 \
        "$iphone_destination"
elif [ ! -f "$iphone_destination" ]; then
    echo "Licensed iPhone bezel source is not mounted and the rendered website asset is missing: $iphone_destination" >&2
    exit 1
else
    echo "Licensed iPhone bezel source is not mounted; preserving the existing rendered iPhone asset."
fi

echo "Generated flat FrameWink device presentation assets in $website_images"
