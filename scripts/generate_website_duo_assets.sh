#!/bin/bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_root="$repo_root/Design/Website/iPhone-Duo/Sources"
output_root="$repo_root/website/public/images"
bezel=${FRAMEWINK_DUO_INNER_BEZEL:-'/Volumes/Bezel-iPhone-Duo/PNG/iPhone Duo - Night Sky - Inner Open Landscape.png'}
working_directory=$(mktemp -d "${TMPDIR:-/tmp}/framewink-website-duo.XXXXXX")
trap 'rm -rf "$working_directory"' EXIT

command -v magick >/dev/null || { echo "ImageMagick 7 is required." >&2; exit 1; }
[ -f "$bezel" ] || { echo "Mount Apple's licensed iPhone Duo artwork first." >&2; exit 1; }
[ "$(magick identify -format '%wx%h' "$bezel")" = '3093x2247' ] || {
    echo "Expected Apple's original landscape artwork." >&2; exit 1;
}

# Keep Apple's entire supplied artwork intact. Only the separate, enclosed
# transparent screen opening receives the actual app pixels. No shell trimming,
# hardware drawing, extra shadows, reflection, rotation, or perspective transform.
screen_component=$(magick "$bezel" -alpha extract -threshold 0 -negate \
    -define connected-components:verbose=true -connected-components 8 null: \
    | awk '$2 == "2853x2007+120+120" { sub(":", "", $1); print $1 }')
[ -n "$screen_component" ] || { echo "Official screen opening changed; inspect before composing." >&2; exit 1; }
magick "$bezel" -alpha extract -threshold 0 -negate \
    -define connected-components:keep="$screen_component" \
    -define connected-components:mean-color=true -connected-components 8 \
    -threshold 0 -morphology Dilate Disk:2 \
    -crop 2853x2007+120+120 +repage "$working_directory/screen-mask.png"

mkdir -p "$output_root"
for name in open-landscape open-controls-landscape; do
    screen="$source_root/$name.png"
    [ "$(magick identify -format '%wx%h' "$screen")" = '2853x2007' ] || {
        echo "Wrong native screenshot size: $screen" >&2; exit 1;
    }
    deviation=$(magick "$screen" -colorspace gray -format '%[fx:standard_deviation]' info:)
    awk -v deviation="$deviation" 'BEGIN { exit !(deviation >= 0.05) }' || {
        echo "Rejected blank display: $screen" >&2; exit 1;
    }
    magick "$screen" "$working_directory/screen-mask.png" \
        -alpha off -compose CopyOpacity -composite "$working_directory/screen.png"
    magick -size 3093x2247 xc:none \
        "$working_directory/screen.png" -geometry +120+120 -compose Over -composite \
        "$bezel" -geometry +0+0 -compose Over -composite \
        -resize 1546x -strip -quality 90 \
        "$output_root/iphone-duo-$name-v1.webp"
done
echo "Generated official-bezel Duo website images without changing the device artwork."
