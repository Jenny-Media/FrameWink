# FrameWink 1.6.1 (80) release verification — 2026-10-24

Release artifacts and draft [PR #32](https://github.com/Jenny-Media/FrameWink/pull/32)
are prepared. **Keep the PR draft and stop before upload.** The four original Duo
landscape-precondition failures are resolved by a Simulator-only UI-runner input
repair, and the previously excluded rotation case passes. A subsequent Larger
Text menu-driver repair also passes. Final complete iPhone, iPad and native Duo
suites each pass **254/0/4**, including restored Duo rotation; see the
[follow-up record](Duo-Orientation-Fix-2026-10-24.md). Original
failed runs remain retained below. Physical acceptance remains TestFlight-only.

## Source and release selection

- Release branch: `codex/release-prep-2026-10-24`, fresh managed worktree. Existing checkouts were preserved.
- Fetched origin/main and confirmed it remained `73b85f6d7d008303d5c534c9eff0d04a433c75a9` immediately before push. This is PR #31's merge and includes `9f0cc83` and `80fddd9` control/blackout fixes.
- Initial build/test/archive source: `8bfb9bd2c525ec0fcacb733e805144b9dca69813`. Initial documentation head: `004d26e`. The later test-harness/tooling repair is committed as `4ec5f61034749ab59a205c68e54c287968057d76`; it changes no application or project/signing input. All 85 application/project fingerprints still match the signed archive. The application difference from main remains the build number.
- Read-only live ASC: public 1.6 (66), Ready for Distribution; latest TestFlight 1.6.1 (78), Complete / Ready to Submit, assigned to Jenny Media Internal; (76) Testing internally and externally. Cloud Archive 78 and Analyze 79 succeeded from `73b85f6`, with Xcode 27.1 (27A9275), macOS Golden Gate 27.0.1 (26A434). Internal post-action succeeded.
- Keep unreleased marketing version 1.6.1. Local build 80 exceeds all observed upload/Cloud numbers. No remote reservation was made; recheck before any later upload. Cloud controls its exported build number.
- Live Internal TestFlight workflow: automatic branch main, five native-folder rules, PR starts Not Enabled, manual starts Any Branches. The release branch push does not trigger distribution. No Cloud build was started in this task.

## Initial local checks (before UI-runner repair)

| Check | Passed | Failed | Skipped / result |
| --- | ---: | ---: | --- |
| Initial full iPhone, iOS 27.0 | 252 | 2 | 4 physical-only skips; retained failed run |
| Three isolated iPhone retries | 6 | 0 | 0; two cases per run, unchanged products |
| Complete iPhone rerun, iOS 27.0 | 254 | 0 | 4 physical-only skips |
| Complete iPad, iPadOS 27.0 | 254 | 0 | 4 physical-only skips |
| Dedicated native Duo, iOS 27.1 | 248 | 5 | 4 physical-only skips; full gate failed |
| Isolated Duo StoreKit retry | 1 | 0 | 0; same 120-second allowance |
| Local build-workflow tests | 30 | 0 | passed |
| Release Analyze / archive guard | — | 0 | passed |
| Signed archive / local App Store export | — | 0 | passed; no upload |
| Plists, StoreKit JSON, shell syntax, note sync, diff | — | 0 | passed |
| Three locked screenshot families + six approved 1.6 Duo files | — | 0 | passed |
| Supplemental legacy asset validator | — | 1 | existing 11-versus-10 landscape source-count mismatch |

The four intentional Simulator skips are the physical PhotoKit catalog, cover,
reopen-cache and distinct-photo navigation tests. The initial table uses Ask to
Buy and marketing-utility exclusions plus the pre-existing approved Duo rotation
exclusion. The later UI-runner repair restores rotation to the default Duo gate;
only the two shared exclusions remain. No original product assertion or timeout
was weakened. The menu-driver repair adds explicit visibility assertions.

The original iPhone failures were the automatic-album controller state wait in
`testLibraryChangesDoNotRestartActiveICloudPreparation` and Share hit testing in
`testFrameControlsPanelOffersTimingAndShare`. Each passed three separate isolated
unchanged-product retries (2 passed / 0 failed / 0 skipped per run). Their original
full-suite failures remain retained; the intermittent cause is unproven.

The first attempted isolated retry with `-test-iterations 3` selected a separate
compiler-cache identity without test products and failed before executing tests.
The correction removed that argument and ran the same existing products three
times. It is tooling evidence, not an app test pass or an additional product
failure. The matrix wrapper's original iPhone exit is 65. iPad and native Duo
were run separately after the shared Duo switched to another task's app;
remaining Duo tests use the dedicated release Simulator.

## Requested behavior and native Simulator scope

The initial iPhone suite passed all six viewport-region tests (including Book
and Tabletop), playback auto-hide policy, ordinary and divided blackout onset,
More across fixture unfold, blackout darkness on division activation, deliberate
tap/escape/recede, separated paused browsing, persistent playing controls, the
largest text size, and each one-tap duration choice. The explicit DEBUG geometry
and schedule-clock cases do not establish physical behavior.

Additional native iOS 27.1 Duo app-only captures use the actual Device Hub fold
controls and `smart-frame` sample scenario, with no geometry or clock overrides:
photo above/control below in Tabletop; photo left/control right in Book; same
paused San Francisco sunset photo 2 across rotation; companion swipe to Golden
Gate photo 3 and back to photo 2 with pause preserved; Resume and More; retained
More beyond five seconds after Closed → Fully Open while playing; actual 30s →
10s selection. The same native process survived the recorded sequence. This is
scoped Simulator evidence, not per-tick timer or hardware acceptance.

The shared Simulator later displayed Puzzle Box during the attempted timing
restoration/dismissal. That attempt is rejected as interference. An earlier MCP
tap delivered Home instead of the intended photo input; it is not an app-defect
claim. The black inner-display capture while Closed is rejected as an inactive
display. Accepted app-only PNG hashes, exact source, flags and rejected files are
in local `NativeDuo/provenance.json`. No private photos enter Git. Native and
fixture evidence remain labeled separately.

## Signed artifacts

Relative to the isolated worktree:

- Archive: `TestArtifacts/ReleasePrep-20261024/SignedArchive/FrameWink.xcarchive`.
- IPA: `TestArtifacts/ReleasePrep-20261024/AppStoreExport/FrameWink.ipa`.
- All logs, result bundles, source fingerprints, verification JSON and native
  captures: `TestArtifacts/ReleasePrep-20261024/` (ignored, retained locally).
- Archive uses the existing Apple Development signature and profile. The local
  exported IPA has a verified Apple Distribution: Jenny Media LLC (5736QK4NZX)
  signature, production application identifier and get-task-allow false.
- Both report 1.6.1 (80), `media.jenny.FrameWink`, minimum OS 15.0, families 1/2,
  Xcode build 27A9275, SDK iphoneos27.1 / 24A94232, production Lifetime ID, and
  no non-exempt encryption. Native reserved-region/division symbols are linked.
- App binary/dSYM UUID: `D1E87C87-5092-3D8B-ADEA-A9DCB8B3BD51` (arm64).
- IPA SHA-256: `0d5d4f5257238ae795e8bd959b71933a02a4a924370e032380847052c13bb7bb`.
- No StoreKit test configuration or DEBUG geometry, schedule-clock or physical
  acceptance flags appear in the Release app. Mac Catalyst, Mac compatibility
  and Vision Pro compatibility remain disabled. No signing setting, bundle ID,
  product ID or credential was changed.

Export options explicitly use method app-store-connect, destination export,
manageAppVersionAndBuildNumber false and uploadSymbols false. Export success is
local signing evidence; no upload validation or TestFlight processing of build
80 is claimed. Xcode Cloud remains the authoritative distribution builder.

## Exact commands

Commands ran from the isolated FrameWink worktree. Result/output paths below
are relative to it; compiler paths and full executed arguments are also retained
in each build.json.

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project FrameWink.xcodeproj -scheme FrameWink -showdestinations

FRAMEWINK_BUILD_EVIDENCE_ROOT="$PWD/TestArtifacts/ReleasePrep-20261024/LocalBuilds" \
FRAMEWINK_TEST_OUTPUT_ROOT="$PWD/TestArtifacts/ReleasePrep-20261024/SimulatorGate" \
FRAMEWINK_IPHONE_DESTINATION='platform=iOS Simulator,id=DB4BE434-7E81-4019-9BDB-AAD6F7A1FA26' \
FRAMEWINK_IPAD_DESTINATION='platform=iOS Simulator,id=AD6D9220-2E34-4EC4-8083-CB0B1903BBA9' \
FRAMEWINK_DUO_DESTINATION='platform=iOS Simulator,id=A5A7FC9E-DA0A-47A0-A540-7FB5FA1CE73F' \
bash scripts/test_local.sh
```

The script stopped after the failed iPhone run. Separate full gates preserve the
script's complete suite, 120-second allowances and exclusions:

```sh
# iPad; native Duo and iPhone rerun use the substitutions listed below.
FRAMEWINK_BUILD_CACHE_VARIANT=release-ipad-80 \
python3 scripts/build_local.py --unsigned \
  --output TestArtifacts/ReleasePrep-20261024/iPadGate -- \
  -quiet -destination 'platform=iOS Simulator,id=AD6D9220-2E34-4EC4-8083-CB0B1903BBA9' \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 120 -maximum-test-execution-time-allowance 120 \
  -skip-testing:FrameWinkTests/StoreKitConfigurationTests/testStoreKitTestAskToBuyReturnsPendingWithoutUnlocking \
  -skip-testing:FrameWinkUITests/MarketingLandscapeScreenshotTests test
```

For Duo: variant `release-duo-80`, output `DuoGate`, destination
`platform=iOS Simulator,id=D86731ED-CAA2-41E5-B1AF-78467918B1DA`, and the additional
existing `-skip-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPersonalFrameRotatesAndSwipeAdvancesToTheNextPhoto`.
For the iPhone full rerun: no cache variant, output `iPhoneGateRerun`, destination
`platform=iOS Simulator,id=DB4BE434-7E81-4019-9BDB-AAD6F7A1FA26`, no Duo-only skip.
All other arguments above are unchanged. The exact expanded commands are in
the corresponding build.json files.

```sh
# Three separate unchanged-product retries, attempt = 1, 2, 3.
python3 scripts/build_local.py --unsigned \
  --output "TestArtifacts/ReleasePrep-20261024/iPhoneRetry-$attempt" -- \
  -quiet -destination 'platform=iOS Simulator,id=DB4BE434-7E81-4019-9BDB-AAD6F7A1FA26' \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 120 -maximum-test-execution-time-allowance 120 \
  -only-testing:FrameWinkTests/AutomaticAlbumControllerTests/testLibraryChangesDoNotRestartActiveICloudPreparation \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testFrameControlsPanelOffersTimingAndShare \
  test-without-building

CI_XCODEBUILD_ACTION=archive sh ci_scripts/ci_pre_xcodebuild.sh
python3 scripts/build_local.py --sdk iphoneos --unsigned --configuration Release \
  --output TestArtifacts/ReleasePrep-20261024/ReleaseAnalyze -- analyze
python3 scripts/build_local.py --sdk iphoneos --configuration Release \
  --output TestArtifacts/ReleasePrep-20261024/SignedArchive -- archive
xcodebuild -exportArchive \
  -archivePath TestArtifacts/ReleasePrep-20261024/SignedArchive/FrameWink.xcarchive \
  -exportOptionsPlist TestArtifacts/ReleasePrep-20261024/ExportOptions.plist \
  -exportPath TestArtifacts/ReleasePrep-20261024/AppStoreExport

python3 -m unittest discover -s scripts/tests -v
bash -n scripts/*.sh ci_scripts/*.sh
plutil -lint FrameWink/Info.plist FrameWink/PrivacyInfo.xcprivacy FrameWink.xcodeproj/project.pbxproj
python3 -m json.tool FrameWink/Resources/FrameWink.storekit > /dev/null
bash scripts/verify_locked_app_store_screenshots.sh
(cd AppStore/Version-1.6/Screenshots/iPhone-Duo && shasum -a 256 -c APPROVED_SHA256SUMS)
bash scripts/validate_app_store_assets.sh
cmp TestFlight/WhatToTest.en-US.txt AppStore/Version-1.6.1/What-to-Test.txt
git diff --check
```

Signed archive and extracted-IPA apps each passed
`codesign --verify --deep --strict --verbose=2 APP_PATH`. Signature authority and
entitlements were inspected with `codesign -dv --verbose=4 APP_PATH` and
`codesign -d --entitlements :- APP_PATH`. UUIDs used `xcrun dwarfdump --uuid PATH`;
linked native APIs used `nm -u APP_BINARY`. All verification JSON is local.

## Warnings and remaining boundaries

Full family result bundles each retain three runtime-warning entries: UIKit's
`_UIGravityWellEffectAnchorView` hosting-hierarchy warning and two purchase-listener
warnings originating in `StoreKitConfigurationTests.swift`. The production
`PurchaseClient.swift` continues to listen to `Transaction.updates` at line 116.
The isolated Duo StoreKit retry retains one fixture listener warning. Do not
report these runs as warning-free.

Build logs retain SDK-build `invalidDigitCount(94232)` and debugger-version/noURL
diagnostics, plus the StoreKitTest SDK header's deprecated transaction-state
warning. The signed Release archive has the App Intents metadata-extraction
skipped warning because the target has no AppIntents dependency. Release static
analysis passed. All original warnings and failed result bundles are retained.

The initial supplemental artwork validator failed because the unchanged
`AppStore/Screenshots/Landscape/iPad-13-inch` has 11 JPEGs while its script expected
10. The later [artwork follow-up](Artwork-Verification-2026-10-24.md) resolves that
mismatch and a second stale ten-versus-seven iPad gallery inventory. It also
validates the current iPhone/Duo cards and their existing approval hashes. All
86 screenshots, IAP review image, icon and 23 locks now pass; all 162 tracked
artwork files are preserved byte-for-byte. The failed initial log remains retained.
The [later parity audit](Screenshot-Parity-2026-10-24.md) compares every visible
interface with build 80 and replaces seven outdated captures in a separate new
review gallery; twelve cards retain approved bytes. Original galleries and all
approval files remain intact. [View the complete revised gallery](Screenshot-Gallery.md).

PR #14 remains open/conflicting. Its unique 1.1 (30) signed local delivery,
September 18 submission and September 21 release/smoke history were reconciled
as dated PR evidence, with unrecorded device/OS detail explicit. Its obsolete
current-availability, old pending-state and whole-project-complete replacements
were not merged. Current release history and old snapshots remain distinct.

The initial native Duo full gate failed. Its StoreKit case passed in isolation;
these four UI cases stopped before their product assertions at initial source:

- `testAutomaticReviewHiddenPhotosRemainAboveUndoInLandscape`: shared helper at
  `FirstLaunchPrivacyUITests.swift:790`, `XCTAssertTrue(waitForLandscape())`.
- `testReviewHiddenPhotosRemainAboveUndoInLandscape`: same line 790 assertion.
- `testBlackoutRemainsDarkWhenDivisionActivates`: line 1280, same precondition.
- `testOpenFrameControlsSurviveUnfoldDuringPlayback`: line 1262, same precondition.

The [later Simulator input repair](Duo-Orientation-Fix-2026-10-24.md) resolves all
four preconditions and establishes their retained downstream assertions. It also
restores the older round-trip rotation case. The initial full Duo bundle remains
failed; do not relabel it as a pass. The first repaired-harness full runs then
expose the separate Larger Text menu-driver issue, whose failed iterations and
correction are retained in the follow-up record. Initial ordinary iPhone
intermittency remains a documented risk; its original causes were not established.

Hardware follow-up is exclusively the owner-authorized TestFlight binary and
`Hardware-Test-Checklist.md`: Duo pose/rotation/playing continuity, VoiceOver,
real PhotoKit/Limited/iCloud, sandbox purchase/restore/Family Sharing, storage,
foreground brightness/Auto-Lock, manual Guided Access, thermals and seven-day
soak, plus iOS/iPadOS 15 and 2 GB coverage. No physical device was controlled or
installed in this task. Simulator results do not close those checks.

No upload, Cloud start, tester assignment, App Review submission, merge, production website
deployment or App Store release occurred. A later merge can automatically upload
and distribute, so it requires separate owner authorization and an exact-source
Cloud/build audit. Build 80 has no ASC processing or hardware acceptance evidence.
