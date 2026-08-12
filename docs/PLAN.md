# Forty-hour execution plan

Update this file after every Codex milestone. Record active human/agent working
time rather than unattended calendar time.

## Budget

| Milestone | Budget | Actual | Status |
|---|---:|---:|---|
| 0. Contract and scaffold | 2 h | 1.5 h | Complete |
| 1. Zero-permission preview | 5 h | 3.75 h | In progress — picker/offline checks pending |
| 2. Frame engine | 6 h | 3 h | Complete |
| 3. Smart Reel curator | 10 h | — | Not started |
| 4. Wall Mode | 5 h | — | Not started |
| 5. Purchases | 4 h | — | Not started |
| 6. Hardening and release | 8 h | — | Not started |
| **Total** | **40 h** | **8.25 h** | **In progress** |

## Milestone 0 — Contract and scaffold

- [x] Xcode project is iPad-only and targets iPadOS 15.
- [x] Application and test targets build.
- [x] Production bundle identifiers and Jenny Media LLC signing team are set.
- [x] Repository folders follow the documented architecture.
- [x] Root navigation/state shell exists without premature feature code.
- [x] Bundled sample-photo asset location exists.
- [x] Current build/test command is recorded below.

Acceptance: a clean checkout builds and launches on an available iPad
Simulator.

Status: complete. The generic Simulator build passes, Xcode detects FrameWink
as an archivable app product, and the app installs and launches on the iOS 27
`iPad (A16)` Simulator.

## Milestone 1 — Zero-permission preview

- [x] First launch is implemented as a polished sample experience without Photos access.
- [x] Sample photos are clearly labelled as examples.
- [x] PHPicker supports selecting up to 100 personal candidates.
- [x] Imports are downsampled to display-appropriate local copies.
- [x] Import progress, cancellation, partial failure, and retry are implemented.
- [x] `Delete Imported Photos` removes files and derived records.
- [x] Import and deletion have compiling unit tests.

Acceptance: after import, a user can view personal photos in Airplane Mode and
can delete every app-controlled copy.

Status: implementation and all five unit tests pass on the iOS 27 `iPad (A16)`
Simulator. The first-launch sample experience was visually verified without a
Photos prompt. Picker interaction, offline playback, and delete-all UI
verification remain pending.

## Milestone 2 — Frame engine

- [x] Single-photo Fit and Fill layouts.
- [x] Two compatible portrait photos can be paired on a landscape display.
- [x] Tap/swipe previous and next.
- [x] Adjustable interval and pause.
- [x] Stable shuffle/order behavior.
- [x] Full-screen controls recede without making navigation undiscoverable.
- [x] Reduce Motion is respected.
- [x] Pure layout-selection tests cover faces and awkward aspect ratios.

Acceptance: a 30-photo fixture reel plays repeatedly without incorrect bounds,
stuck timers, or losing manual navigation.

Status: complete. The deterministic layout chooser produces bounded Fit, Fill,
face-safe fallback, portrait-pair, and rotated layouts. The pure frame-session
controller replays a 30-page fixture, wraps manual navigation, changes timing,
and pauses/resumes without timer drift. Frame Mode was visually exercised in
portrait and landscape on the iOS 27 `iPad (A16)` Simulator; controls recede to
an interaction hint and manual next navigation wraps correctly. All 18 project
tests pass. Real-device touch gestures, rotation, and long-running playback
remain release checks rather than blockers to the pure frame engine.

## Milestone 3 — Smart Reel curator

- [ ] High-confidence filters and basic quality signals.
- [ ] Burst and near-duplicate suppression.
- [ ] Vision face quality and saliency integration.
- [ ] Bounded similarity comparisons.
- [ ] Date/event diversity and recent/older balance.
- [ ] Layout fitness contributes to ranking.
- [ ] Review Suggestions grid.
- [ ] `Never Show Again` applies immediately and persists.
- [ ] Algorithm revision is persisted with cached scores.
- [ ] Ranking is deterministic under test.

Acceptance: 100 candidates produce a 30-photo reel in under 30 seconds on the
oldest target device, duplicate suppression exceeds 90% in fixtures, and at
least 80% of a small human-labelled evaluation set is considered displayable.

## Milestone 4 — Wall Mode

- [ ] Idle timer is disabled only during active Frame Mode.
- [ ] Original app-controlled display behavior is restored when leaving.
- [ ] Scheduled visual dimming and blackout work while foregrounded.
- [ ] Guided Access setup checklist uses truthful language.
- [ ] Wall setup includes power, ventilation, battery, cable, orientation, and
      reboot-recovery warnings.
- [ ] Current state survives normal app termination where practical.
- [ ] Seven-day real-device soak test begins.

Acceptance: repeated enter/exit and foreground/background transitions do not
leave global brightness or idle behavior in an unexpected state.

## Milestone 5 — Purchases

- [ ] Local StoreKit configuration contains a non-consumable Wall Mode product.
- [ ] Production product identifier is documented but not assumed.
- [ ] Verified transactions drive entitlement.
- [ ] Purchase, cancellation, pending, failure, restore, offline, revocation,
      and StoreKit-unavailable states are handled.
- [ ] App screens clearly distinguish free and paid behavior.
- [ ] Family Sharing configuration is documented.
- [ ] Purchase controller has unit tests using an injected client.

Acceptance: StoreKit Test purchase and restoration unlock Wall Mode, while all
failure states leave Free Smart Reel usable.

## Milestone 6 — Hardening and release

- [ ] Test on the oldest supported 2 GB target and one current iPad.
- [ ] Peak memory during 100-photo import/analysis is below approximately 300 MB.
- [ ] No visible slideshow hitching while background analysis is active.
- [ ] Accessibility labels, Dynamic Type where appropriate, contrast, and Reduce
      Motion are reviewed.
- [ ] Permission denial, Limited Photos, cloud-only, deleted asset, full disk,
      memory warning, thermal, and corrupted cache states are recoverable.
- [ ] App privacy responses and privacy policy match the implementation.
- [ ] App Store screenshots distinguish free and paid behavior.
- [ ] App Review notes explain Photos permissions and Wall Mode unlock.
- [ ] Seven-day soak results are recorded in `docs/TESTING.md`.
- [ ] Xcode Cloud clean archive succeeds and its post-action distributes to
      TestFlight.

Acceptance: release checklist passes with no critical known defect and no claim
contradicts `docs/PRODUCT.md`.

## Current build and test commands

```text
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/FrameWink-DerivedData CODE_SIGNING_ALLOWED=NO build

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/FrameWink-DerivedData CODE_SIGNING_ALLOWED=NO build-for-testing

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-DerivedData CODE_SIGNING_ALLOWED=NO test
```

## Current risks and blockers

- Product name `FrameWink`, app identifier `media.jenny.FrameWink`, test
  identifier `media.jenny.FrameWinkTests`, and Jenny Media LLC team
  `5736QK4NZX` are confirmed and configured.
- Production StoreKit product identifier is undecided.
- Public open-source license is undecided.
- Physical legacy-device test matrix must be acquired/confirmed.
- Xcode Cloud setup is blocked only at the cloud boundary: this local Git
  repository has no hosted remote yet, and the App Store Connect app record and
  account role have not been verified. Local implementation and validation
  continue while those inputs are pending. See `docs/DISTRIBUTION.md`.
- Installed Simulator runtimes begin at iOS 27. The app compiles with an
  iPadOS 15 deployment target; the unit-test target uses iOS 17 because the
  XCTest libraries bundled with Xcode 27 no longer link cleanly at 15.0.
- PHPicker cancellation, large/iCloud-backed selections, Airplane Mode, and
  delete-all behavior still require Simulator and real-device interaction.

## Timebox rule

At 32 active hours, Milestones 0–5 should be complete. Use the remaining eight
hours only for hardening and release. Move incomplete optional behavior to the
backlog rather than extending the MVP.
