#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
base="$repo_root/Design/Website/hero-lifestyle-base.webp"
website_images="$repo_root/website/public/images"
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-lifestyle-hero.XXXXXX")

trap 'rm -rf "$working_directory"' EXIT

[ -n "$magick_bin" ] && [ -x "$magick_bin" ] || {
    echo "ImageMagick 7 is required (expected the 'magick' executable)." >&2
    exit 1
}
[ -f "$base" ] || { echo "Lifestyle base is missing: $base" >&2; exit 1; }

"$magick_bin" -size 1600x1200 xc:black \
    -fill white \
    -draw 'roundrectangle 0,0,1599,1199,48,48' \
    "$working_directory/screen-mask.png"

render_scene() {
    source=$1
    destination=$2
    masked="$working_directory/$(basename "$destination" .webp)-masked.png"
    warped="$working_directory/$(basename "$destination" .webp)-warped.png"

    "$magick_bin" "$source" "$working_directory/screen-mask.png" \
        -alpha off -compose CopyOpacity -composite \
        "$masked"

    "$magick_bin" "$masked" \
        -virtual-pixel transparent \
        -distort Perspective \
        '0,0 986,353 1599,0 1426,353 1599,1199 1382,703 0,1199 916,698' \
        "$warped"

    "$magick_bin" "$base" "$warped" \
        -compose over -composite \
        -strip -quality 88 \
        "$destination"
}

render_scene \
    "$website_images/ipad-landscape-frame-clean-v2.webp" \
    "$website_images/hero-lifestyle-frame-v5.webp"
render_scene \
    "$website_images/ipad-landscape-mosaic-clean-v2.webp" \
    "$website_images/hero-lifestyle-mosaic-v5.webp"

echo "Generated clean FrameWink lifestyle hero scenes in $website_images"
