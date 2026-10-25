#!/bin/bash
# Recompose build-80 UI cards in the existing approved design. Historical
# galleries and approval locks stay intact; the new set awaits owner review.
set -euo pipefail
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
captures="$repo_root/AppStore/Version-1.6.1/CaptureSources"
output_root=${FRAMEWINK_RELEASE_ARTWORK_OUTPUT_ROOT:-"$repo_root/AppStore/Version-1.6.1/Screenshots"}
# Never allow the legacy iPhone generator's synthetic-bezel fallback here.
iphone_bezel=${FRAMEWINK_IPHONE_BEZEL:-'/Volumes/Bezel-iPhone-18/PNG/iPhone 18 Pro Max/iPhone 18 Pro Max - Black - Portrait.png'}
[ -f "$iphone_bezel" ] || { echo "Official iPhone bezel is required: $iphone_bezel" >&2; exit 1; }
# Reject a buffer that would be resized or rotated again by a legacy renderer.
# In particular, a rotated XCTest PNG can still carry LeftBottom metadata.
for family in iPhone-6.9-inch iPad-13-inch iPhone-Duo; do
    case "$family" in
        iPhone-6.9-inch) expected=1320x2868 ;;
        iPad-13-inch) expected=2752x2064 ;;
        iPhone-Duo) expected=2007x2853 ;;
    esac
    for capture in "$captures/$family/"*.png; do
        actual=$(magick identify -format '%wx%h %[orientation]' "$capture")
        case "$actual" in
            "$expected TopLeft"|"$expected Undefined") ;;
            *) echo "Non-normalized native capture: $capture ($actual)" >&2; exit 1 ;;
        esac
    done
done
work=$(mktemp -d "${TMPDIR:-/tmp}/framewink-artwork80.XXXXXX")
trap 'rm -rf "$work"' EXIT

FRAMEWINK_IPHONE_PPO_OUTPUT_ROOT="$work/iPhone-6.9-inch" \
FRAMEWINK_IPHONE_PPO_CONTACT_SHEET="$work/iphone-contact.jpg" \
FRAMEWINK_IPHONE_PPO_ALBUM_CAPTURE="$captures/iPhone-6.9-inch/album-picker.png" \
FRAMEWINK_IPHONE_PPO_CONTROLS_CAPTURE="$captures/iPhone-6.9-inch/controls.png" \
FRAMEWINK_IPHONE_PPO_SAMPLE_CAPTURE="$captures/iPhone-6.9-inch/sample-setup.png" \
    bash "$repo_root/scripts/generate_app_store_iphone_ppo_screenshots.sh"

FRAMEWINK_IPAD_PPO_OUTPUT_ROOT="$work/iPad-13-inch" \
FRAMEWINK_IPAD_PPO_CONTACT_SHEET="$work/ipad-contact.jpg" \
FRAMEWINK_IPAD_PPO_CAPTURE_ROOT="$captures/iPad-13-inch" \
FRAMEWINK_IPAD_PPO_CAPTURE_EXTENSION=png \
    bash "$repo_root/scripts/generate_app_store_ipad_ppo_screenshots.sh"

FRAMEWINK_DUO_OUTPUT_ROOT="$work/iPhone-Duo" \
FRAMEWINK_DUO_SAMPLE_CAPTURE="$captures/iPhone-Duo/sample-setup.png" \
    bash "$repo_root/scripts/generate_app_store_iphone_duo_release_screenshots.sh"

# Retain the twelve verified current cards byte-for-byte. Replace exactly the
# seven outdated interfaces; don't rebuild their photography or headlines.
for family in iPhone-6.9-inch iPad-13-inch; do
    mkdir -p "$output_root/$family"
    cp "$repo_root/AppStore/Screenshots/ProductPageOptimization/$family/Final/"*.jpg "$output_root/$family/"
done
mkdir -p "$output_root/iPhone-Duo"
cp "$repo_root/AppStore/Version-1.6/Screenshots/iPhone-Duo/"*.jpg "$output_root/iPhone-Duo/"
for filename in 03-choose-an-album.jpg 05-simple-controls.jpg 06-see-it-first.jpg; do
    cp "$work/iPhone-6.9-inch/$filename" "$output_root/iPhone-6.9-inch/$filename"
done
for filename in 05-choose-an-album.jpg 06-simple-controls.jpg 07-see-it-first.jpg; do
    cp "$work/iPad-13-inch/$filename" "$output_root/iPad-13-inch/$filename"
done
cp "$work/iPhone-Duo/06-see-it-first.jpg" "$output_root/iPhone-Duo/06-see-it-first.jpg"
(
    cd "$output_root"
    shasum -a 256 iPhone-6.9-inch/*.jpg iPad-13-inch/*.jpg iPhone-Duo/*.jpg > SHA256SUMS
)
echo "Prepared nineteen release cards: seven UI refreshes, twelve approved originals."
