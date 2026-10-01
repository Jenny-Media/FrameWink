# Native iPhone Duo website captures

These are real Simulator app pixels from the native Duo candidate in
[PR #20](https://github.com/Jenny-Media/FrameWink/pull/20), using bundled sample
photos. The two fresh open-display captures were made on October 1, 2026 with
Xcode 27.1 (27A9269), iOS 27.1, and source commit
`867d91d630b3b5ce0480097013e96a2679494364`. The earlier Book/Larger Text capture
is retained as layout QA evidence and is not used on the website.

The main website uses one open-screen image. The native controls image is also
stored for review and future use. All originals, dimensions, artwork provenance,
and SHA-256 hashes are listed in `capture-manifest.json`. Closed-display blank
captures were rejected. Fresh closed and Tabletop marketing captures remain
pending because Device Hub pose controls were unresponsive.

## Apple artwork

The owner authorized accepting the Apple Design Resources license. The original
package was acquired from [Apple Design Resources](https://developer.apple.com/design/resources/)
and mounted read-only after accepting license **LYL142, June 21, 2023** on
October 1, 2026. The package and standalone PNG/PSD bezels stay outside Git.

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
physical Duo checks and Apple cloud validation remain required.
