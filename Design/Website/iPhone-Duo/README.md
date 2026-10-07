# Native iPhone Duo website captures

These are real native Duo app pixels from version 1.6 in
[PR #23](https://github.com/Jenny-Media/FrameWink/pull/23), using bundled sample
photos. The two open-display captures were refreshed on October 6, 2026 with
Xcode 27.1 RC (27A9275), SDK/runtime build 24A94232, on the dedicated
FrameWinkRC16DuoQA Simulator. Native app source is unchanged from the
Cloud Analyze 65 validated commit `13c077ec37689afab00be1958a053bdc7e8ac80d`.
The earlier Book/Larger Text file retains its separate beta provenance and is
not used on the website.

The website uses the open-screen image. The controls image is also stored for
review and future use. Dimensions, artwork provenance, and SHA-256 hashes are
listed in `capture-manifest.json`. Inactive or incorrectly sized captures are
rejected. Manual RC Book/Tabletop, paused personal reel continuity, and largest
text duration-panel scrolling were verified through Device Hub.

## Apple artwork

The owner authorized accepting the Apple Design Resources license. The original
package was acquired from [Apple Design Resources](https://developer.apple.com/design/resources/)
and mounted read-only after accepting license **LYL142, June 21, 2023** on
October 1 and October 6, 2026. The package and standalone PNG/PSD bezels stay outside Git.

The website composites retain the complete supplied Night Sky Inner Open
Landscape artwork and insert real app pixels into its exact transparent screen
opening. The generator does not trim the shell, redraw hardware, rotate, add
shadows, or apply perspective effects. Final WebP images are uniformly resized.
See [Apple's marketing guidelines](https://developer.apple.com/app-store/marketing/guidelines/).

Apple artwork in these depictions is licensed only for showing Apple-platform
application interfaces. Do not extract it, redistribute it as standalone artwork,
or reuse it as clip art or in interfaces for non-Apple platforms. Apple retains
ownership of its artwork; these composites do not imply Apple endorsement.

## Regenerate

Mount the licensed original package locally. From the repository root, run:

```sh
bash scripts/generate_website_duo_assets.sh
```

For fresh sources, use `scripts/capture_website_duo_screenshots.sh` from the
native candidate. Set `FRAMEWINK_SIMULATOR_ID` to a dedicated test device and
select **Open, landscape, full screen** in Xcode 27.1 Device Hub first. The
script checks exact native dimensions and rejects blank displays. It does not
change App Store screenshots or use anyone's personal library.

These images preview an upcoming update. Native support has not yet shipped;
signed archive, App Review, and physical Duo checks remain separate gates.
