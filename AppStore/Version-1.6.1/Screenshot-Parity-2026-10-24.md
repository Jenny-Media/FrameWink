# Build 80 screenshot parity — 2026-10-24

The complete 19-card gallery was compared with native 1.6.1 (80) Simulator
interfaces. Seven cards need refreshed UI: iPhone 3/5/6, iPad 5/6/7, and Duo 6.
The remaining twelve cards retain their approved bytes. The new review set is
in `Screenshots/`; earlier approved galleries and every approval lock remain
intact. [View the complete revised gallery](Screenshot-Gallery.md).

## Per-card decisions

| Family | Cards | Decision and observed reason |
| --- | --- | --- |
| iPhone 6.9-inch | 1, 2, 4 | Retain: photo-only lifestyle/full-frame compositions; clean full-screen playback remains available. |
| iPhone 6.9-inch | 3 | Refresh: album picker now has an × close control instead of the older Cancel text button. Covers, counts and selection remain current. |
| iPhone 6.9-inch | 5 | Refresh: timing sheet now has an × close control instead of the older Close text button. Four timing choices and 30s selection remain current. |
| iPhone 6.9-inch | 6 | Refresh: the sample caption now sits on a dark rounded background with updated spacing. First-launch Choose Photos/Start Sample Frame actions remain current. |
| iPad 13-inch | 1–4 | Retain: wall/table/clean full-screen and four-photo Mosaic compositions remain current. Native single/Mosaic captures confirm the displayed layouts. |
| iPad 13-inch | 5 | Refresh: album picker now has an × close control; the underlying sample caption treatment also changed. |
| iPad 13-inch | 6 | Refresh: timing popover now has an × close control. The current deterministic controls scenario uses the sail photo. |
| iPad 13-inch | 7 | Refresh: updated sample-caption treatment and placement. Permission-free setup actions remain current. |
| iPhone Duo | 1, 2, 4 | Retain: closed/open photo-only compositions remain current. Native inner-display clean playback was checked against the supported full-screen presentation. |
| iPhone Duo | 3, 5 | Retain: native album picker and timing controls already use the current × control, layout, labels and actions. No obsolete UI was observed. |
| iPhone Duo | 6 | Refresh: the sample caption now has a dark rounded background and updated spacing. |

Retained photo-only cards are not newly captured from build 80. They depict
bundled publisher-owned photos without UI controls or version-specific copy;
UI comparison does not claim identical arbitrary slideshow content. The two
retained Duo detail cards were compared against fresh native inner-display
captures. Seven replacement cards use new build-80 buffers in the established
composition. No UI, text controls, hardware or new room photography was generated.

## Capture method and source identity

The application and project inputs match signed archive source `8bfb9bd` (85
files). Existing Debug Simulator products identify themselves as 1.6.1 (80),
SDK 27.1. They render the same production SwiftUI views with existing Debug-only
bundled-photo/album scenarios; no personal photos or production entitlements are
used. This is Simulator screenshot evidence, not a new TestFlight binary or
physical-device acceptance run.

| Capture destination | Runtime | Native pixels |
| --- | --- | --- |
| Fresh FrameWink 80 Screenshot Pro Max, `74504AF4-FA50-480B-AC31-BD714278BCBE` | iOS 27.0 | 1320 × 2868 |
| Existing dedicated iPad QA, `AD6D9220-2E34-4EC4-8083-CB0B1903BBA9` | iPadOS 27.0 | 2752 × 2064 landscape |
| Existing dedicated Duo QA, `D86731ED-CAA2-41E5-B1AF-78467918B1DA` | iOS 27.1 | 2007 × 2853 inner portrait |

The original QA iPhone is the smaller Pro model; its initial 1206 × 2622 probe
was rejected as a source for the 6.9-inch gallery. The fresh Pro Max supplies
exact native pixels. XcodeBuildMCP verified session defaults, installed/launched
the existing products and inspected the UI. Its optimized screenshot output is
368 × 800, so full native buffers use `simctl io screenshot --type=png`.

Duo captures use its actual open display, not division/geometry overrides.
A standalone Simulator-only helper outside the app sends the same native
control-event protocol as the existing UI runner. Hinge 180 selects Fully Open;
`landscape-left` yields the inner portrait buffer. Actual dimensions and rendered
UI gate capture acceptance; the initial landscape-sized probe is retained.
The native helper is absent from application/project inputs and the archive.
The existing fixtures and assertions are unchanged apart from the capture-driver
scroll condition described below.

Apple's already authorized Design Resources packages were mounted read-only.
The iPhone 18 package was retrieved again from the official
[Apple Design Resources page](https://developer.apple.com/design/resources/).
The previously authorized LYL142 06/21/2023 terms are reused. Original Apple
bezel files remain outside the repository. The release refresh refuses the
older generator's synthetic-bezel fallback. Native UI is composed with the
existing exact screen-opening geometry and uniform scaling; iPad buffers are
auto-oriented once from XCTest's portrait-oriented storage and tagged TopLeft,
without scaling/cropping. The first render exposed a retained LeftBottom tag
after manual rotation; it was corrected before final review. The regeneration
script rejects incorrect source dimensions or orientation metadata.

## Capture-driver repair

The first complete iPad marketing capture stopped at the storage screenshot:
the loop stopped when Free Up Unused Space became hittable, while Delete All
FrameWink Photos remained below the viewport. The driver now continues while
either control is offscreen. The same three-gesture limit, both original
visibility assertions, other product assertions and timeouts are retained.
This changes only `MarketingLandscapeScreenshotTests.swift`, not app behavior.
The corrected complete marketing capture test is run on iPhone and iPad.
Original failure and successful result bundles remain retained separately.

## Reproduction

All local receipts live under ignored
`TestArtifacts/ReleasePrep-20261024/CaptureParity80/`. Source capture manifests,
raw PNGs, initial probes, failed and passing xcresults, and exact build commands
are retained. The complete release render inputs are in `CaptureSources/`.

```sh
# Capture harness repair: build and run on each affected family.
FRAMEWINK_BUILD_CACHE_VARIANT=release-ipad-80 python3 scripts/build_local.py --unsigned \
  --output TestArtifacts/ReleasePrep-20261024/CaptureParity80/iPadCaptureFixed -- \
  -quiet -destination 'platform=iOS Simulator,id=AD6D9220-2E34-4EC4-8083-CB0B1903BBA9' \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 120 -maximum-test-execution-time-allowance 120 \
  -only-testing:FrameWinkUITests/MarketingLandscapeScreenshotTests/testCaptureLandscapeMarketingScreens test
python3 scripts/build_local.py --unsigned \
  --output TestArtifacts/ReleasePrep-20261024/CaptureParity80/iPhoneCaptureFixed -- \
  -quiet -destination 'platform=iOS Simulator,id=74504AF4-FA50-480B-AC31-BD714278BCBE' \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 120 -maximum-test-execution-time-allowance 120 \
  -only-testing:FrameWinkUITests/MarketingLandscapeScreenshotTests/testCaptureLandscapeMarketingScreens test

# With the licensed Apple iPhone/iPad/Duo bezels mounted at their existing paths:
bash scripts/generate_app_store_1_6_1_refresh.sh
sh scripts/validate_app_store_assets.sh
bash scripts/verify_locked_app_store_screenshots.sh
python3 -m unittest discover -s scripts/tests -v
bash -n scripts/*.sh ci_scripts/*.sh
cmp TestFlight/WhatToTest.en-US.txt AppStore/Version-1.6.1/What-to-Test.txt
git diff --check
```

The final iPad captures repeat the same test without rebuilding after setting
the status-bar time to 9:41, output `iPadCaptureFinal`. All three runs and exact
commands are in their build.json files. The seven refreshed cards are new review
candidates; new `SHA256SUMS` records reproducibility and does not imply owner or
Apple approval. Existing approved lock files retain their original values.

## Release boundary

Keep PR #32 draft. No upload, metadata mutation in ASC, Cloud start, physical
installation, main merge, App Review submission or production publication is
included. The signed archive/IPA and version/build remain unchanged. TestFlight
hardware checks and future exact-source Cloud validation remain outstanding.

## Final checks and provenance limits

| Check | Result |
| --- | --- |
| Corrected iPad complete marketing capture | 1 passed / 0 failed / 0 skipped; exit 0; gate input hashes stable |
| iPhone complete marketing capture | 1 passed / 0 failed / 0 skipped; exit 0; gate input hashes stable |
| Final iPad 9:41 capture | 1 passed / 0 failed / 0 skipped; exit 0; native inputs unchanged (see below) |
| Asset validator | Pass: 105 screenshot JPEGs, IAP review and icon |
| Historical approval hashes | 23/23 unchanged |
| New candidate and native-source hashes | 19/19 and 9/9 pass |
| Original artwork preservation | All 162 earlier tracked artwork files byte-identical |
| App/project preservation | All 85 inputs match the unchanged signed archive |
| Selective refresh inventory | Exactly seven changed cards and twelve original byte matches |
| Native-source orientation guard | Nine valid inputs pass; retained LeftBottom fixture is rejected |
| Existing tooling tests | 30 passed, zero failures |
| Shell syntax, note sync, diff checks | Pass |
| Local review gallery | 19 images decode; seven original/current comparisons, keyboard navigation, downloads and mobile layout pass |

The final iPad timestamp-only capture has `source_unchanged_during_run: false`
because artwork-script inputs changed during that run. Its application and test
inputs all match the earlier clean passing capture runs; no native input changed.
Retain that global drift flag rather than relabeling it. The clean iPhone and
iPad capture runs above both report stable gate hashes. A fresh native fingerprint
audit confirms all 85 app/project inputs and all current capture-test inputs.

The full 254/0/4 iPhone/iPad/Duo regression results are the prior runs at `4ec5f61`.
This follow-up changes only the marketing capture driver among native test files;
that class was excluded from those full suites and is verified separately here.
No new complete native regression matrix or archive rebuild was performed.
The current capture summaries report no runtime-warning entries; build logs
retain the existing SDK `invalidDigitCount(94232)` and debugger-version/noURL
diagnostics. Prior full-suite UIKit/StoreKit warnings remain in their old logs.

`asset-validation-final.log`, `tooling-tests.log`, `source-orientation-guard.json`,
`final-audit.json`, `gallery-browser-check.json`, and all family preview images
are retained in the local evidence folder. `FirstRender-iPad/` preserves the
incorrect first compositions for diagnosis; they are absent from the final
review set. The HTML review file is retained in the sibling `ArtworkFix/` folder
as `Screenshot-Gallery-Build80.html`, with original-versus-current controls.
The earlier gallery HTML remains available for historical comparison.
