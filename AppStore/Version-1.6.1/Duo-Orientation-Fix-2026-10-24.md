# Duo Simulator orientation repair — 2026-10-24

Final native/test/tooling source: `4ec5f61034749ab59a205c68e54c287968057d76`.
Status: repaired; final full iPhone, iPad and Duo suites each pass **254/0/4**.
The four skips remain the existing physical PhotoKit-only checks. This record
supplements the [initial release verification](Verification-2026-10-24.md) and
preserves every earlier failed run. No application behavior, signing, version,
bundle identifier, production StoreKit ID or release artwork changes.

## Reproduction and cause

The unchanged four-case retry reproduces 0 passed / 4 failed / 0 skipped. Each
case stops at the original eight-second landscape-window predicate. The retained
original free-review diagnostic contains one main window, 466 × 678 points,
after the requested landscape rotation. Selecting another app window therefore
does not explain this reproduction.

On this Xcode 27.1 / iOS 27.1 Duo Simulator, assigning
`XCUIDevice.shared.orientation` does not reliably rotate the actual scene. An
[upstream native reproduction and control-event investigation](https://github.com/appium/appium-ios/pull/81)
identified the Simulator receiver's orientation-picker event. A Swift
implementation in `FrameWinkUITests/DuoSimulatorOrientation.swift` uses that
protocol only inside the Simulator UI-test runner. The four original cases now
reach their downstream product assertions and pass, with unchanged application
inputs, assertions and eight-second predicates. The older personal-frame
landscape/swipe/portrait round trip also passes unchanged.

The helper detects an available hinge sensor before using the workaround,
selects the cover display for a deterministic fixture-suite baseline, and sends
the Simulator control event after synchronizing XCTest's reported orientation.
It fails if the input transport cannot be created. Dispatch success alone never
satisfies the existing real-window geometry checks. Ordinary iPhone/iPad retain
XCTest's normal orientation path. The transport is compiled out for physical
device targets and is outside the app target. This is private Simulator tooling
and may need adjustment when Xcode changes.

## Scope of the passing assertions

- Both personal and automatic review pages: exclusion exposes Hidden from Frame
  above the temporary Undo bar, the control remains tappable, and its list opens.
- More/unfold fixture: the panel remains after five seconds, duration changes
  through actual input, playback stays running, and normal auto-hide resumes
  after dismissal.
- Blackout/division fixture: geometry change stays dark without a tap; deliberate
  input reveals Exit and it recedes.
- Existing rotation test: landscape swipes, hide/reveal, paused-photo continuity
  through return to portrait, and subsequent playback auto-hide.

The two division-transition tests still use the explicitly labeled DEBUG portrait
division fixture. Cover-panel native rotation drives production reflow; this does
not turn their synthetic division into evidence of a native physical fold.
Book/Tabletop captures and the TestFlight-only hardware checklist retain their
separate acceptance boundaries.

## Results and local evidence

All paths are relative to ignored `TestArtifacts/ReleasePrep-20261024/` in the
release worktree. Every run retains `build.json`, `build.log` and `result.xcresult`.

| Run | Passed | Failed | Skipped | Folder |
| --- | ---: | ---: | ---: | --- |
| Unchanged four-case retry | 0 | 4 | 0 | OrientationRetry-Baseline |
| Repaired original four cases | 4 | 0 | 0 | OrientationFix-Focused |
| Existing playback rotation round trip | 1 | 0 | 0 | OrientationFix-RoundTrip |
| First repaired-harness full iPhone | 253 | 1 | 4 | OrientationFix-iPhoneFull |
| First repaired-harness full iPad | 254 | 0 | 4 | OrientationFix-iPadFull |
| First repaired-harness full Duo, rotation included | 253 | 1 | 4 | OrientationFix-DuoFull |
| Unchanged iPhone privacy retry | 1 | 0 | 0 | OrientationFix-iPhonePrivacyRetry |
| First hittability repair, iPhone / Duo | 2 | 0 | 0 | OrientationFix-Privacy-iPhone / Duo |
| First hittability repair, iPad | 0 | 1 | 0 | OrientationFix-Privacy-iPad |
| Clipped-menu repair, iPhone | 1 | 0 | 0 | OrientationFix-PrivacyClipped-iPhone |
| Clipped-menu repair, iPad | 1 | 0 | 0 | OrientationFix-PrivacyClipped-iPad |
| Clipped-menu repair, Duo | 1 | 0 | 0 | OrientationFix-PrivacyClipped-Duo |
| Final complete iPhone | 254 | 0 | 4 | OrientationFix-iPhoneFinal |
| Final complete iPad | 254 | 0 | 4 | OrientationFix-iPadFinal |
| Final complete native Duo, rotation included | 254 | 0 | 4 | OrientationFix-DuoFinal |

All three final runs exit 0 and retain identical 134-input fingerprints from
committed source `4ec5f61`, unchanged throughout execution. Each final summary
retains three existing runtime warnings: UIKit's `_UIGravityWellEffectAnchorView`
hosting warning and two StoreKit fixture transaction-listener warnings. Existing
SDK `invalidDigitCount(94232)` and debugger-version/noURL diagnostics remain in
build logs. These runs are not warning-free. The 120-second test allowance and
eight-second orientation predicates remain unchanged. Source and result audit:
local `OrientationFix-final-audit.json`; unchanged archive/symbol exclusion audit:
local `OrientationFix-archive-input-audit.json`.

The passing focused run retains native app screenshots in its `attachments/`
folder. The original baseline bundle and its portrait-window diagnostic remain
available. No timeout increase, assertion removal or new skip is used.

All 85 application/project input fingerprints still match the signed archive
from `8bfb9bd2c525ec0fcacb733e805144b9dca69813`. The UI-test helper and harness
are new; the original statement that all native/test inputs match that archive
now applies only to the initial preparation, not this follow-up. No archive
rebuild is required for an unchanged application.

## Additional Larger Text test-driver repair

The first full regression after the orientation repair passes all four original
cases and the restored round-trip case. It exposes one additional test-driver
failure on iPhone and Duo: `testPrivacyActionsRemainReachableWithLargerText`.
The iPad full run passes. The failed iPhone hierarchy places Privacy & Data at
Y=742 with height 186, below the menu's visible container ending at Y=592. The
button already exists in the accessibility tree, so the test's existence-only
condition skips its scroll and attempts an impossible tap. An unchanged isolated
retry passes, consistent with menu-item creation/visibility timing, without
establishing an application defect.

The test now enters its existing bounded scroll when the button is not hittable,
requires hittability before ending the scroll, and asserts hittability before
tapping. All downstream privacy, disclosure, cleanup, confirmation and dismissal
checks remain. The first hittability repair passes on iPhone and Duo but exposes
an iPad gesture bug: the collection reports 1,376 points of content height beyond
its visible popover. Input based on that full height dismisses the menu. The
final driver intersects the collection frame with its nonempty clipping ancestors
and app window, then drags within that visible rectangle. The final focused case
passes on all three families. Both failed iterations remain retained.

This repair changes only the UI driver, with no new timeout or skip. The
previously excluded Duo rotation test is restored to `test_local.sh`;
the existing workflow test now rejects that exclusion on every family.

## Commands

```sh
# From the isolated release worktree; four unchanged baseline cases.
FRAMEWINK_BUILD_CACHE_VARIANT=release-duo-80 \
python3 scripts/build_local.py --unsigned \
  --output TestArtifacts/ReleasePrep-20261024/OrientationRetry-Baseline -- \
  -quiet -destination 'platform=iOS Simulator,id=D86731ED-CAA2-41E5-B1AF-78467918B1DA' \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 120 -maximum-test-execution-time-allowance 120 \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testAutomaticReviewHiddenPhotosRemainAboveUndoInLandscape \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewHiddenPhotosRemainAboveUndoInLandscape \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testBlackoutRemainsDarkWhenDivisionActivates \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testOpenFrameControlsSurviveUnfoldDuringPlayback \
  test-without-building
```

Repaired focused run: output `OrientationFix-Focused`, action `test`, all other
arguments identical. Round-trip run: output `OrientationFix-RoundTrip`, action
`test-without-building`, replace the four selectors with
`-only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPersonalFrameRotatesAndSwipeAdvancesToTheNextPhoto`.
Every expanded argument and source fingerprint is retained in that run's manifest.

```sh
# Full native Duo gate, including the older round-trip rotation case.
FRAMEWINK_BUILD_CACHE_VARIANT=release-duo-80 \
python3 scripts/build_local.py --unsigned \
  --output TestArtifacts/ReleasePrep-20261024/OrientationFix-DuoFull -- \
  -quiet -destination 'platform=iOS Simulator,id=D86731ED-CAA2-41E5-B1AF-78467918B1DA' \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 120 -maximum-test-execution-time-allowance 120 \
  -skip-testing:FrameWinkTests/StoreKitConfigurationTests/testStoreKitTestAskToBuyReturnsPendingWithoutUnlocking \
  -skip-testing:FrameWinkUITests/MarketingLandscapeScreenshotTests test
```

Ordinary iPhone: omit the cache variant, output `OrientationFix-iPhoneFull`,
destination `platform=iOS Simulator,id=DB4BE434-7E81-4019-9BDB-AAD6F7A1FA26`.
Ordinary iPad: variant `release-ipad-80`, output `OrientationFix-iPadFull`,
destination `platform=iOS Simulator,id=AD6D9220-2E34-4EC4-8083-CB0B1903BBA9`.
All other flags/actions are identical. The unchanged existing Ask-to-Buy and
marketing-utility exclusions apply equally to all three families.

The final complete reruns use the same commands at committed source `4ec5f61`,
with outputs `OrientationFix-iPhoneFinal`, `OrientationFix-iPadFinal` and
`OrientationFix-DuoFinal`. The first full runs and focused failed artifacts
remain unchanged. Focused privacy runs use one selector:
`-only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPrivacyActionsRemainReachableWithLargerText`
with action `test`; the unchanged retry uses `test-without-building`.

The updated local workflow tests pass 30/0. `bash -n scripts/test_local.sh` and
`git diff --check` pass. These checks validate the restored matrix selection;
no Ask-to-Buy or marketing-utility selection change was made.

No physical device was controlled. No upload, Cloud start, tester assignment,
App Review submission, merge, production website deployment or publication occurred.

## Release boundary

The automated landscape blocker is closed, including the restored round trip.
Keep release PR #32 draft for owner review and the remaining release gates.
Hardware acceptance for candidate 80 remains unrun and exclusively TestFlight.
The unchanged legacy artwork validator's 11-versus-10 source count remains a
known limitation; approved galleries pass and no new artwork upload is prepared.
The initial ordinary iPhone and StoreKit intermittency remains historical risk;
this repair does not establish its cause. All failed bundles are preserved.

No production source or archive rebuild was needed. The existing signed archive
and distribution IPA retain the original paths, UUID and SHA-256 in the initial
release report. No upload, Cloud start, tester assignment, App Review submission,
merge, production website deployment or publication occurred. Follow-up active-work estimate:
approximately 0.6 hours, excluding unattended Simulator runtime.

GitHub's existing Vercel integration automatically built a PR preview for
`242acbe087eec546307e3d4736adb21189d0a53b`. The API reports READY, Git source on
`codex/release-prep-2026-10-24`, target null (preview), and only its branch-preview
alias. This is automatic PR CI, not a production promotion. Subsequent documentation
pushes may refresh that preview. No production deployment was started manually.
