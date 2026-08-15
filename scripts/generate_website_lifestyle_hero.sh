#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
magick_bin=${FRAMEWINK_MAGICK_BIN:-$(command -v magick || true)}
base="$repo_root/Design/Website/hero-lifestyle-base-v2.png"
website_images="$repo_root/website/public/images"
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-lifestyle-hero.XXXXXX")

trap 'rm -rf "$working_directory"' EXIT

[ -n "$magick_bin" ] && [ -x "$magick_bin" ] || {
    echo "ImageMagick 7 is required (expected the 'magick' executable)." >&2
    exit 1
}
[ -f "$base" ] || { echo "Lifestyle base is missing: $base" >&2; exit 1; }

"$magick_bin" -size 1672x941 xc:black \
    -fill white \
    -stroke none \
    -draw "path 'M 994,349 L 1414,348 C 1425,348 1432,356 1430,368 L 1389,700 C 1388,711 1379,718 1368,717 L 932,709 C 920,709 913,701 916,689 L 974,369 C 976,357 983,350 994,349 Z'" \
    "$working_directory/screen-mask.png"

render_scene() {
    source=$1
    destination=$2
    warped="$working_directory/$(basename "$destination" .webp)-warped.png"
    clipped="$working_directory/$(basename "$destination" .webp)-clipped.png"

    "$magick_bin" "$source" \
        -virtual-pixel transparent \
        -distort Perspective \
        '0,0 968,339 1599,0 1442,339 1599,1199 1404,726 0,1199 898,718' \
        "$warped"

    "$magick_bin" "$warped" "$working_directory/screen-mask.png" \
        -alpha off -compose CopyOpacity -composite \
        "$clipped"

    "$magick_bin" "$base" "$clipped" \
        -compose over -composite \
        -strip -quality 88 \
        "$destination"
}

"$magick_bin" "$base" \
    -strip -quality 88 \
    "$website_images/hero-lifestyle-frame-v7.webp"
render_scene \
    "$website_images/ipad-landscape-mosaic-clean-v2.webp" \
    "$website_images/hero-lifestyle-mosaic-v7.webp"

echo "Generated clean FrameWink lifestyle hero scenes in $website_images"
