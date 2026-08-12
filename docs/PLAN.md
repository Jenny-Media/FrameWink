# Forty-hour execution plan

Update this file after every Codex milestone. Record active human/agent working
time rather than unattended calendar time.

## Budget

| Milestone | Budget | Actual | Status |
|---|---:|---:|---|
| 0. Contract and scaffold | 2 h | 1.5 h | Complete |
| 1. Zero-permission preview | 5 h | 3.75 h | In progress — picker/offline checks pending |
| 2. Frame engine | 6 h | 3 h | Complete |
| 3. Smart Reel curator | 10 h | 6 h | Implementation complete — physical validation pending |
| 4. Wall Mode | 5 h | 3 h | Implementation complete — physical soak pending |
| 5. Purchases | 4 h | 3.75 h | Complete — physical purchase check remains a release gate |
| 6. Hardening and release | 8 h | 7.5 h | Implementation complete — physical/cloud validation pending |
| **Total** | **40 h** | **28.5 h** | **In progress** |

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

- [x] High-confidence filters and basic quality signals.
- [x] Burst and near-duplicate suppression.
- [x] Vision face quality and saliency integration.
- [x] Bounded similarity comparisons.
- [x] Date/event diversity and recent/older balance.
- [x] Layout fitness contributes to ranking.
- [x] Review Suggestions grid.
- [x] `Never Show Again` applies immediately and persists.
- [x] Algorithm revision is persisted with cached scores.
- [x] Ranking is deterministic under test.

Acceptance: 100 candidates produce a 30-photo reel in under 30 seconds on the
oldest target device, duplicate suppression exceeds 90% in fixtures, and at
least 80% of a small human-labelled evaluation set is considered displayable.

Status: implementation complete; physical acceptance remains open. The pure
100-candidate fixture selects 30 photos in under one second and the bounded
Simulator analysis test processes 100 thumbnails in 0.24 seconds using the
conventional-signal fallback. A conservative run that attempted unavailable
Simulator Vision requests took 1.899 seconds with 54.6 MB peak resident-memory
growth. Duplicate/burst fixtures collapse all labelled duplicates. The picker,
analysis, review grid, immediate exclusion, curated playback, cache/reel
persistence, and relaunch flow were exercised end to end with three imported
photos. Physical Vision execution, the oldest-device 30-second/memory gate, and
a licensed human-labelled displayability set still prevent marking the full
acceptance criterion complete.

## Milestone 4 — Wall Mode

- [x] Idle timer is disabled only during active Frame Mode.
- [x] Original app-controlled display behavior is restored when leaving.
- [x] Scheduled visual dimming and blackout work while foregrounded.
- [x] Guided Access setup checklist uses truthful language.
- [x] Wall setup includes power, ventilation, battery, cable, orientation, and
      reboot-recovery warnings.
- [x] Current state survives normal app termination where practical.
- [x] Seven-day real-device soak-test record is initialized.

Acceptance: repeated enter/exit and foreground/background transitions do not
leave global brightness or idle behavior in an unexpected state.

Status: implementation complete; the physical soak remains open. FrameWink now
owns and restores only the idle-timer flag, and only while Frame Mode is active
in a foreground scene. The schedule evaluator provides foreground-only visual
dimming and blackout without changing system brightness or promising wake.
Configuration and ten commissioning checks persist locally. Injected-adapter
tests cover repeated activation, deactivation, foregrounding, backgrounding,
and restoration of a pre-existing idle-timer value. The Wall Mode setup and
lower safety/reboot checklist were visually inspected on the iPad Simulator.
Brightness appearance, Guided Access transitions, thermal behavior, mounting,
and the seven-day run require physical hardware under blocker B-005.

## Milestone 5 — Purchases

- [x] Local StoreKit configuration contains a non-consumable Wall Mode product.
- [x] Production product identifier and App Store Connect product are configured.
- [x] Verified transactions drive entitlement.
- [x] Purchase, cancellation, pending, failure, restore, offline, revocation,
      and StoreKit-unavailable states are handled.
- [x] App screens clearly distinguish free and paid behavior.
- [x] Family Sharing configuration is documented.
- [x] Purchase controller has unit tests using an injected client.

Acceptance: StoreKit Test purchase and restoration unlock Wall Mode, while all
failure states leave Free Smart Reel usable.

Status: complete. App Store Connect configuration and local implementation are
both complete; physical purchase behavior remains a release-validation item.
The Debug scheme uses the explicitly local, non-consumable
`media.jenny.FrameWink.wallmode.local` product, while Release uses the confirmed
`media.jenny.FrameWink.wallmode` production identifier. Verified StoreKit
2 entitlements and transaction updates gate all paid Wall Mode capabilities;
refunds and revocations restore app-owned display state without deleting the
free reel or cached automatic-album data.
StoreKit Test exercises product loading, purchase, `AppStore.sync`, refund,
Ask to Buy/pending, and simulated purchase failure. Injected-client tests cover
cancellation, successful and no-purchase restore, unavailable StoreKit,
unverified updates, revocation, and an offline StoreKit-verified entitlement.
The local purchase scenarios and entitlement gates pass on the iOS 27 `iPad
(A16)` Simulator. The paywall, $9.99 local price, visible Restore Purchases
action, included paid-scope copy, and recoverable StoreKit failure are covered
locally. The production non-consumable is App Store Connect Apple ID
`6800849862`, with a $9.99 U.S. base price, all 175 current and future
storefronts, English (U.S.) localization, and Family Sharing permanently
enabled.

## Milestone 6 — Hardening and release

- [ ] Test on the oldest supported 2 GB target and one current iPad.
- [ ] Peak memory during 100-photo import/analysis is below approximately 300 MB.
- [ ] No visible slideshow hitching while background analysis is active.
- [x] Accessibility labels, Dynamic Type where appropriate, contrast, and Reduce
      Motion are reviewed.
- [x] Fault-injected local seams recover from denied/Limited authorization
      states, cloud-only and deleted assets, failed persistence, and corrupted
      caches without losing the last durable photo/configuration state.
- [ ] Real-device Limited Photos, iCloud residency, storage exhaustion, memory
      warning, and thermal transitions are recoverable.
- [x] App privacy responses and privacy policy match the implementation.
- [x] App Store screenshots distinguish free and paid behavior.
- [x] App Review notes explain Photos permissions and Wall Mode unlock.
- [ ] Seven-day soak results are recorded in `docs/TESTING.md`.
- [ ] Xcode Cloud clean archive succeeds and its post-action distributes to
      TestFlight.

Acceptance: release checklist passes with no critical known defect and no claim
contradicts `docs/PRODUCT.md`.

Status: local hardening is complete; physical-device and cloud-boundary
acceptance remains open. All 100 shared-scheme tests pass. Xcode static analysis completes
without warnings after excluding the StoreKit test bundle from the Analyze
action, and an unsigned Release device build succeeds. The built product is
iPad-only with a 15.0 minimum, contains the opaque AppIcon and root privacy
manifest, contains no third-party framework or StoreKit test configuration, and
contains the production Wall Mode product ID and non-exempt-encryption
declaration. Source and binary inspection
found no developer networking, analytics, tracking, PhotoKit mutation, or
system-brightness mutation. The Photos usage description supports the paid
automatic-album flow; authorization is requested only after a user explicitly
chooses that feature.

The import store now repairs a missing or corrupt manifest, prunes records for
deleted local image files, eagerly decodes display images off the main thread,
and supplies bounded review thumbnails. Wall Mode no longer republishes an
unchanged visual state four times per second, curation progress is UI-throttled,
and optional Vision work is skipped at serious/critical thermal states. Tests
cover recovery and unchanged-state publication. Simulator UI review passed at
the largest text size with Increase Contrast and Reduce Motion enabled. The app
keeps Frame Mode controls visible when VoiceOver is enabled; Apple's first-run
VoiceOver tutorial prevented a complete spoken-navigation pass, so that remains
a physical accessibility check rather than a claimed acceptance result.

The slideshow now checks its schedule once per second, publishes session state
only for an actual visible page change, and preloads the next page through a
bounded four-image/80 MiB decoded-image cache. Duplicate loads are coalesced;
memory warnings cancel in-flight work, clear the cache, and prevent late results
from repopulating it. A 32.13-second iPad Simulator recording captured five
automatic dissolves without a sustained blank/spinner or overlapping captions.
This closes the known simulator transition defect but not the physical 2 GB
memory and smoothness gates under concurrent real Vision analysis.

The original paid-scope mismatch is resolved locally. A verified entitlement
now unlocks selected-album PhotoKit refresh, an unlimited eligible input pool,
display-history repeat reduction, a four-photo Mosaic layout, and multiple
album-aware saved configurations. Automatic album images are downsampled to
2,560 pixels, cached separately, refreshed from PhotoKit change notifications,
and never mutate the Photos library. Strict Offline disables network access for
image requests; failed/cloud-only items preserve a prior usable local copy.

Permission denial, revocation, partial automatic-album failure, corrupt album
metadata, deleted assets, display-history persistence, and configuration
persistence have automated recovery coverage. Actual Limited Photos behavior,
iCloud download behavior, large-album performance, change delivery,
memory-pressure behavior, thermal response, and slideshow smoothness during
real Vision work still require physical hardware.

Automatic-album configuration writes are transactional. Selecting a different
album or changing automatic-refresh/Strict Offline settings updates live state
only after the durable configuration succeeds, so a storage/write failure keeps
the active album, options, and reel usable. Album image refresh follows the same
rule: a changed cloud-only asset keeps its last good copy, metadata-write
failure removes newly committed images and preserves the prior cache, and
best-effort orphan cleanup cannot invalidate an already committed metadata
transaction.

Durable Never Show corruption now has an explicit non-destructive recovery in
both Free Smart Reel and paid automatic albums: reset only the local veto list,
keep the photo copies, and rebuild suggestions. A fault-injected manifest-write
test also proves failed persistence removes the just-committed image and leaves
the source retryable. Photo copies, automatic-album caches, and derived analysis
data are excluded from device backup and the resource flags are covered by
tests.

The shared scheme also runs an iPad UI test target with bundle identifier
`media.jenny.FrameWinkUITests`. It isolates launch state, proves Sample Mode
does not request Photos authorization, opens PHPicker only from the explicit
photo action, cancels the picker, and returns safely. A second isolated flow
loads a persisted personal reel from app-controlled local copies, displays it
in Frame Mode, confirms `Delete Imported Photos`, and verifies the app returns
to Samples with no delete action remaining. A third flow rotates the iPad to
landscape, enters Frame Mode, swipes to an exact next photo, returns to portrait,
and verifies navigation state survives rotation. The destructive and local-veto
reset controls expose at least 44-point label hit areas. The same target will
run inside Xcode Cloud's Test action.

The paid analysis cache now keys persisted signals to the asset content
revision, archives reusable Vision feature prints, skips image decode and Vision
for unchanged assets, uses bounded checkpoint frequency, and throttles paid
progress publication. Simulator regressions exercise both the curator and full
pipeline with 5,000 candidates. Xcode Cloud's pre-build archive guard is also
committed and validates the confirmed production IAP identifier before a
TestFlight archive.

A Debug-only screenshot harness now isolates its fixture state from normal app
data. It produces an upload-ready set of ten native 13-inch iPad JPEGs at 2064 x
2752 without alpha, plus an eleven-image source library, using bundled
project-owned media. The submission set explicitly orders three Free Smart Reel
screens before seven Paid Wall Mode screens covering purchase/restore,
automatic-album privacy, saved configurations, Mosaic, night scheduling, and
honest commissioning guidance. Release builds ignore the harness. Marketing
caption overlays remain optional polish rather than a release gate.

## Current build and test commands

```text
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/FrameWink-DerivedData CODE_SIGNING_ALLOWED=NO build

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/FrameWink-DerivedData CODE_SIGNING_ALLOWED=NO build-for-testing

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-DerivedData CODE_SIGNING_ALLOWED=NO test
```

## Current risks and blockers

- Product name `FrameWink`, app identifier `media.jenny.FrameWink`, test
  identifiers `media.jenny.FrameWinkTests` and `media.jenny.FrameWinkUITests`,
  and Jenny Media LLC team
  `5736QK4NZX` are confirmed and configured.
- Production StoreKit product identifier is confirmed as
  `media.jenny.FrameWink.wallmode`.
- Family Sharing is confirmed for the production non-consumable and enabled in
  the local StoreKit test configuration.
- Public open-source license is undecided.
- Physical legacy-device test matrix must be acquired/confirmed.
- Milestone 3's physical Vision, oldest-device performance, and human-labelled
  displayability acceptance checks remain open as blocker B-004. Simulator
  conventional analysis, deterministic curation, and UI integration are not
  blocked.
- Milestone 4's physical idle-timer/Guided Access/thermal/brightness behavior
  and seven-day mounted-device soak remain open as blocker B-005. All schedule,
  persistence, state-restoration, and setup-copy work is independently verified.
- Milestone 5's implementation, tests, production product, Family Sharing,
  pricing, storefronts, and Paid Apps agreement are configured. A physical
  StoreKit purchase/restore check remains part of B-004, not product setup.
- The public GitHub remote and App Store Connect app record are configured.
  Repository-scoped Xcode Cloud access is owner-approved and successfully
  connected. The GitHub App is restricted to `Jenny-Media/FrameWink`. Xcode is
  waiting at its Apple Account authentication sheet before it can create the
  first workflow; B-010 tracks that remaining login boundary. Local
  implementation and validation are unaffected.
- The public privacy-policy/support URLs and monitored support email are
  confirmed and B-007 is resolved.
- B-008 is resolved locally: the paid implementation and paywall now match the
  authoritative automatic-album, scale, repeat-avoidance, layout, and saved-
  configuration contract. Physical PhotoKit validation remains under B-004.
- Installed Simulator runtimes begin at iOS 27. The app compiles with an
  iPadOS 15 deployment target; the unit-test target uses iOS 17 because the
  XCTest libraries bundled with Xcode 27 no longer link cleanly at 15.0.
- PHPicker cancellation and delete-all are covered in isolated Simulator UI
  flows. Large/iCloud-backed selections and physical Airplane Mode behavior
  remain real-device interaction checks.

## Timebox rule

At 32 active hours, Milestones 0–5 should be complete. Use the remaining eight
hours only for hardening and release. Move incomplete optional behavior to the
backlog rather than extending the MVP.
