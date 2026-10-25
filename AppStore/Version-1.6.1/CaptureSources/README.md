# Build 80 native render inputs

Nine lossless native Simulator buffers support the seven refreshed cards.
The two extra iPad inputs are the clean single/Mosaic states consumed by the
existing full-gallery generator; the release workflow retains those two
approved cards unchanged. `SHA256SUMS` records these inputs, not artwork approval.

- iPhone: fresh iPhone 18 Pro Max, iOS 27.0, 1320 × 2868. Scenarios are
  `album-picker`, `frame-controls`, and `sample`.
- iPad: iPad Pro 13-inch (M5), iPadOS 27.0, 2752 × 2064 landscape. Exported
  attachments from `MarketingLandscapeScreenshotTests/testCaptureLandscapeMarketingScreens`.
- Duo: real fully open inner portrait display, iOS 27.1, 2007 × 2853, scenario
  `sample`; no geometry or division override.

The application is the existing 1.6.1 (80) Debug Simulator counterpart of the
signed archive: all 85 application/project source fingerprints match archive
source `8bfb9bd`. Only bundled project-owned photos and the existing fake album
are used. No personal Photos access occurs. Debug fixture state is absent from
the Release archive.

XCTest's raw iPad PNGs are 2064 × 2752 with EXIF orientation 8 (LeftBottom).
Normalize each exported file with:

```sh
magick exported.png -auto-orient -orient TopLeft -strip normalized.png
```

This rotates rendered pixels once without scaling/cropping and clears the
orientation hazard before the legacy renderer calls `-auto-orient`. Explicit
`-rotate -90 -strip` alone leaves ImageMagick's LeftBottom orientation property
in PNG output and is unsuitable here. The release workflow rejects that state.

Detailed per-card decisions, raw capture manifests, initial probes, failed and
passing test receipts, exact commands and limitations are recorded in
[the parity audit](../Screenshot-Parity-2026-10-24.md). Regenerate with
`scripts/generate_app_store_1_6_1_refresh.sh` after mounting the already licensed
original Apple iPhone/iPad/Duo bezels at their documented default paths.
