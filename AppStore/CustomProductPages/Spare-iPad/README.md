# Spare iPad custom product page

Owner-review draft: Give your spare iPad a new purpose. Created from released
1.6; independent of the replacement 1.6.1 binary. No public submission yet.

Header: Review-v1/Upload/FrameWink-Spare-iPad-Header-3840x1646.png.
Search Results: Review-v1/Upload/FrameWink-Spare-iPad-Search-3840x2560.jpg.
The PNG Search master is retained; JPEG is the intended ASC upload.
All seven iPad screenshots are in Review-v1/Screenshots/iPad-13-inch, numbered
in display order. Other device galleries inherit the released listing.
Promotional text is 147 characters; the selected search keyword is iPad.

The opening card and both creative assets reuse the approved room plates
from 1.6 production artwork, the authentic landscape app capture, and Apple's
licensed iPad Pro (M5) bezel. No new AI generation was used. Room-only plates
and original imagegen prompts are saved under Sources. App and hardware pixels
are composited from their original files, uniformly resized, and never warped.
The foreground wooden holder covers the iPad bottom edge.

Native bezel and screenshot interior comparisons are zero. Final PNG interior
and foreground rail comparisons are zero. Headline-to-device gaps are 443 px
for Header and 178 px for Search. JPEG derivatives use quality 98 and 4:4:4
sampling; lossless pixel checks apply to the PNG master, not the JPEG export.
The Header preset accommodates Apple's landscape crop. Local gallery/crop
proofs are in Review-v1/Proofs; live ASC previews are recorded separately.

Regenerate from the repository root with ImageMagick 7 and the external licensed
bezel mounted. Do not redistribute the standalone Apple hardware PNG.

```sh
FRAMEWINK_IPAD_BEZEL='/private/tmp/framewink-ipad161-bezels/PNG/iPad Pro (M5) 13" - Space Black - Landscape.png' \
bash scripts/generate_app_store_ipad_custom_page.sh
```

Override FRAMEWINK_IPAD_CPP_OUTPUT_ROOT for an independent reproducibility run.
Hashes and source provenance are in manifest.json. Native app behavior and the
released general listing are unchanged. This page needs owner artwork approval
and App Review before its dedicated link can be published.
