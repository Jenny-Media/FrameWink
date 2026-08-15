# Forty-hour execution plan

Update this file after every Codex milestone. Record active human/agent working
time rather than unattended calendar time.

## Budget

| Milestone | Budget | Actual | Status |
|---|---:|---:|---|
| 0. Contract and scaffold | 2 h | 1.5 h | Complete |
| 1. Zero-permission preview | 5 h | 4.25 h | In progress — physical offline check pending |
| 2. Frame engine | 6 h | 4 h | Complete |
| 3. Smart Reel curator | 10 h | 6 h | Implementation complete — physical validation pending |
| 4. Wall Mode | 5 h | 3.5 h | Implementation complete — physical soak pending |
| 5. Purchases | 4 h | 3.75 h | Complete — physical purchase check remains a release gate |
| 6. Hardening and release | 8 h | 24.75 h | Local release candidate complete — cloud/App Store completion pending |
| **Total** | **40 h** | **47.75 h** | **In progress** |

## Milestone 0 — Contract and scaffold

- [x] Xcode project is universal and targets iOS/iPadOS 15.
- [x] Application and test targets build.
- [x] Production bundle identifiers and Jenny Media LLC signing team are set.
- [x] Repository folders follow the documented architecture.
- [x] Root navigation/state shell exists without premature feature code.
- [x] Bundled sample-photo asset location exists.
- [x] Current build/test command is recorded below.

Acceptance: a clean checkout builds and launches on available iPhone and iPad
Simulators.

Status: complete. The generic Simulator build passes, Xcode detects FrameWink
as an archivable app product, and the app installs and launches on iOS 27
iPhone 17 Pro Max and `iPad (A16)` Simulators.

## Milestone 1 — Zero-permission preview

- [x] First launch is implemented as a polished sample experience without Photos access.
- [x] Sample photos are clearly labelled as examples.
- [x] PHPicker supports selecting up to 500 personal candidates across sessions.
- [x] A first reel becomes playable from ten imports while later checkpoints
      refine up to 100 recommendations without replacing it with samples.
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
- [x] Album preparation never substitutes bundled samples for the chosen source.
- [x] Compact, wide, tall, and entitled large-window layouts respond to live
      geometry without adding settings.
- [x] Window reflow preserves a stable photo anchor, playback state, remaining
      interval, and display-history semantics.
- [x] System chrome and gesture guidance recede in Frame Mode; single-photo
      motion pauses during resize and respects Reduce Motion.

Acceptance: a 30-photo fixture reel plays repeatedly without incorrect bounds,
stuck timers, or losing manual navigation.

Status: complete. The deterministic layout chooser produces bounded Fit, Fill,
face-safe fallback, occasional portrait-pair/landscape-stack, compact single,
entitlement-gated event Mosaic, and rotated/resized layouts. The pure frame-session
controller replays a 30-page fixture, wraps manual navigation, changes timing,
and pauses/resumes without timer drift, including an interactive-resize hold
that preserves the remaining interval. Frame Mode was visually exercised in
portrait on the iOS 27 `iPad (A16)` Simulator with system chrome absent and a
clean photo-only state after both controls and guidance receded. Real-device
window resizing and long-running playback remain release checks rather than
blockers to the pure frame engine.

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

Acceptance: the first ten candidates produce a playable reel in under 30
seconds on the oldest target device, a 500-candidate import completes without
exceeding the memory gate, duplicate suppression exceeds 90% in fixtures, and
at least 80% of a small human-labelled evaluation set is considered
displayable.

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
- [ ] Peak memory during 500-photo import/analysis is below approximately 300 MB.
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
- [x] Xcode Cloud clean archive succeeds and its post-action distributes to
      TestFlight.

Acceptance: release checklist passes with no critical known defect and no claim
contradicts `docs/PRODUCT.md`.

Status: local hardening is complete; physical-device and cloud-boundary
acceptance remains open. The current iOS 27 iPad Simulator scheme passes 128
tests with one intentional physical-only PhotoKit test skipped, zero failures,
and zero runtime warnings. Coverage includes honest automatic-album and initial
personal-import preparation, responsive single/pair/stack/Mosaic layout,
resize anchor/timer/history continuity, immersive overlay behavior, and
blackout escape. Xcode static analysis completes without warnings after
excluding the StoreKit test bundle from the Analyze action, and an unsigned
Release device build succeeds. The built product is
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
display-history repeat reduction, a four-photo Mosaic layout, and a durable
active frame configuration. Automatic album images are downsampled to
2,560 pixels, cached separately, refreshed from PhotoKit change notifications,
and never mutate the Photos library. Apple Photos can fetch iCloud originals
when needed; failed items preserve a prior usable local copy.

Permission denial, revocation, partial automatic-album failure, corrupt album
metadata, deleted assets, display-history persistence, and configuration
persistence have automated recovery coverage. Actual Limited Photos behavior,
iCloud download behavior, large-album performance, change delivery,
memory-pressure behavior, thermal response, and slideshow smoothness during
real Vision work still require physical hardware.

Automatic-album configuration writes are transactional. Selecting a different
album or changing the automatic refresh policy updates live state
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

Large automatic albums now become useful progressively instead of blocking on
the full candidate pool. PhotoKit requests the 2,560-pixel representation used
by FrameWink's display cache, the synchronizer prioritizes a date-spanning
first batch, and durable records are checkpointed so an interruption resumes
from app-controlled copies instead of starting over. The initial batch produces
a playable reel while the complete album continues to download and improve
recommendations. A ready home preview also accepts
horizontal swipes before Frame Mode. The complete Simulator scheme passes 131
runnable tests plus one intentional physical-only skip with zero failures or
runtime warnings after these changes.

The first playable automatic-album stage now begins after ten representative
candidates instead of thirty, refines again at thirty, and then uses the
complete-album result. The existing reel remains usable during refinement.
Album choice is now a responsive Photos-familiar grid with square covers,
names, counts, and a selected checkmark. Covers use cancellable local PhotoKit
thumbnail requests and a bounded cache, so the album metadata grid still
appears independently of cover availability. The complete iPad Simulator
scheme passes 135 tests with two intentional physical-only skips, zero
failures, and zero runtime warnings. The grid was visually checked at both
iPad (A16) and iPad mini Simulator sizes, and the unsigned Release build
succeeds. Real-library cover behavior and time-to-first ten-photo reel remain
physical checks under B-004.

Immediate playback from that provisional reel now also repairs a stale internal
page count even when the responsive layout signature already matches. Manual
advance updates the stable photo anchor atomically so a simultaneous Frame Mode
geometry reflow cannot restore the prior page. The final complete Simulator
scheme passes 132 tests with two intentional real-PhotoKit physical-only skips,
zero failures, and zero runtime warnings. A configured-real-album regression on
the connected iPad Pro proves both the Next control and a subsequent swipe show
distinct cached photos from the current 30-photo reel.

A Debug-only screenshot harness now isolates its fixture state from normal app
data. It produces an upload-ready set of ten native 13-inch iPad JPEGs at 2064 x
2752 without alpha, plus an eleven-image source library, using bundled
project-owned media. The submission set explicitly orders three Free Smart Reel
screens before seven paid screens covering purchase/restore, automatic-album
privacy, Frame Settings, Mosaic, night scheduling, and honest mounted-iPad
guidance. Release builds ignore the harness. Marketing
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
- A physical iPad Pro 12.9-inch (3rd generation) on iPadOS 26.6 is now connected
  and has physical install/launch plus partial automated-test evidence. Older
  deployment-target coverage and the broader legacy-device matrix remain open.
- An iPad mini (6th generation) on iPadOS 27 is connected, registered to the
  Jenny Media LLC development team, signed, installed, and running the physical
  acceptance harness. Its real 653-item album prepared successfully and the
  process remained live at nominal thermal state.
- Milestone 3 now has on-device Vision and curator performance evidence, but
  real Photos/iCloud behavior, oldest-device coverage, and human-labelled
  displayability acceptance remain open as blocker B-004.
- Milestone 4 now has physical install, launch, rotation, and local-frame UI
  evidence. Idle-timer/Guided Access/thermal/brightness behavior and the
  seven-day mounted-device soak remain open as blocker B-005. A Debug-only
  physical acceptance harness and host monitor now automate app/process,
  idle-timer, Guided Access, thermal, battery, lock-state, and screenshot
  evidence while the physical safety and visual checks remain human-owned.
- Milestone 5's implementation, tests, production product, Family Sharing,
  pricing, storefronts, and Paid Apps agreement are configured. Local StoreKit
  purchase/restore/refund behavior passes on the physical iPad; a TestFlight
  sandbox account check remains part of B-004, not product setup.
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
- A real-library album-picker stall found after Full Photos authorization on
  the physical iPad is resolved: PhotoKit album/asset discovery no longer runs
  on the UI actor, album rows avoid eager per-album scans, failure/empty states
  are recoverable, and a physical-only ten-second UI regression now passes.
  Full selected-album synchronization acceptance remains under B-004.
- Physical count-only diagnostics traced an apparent one-photo album reel to
  Strict Offline: one of 326 originals was local and 325 required iCloud.
  PhotoKit's network-required result is classified correctly, the simplified
  experience allows the owner-authorized iCloud preparation, and the same album
  completed all 326 durable records without a refresh-loop reset. The completed
  run exposed and then verified a separate Vision-distance fix: the album now
  produces 86 ready photos instead of two.
- Installed Simulator runtimes begin at iOS 27. The app compiles with an
  iPadOS 15 deployment target; the unit-test target uses iOS 17 because the
  XCTest libraries bundled with Xcode 27 no longer link cleanly at 15.0.
- PHPicker cancellation and delete-all are covered in isolated Simulator UI
  flows. Large/iCloud-backed selections and physical Airplane Mode behavior
  remain real-device interaction checks.
- The content-first refinement replaces the mode dashboard with one primary
  action, one contextual secondary action, and one More menu. Frame playback
  hides captions and keeps only previous, pause/play, next, and More controls.
  The compact Frame Settings screen persists one active configuration, hides
  legacy Wall Mode/Strict Offline terminology, and keeps mounted-iPad guidance
  collapsed. The current full Simulator suite passes 128 tests with one
  real-PhotoKit UI test skipped by design, covering honest preparation,
  responsive composition/resize continuity, the independent hint/control
  lifecycle, deterministic swipe navigation, and blackout escape. The
  replacement build is installed on the physical iPad. The 326-photo
  iCloud-backed preparation and corrected 86-photo curated result now both have
  physical evidence.
- A second large-album physical pass resolved the remaining latency/interaction
  defect under B-018. The target-sized PhotoKit path sustained roughly 5–7
  prepared photos per second on the connected Pro and mini. The Pro exposed an
  initial 30-photo reel and enabled **Start Frame** while its full 1,925-item
  analysis continued; progress is visible on both the neutral backdrop and
  setup card, durable sync checkpoints survive relaunch, and the ready preview
  is swipeable before Frame Mode.
- B-019 is resolved on the connected iPad Pro. Count-only inspection confirmed
  30 unique selections and distinct cached images, then instrumented physical
  UI testing found and repaired the matching-signature/zero-page playback race.
  The configured real album now advances to a distinct photo with Next and to
  another distinct page with a swipe immediately after entering Frame Mode.
- The playback/source-state audit is complete. Speed and display-style edits
  now persist the photo source that is actually on screen and no longer
  reactivate a stale saved source. Saved-configuration source application is
  limited to launch and explicit configuration-ID changes; entitlement
  publication and background personal-photo curation no longer override a
  later user source choice.
- Automatic layout now attempts a compatible pair or stack on the anchored
  first page of a sufficiently large non-compact window, so expanding a live
  frame produces an immediately visible reflow when the photos support it.
  Single-photo Fit/Fill crops continue to recompute from live geometry without
  distortion, and compact windows remain single-photo.
- The complete iOS 27 `iPad (A16)` Simulator scheme passes 139 tests with two
  intentional physical-only skips, zero failures, zero expected failures, and
  zero runtime warnings. The unsigned generic iPadOS Release build succeeds.
  The signed audited Debug build is installed and launched over existing data
  on the connected iPad Pro and iPad mini 6. Human Stage Manager resize
  observation remains a required real-device check because XCTest cannot drag
  the window resize handle.

Album covers now use a bounded four-request PhotoKit queue, request 384-pixel
tiles through `PHCachingImageManager`, try up to six recent eligible local
assets before allowing Apple Photos to fetch the preferred iCloud-backed cover,
and invalidate both cover identity and image caches on library changes. Tiles
show distinct loading and unavailable states. The real-cover UI regression is
installed on both connected iPads but iPadOS timed out enabling XCTest
automation before the test body ran; B-020 records the remaining manual or
unlocked-device confirmation.

Single-photo playback now uses deterministic 3.5–7% zoom, zoom-out, and up to
1.8% pan plans that must preserve detected important regions. The movement
reaches its first endpoint within the active slide interval, pauses with
playback/resizing, and remains disabled for Reduce Motion and multi-photo
pages. Manual navigation adds a restrained 32-point directional dissolve.
Automatic tall layouts remain two-up in ordinary portrait windows, expand to
three around a 1:2 viewport, cap at four for exceptional tall/narrow geometry,
retain a 220-point minimum cell height, and retry smaller face-safe groups.
The complete Simulator scheme passes 145 tests with three intentional
physical-only skips, zero failures, zero expected failures, and zero runtime
warnings. A clean unsigned Release build and the archive-mode Xcode Cloud guard
pass. The signed Debug build is installed and launched on the connected iPad
Pro and iPad mini 6 without clearing their app data.

The owner has now manually confirmed on a physical iPad that album covers
appear progressively, Living Photo motion behaves as intended, 3–4-photo tall
stacks appear in narrow Stage Manager geometry, and important-content safety is
preserved. B-020 is resolved by that owner-observed real-library evidence.

Album discovery now returns each album's bounded recent eligible cover
candidates with its metadata, avoiding a second per-tile collection lookup.
The first eighteen covers are preheated, on-screen tile requests use the
measured tile width and display scale, and the existing four-request gate,
32 MiB cache, local-first policy, alternate-asset fallback, and cancellation
remain bounded. If no local candidate succeeds, every eligible candidate may
fall back through PhotoKit's iCloud-enabled request while the tile shows an
explicit cloud-loading state.

Multi-photo composition now audits visual occupancy. A photo must safely crop
full-bleed or occupy at least 78% of its tile; otherwise Mosaic retries a smaller
group and ultimately returns that item to a single-photo page. Pair and stack
paths continue to require safe full-bleed crops. Long-press targets are scoped
to each placement and open the native system share sheet for the exact image;
an equivalent VoiceOver custom action is exposed. Living Photo remains
deterministic at 4–7% scale and up to 2.5% pan, reaches an endpoint within the
slide interval, and is governed by a tested policy that disables it for Reduce
Motion, resize, pause, preview, and multi-photo scenes.

Frame playback avoids the top-leading window-control region and now uses a
receding top-right close control. Frame Controls exposes one **Share Photo** or
**Share Photos** action for the whole visible scene plus **Exit Frame**, while
long-press remains an exact-tile shortcut and the slideshow swipe recognizer
coexists with context-menu recognition. The album picker preserves an already
loaded catalog during background refresh, retains revision-keyed bounded cover
images across PhotoKit change notifications, and retargets preheating to the
measured tile pixel size. The complete iOS 27 `iPad (A16)` Simulator scheme
passes 153 tests with four intentional physical-only skips and zero failures.
The unsigned Release build, static analysis, and archive guard pass; built
`UIDeviceFamily` remains `[2]` (iPad only). A symbolicated ETTrace launch capture
recorded 0.226 seconds of active main-thread work, with about 0.031 seconds in
the largest FrameWink-specific slideshow construction stack and no album or
PhotoKit work on first launch. iOS 27 beta emitted two private UIKit context-menu
hierarchy warnings during the long-press UI test. The new real-library
close/reopen two-second timing regression is installed on the connected iPad
Pro, but iPadOS timed out enabling UI automation before the tests ran; B-021
records that non-blocking device-runner boundary.

Playback `More` now opens an anchored Frame Controls popover instead of a
cascading command menu. Display Style and Slideshow Speed are visible as direct
selection grids, the panel remains open while either setting changes, and Share
plus Exit Frame remain in the same surface. Focused UI regressions cover panel
reachability, direct Fit/5-second changes without a photo-source regression,
and blackout escape. The first release remains iPad-only; an iPhone adaptation
is recorded as a separate post-MVP product decision rather than widening the
release matrix during hardening. The final iOS 27 `iPad (A16)` Simulator scheme
passes 153 tests with four intentional physical-PhotoKit skips and zero
failures. The clean unsigned iPadOS 15 Release build succeeds. One Jenny Media
LLC-signed Debug artifact was installed and launched over existing data on both
the iPad Pro 12.9-inch (3rd generation) and iPad mini 6.

Compact-width inspection on the temporary iPhone compatibility build exposed
that the popover's adaptive sheet inherited the playback bar's white foreground
and defaulted to an oversized modal. The panel now establishes system semantic
colors, adapts to a bounded draggable sheet on iOS 16+, and presents Share as a
full-width prominent direct action. The iPad popover behavior and committed
iPad-only target remain unchanged.

Owner testing then found that an uncached album catalog could remain behind a
blank loading state for more than ten seconds. Album discovery now publishes
only fast collection metadata; cover-candidate scans and screen-sized images
start lazily for visible tiles through the existing four-request limiter. The
grid therefore becomes selectable before its covers finish, while in-memory
covers and candidate identifiers are reused when the picker is reopened and
invalidated on a real PhotoKit change. PHPicker remains the system UI for Free
Smart Reel photo selection because it cannot identify a persistent album for
automatic refresh. The physical regression now requires the first metadata
grid within three seconds and continues to verify progressive cover and reopen
cache behavior.

The compact Frame Controls sheet now uses one system-background surface without
a second grabber band. Share is a softer bordered action with geometrically
centered text, and a receding top-right close control exits Frame Mode without
opening More. A temporary iPhone 17 Pro Max compatibility run visually confirms
the single sheet edge and centered action; its project-family change was
reverted. The complete iPad Simulator suite passes 154 tests with four
intentional physical-PhotoKit skips and zero failures (158 total). Active work
for this refinement was approximately 2 hours. The exact final source is
installed and open on the physical iPad Pro, and a temporary compatibility
build is installed and open on the physical iPhone 17 Pro Max; the committed
release target remains iPad-only. The remaining risk is the
initial-catalog and cover timing on a large real iCloud Photos library, which
cannot be represented faithfully in Simulator and is covered by the tightened
physical acceptance checks.

Owner testing then exposed that a multi-photo scene changed the direct share
control into `Share Featured` plus an `Other Photos` menu. Frame Controls now
keeps one stable action: `Share Photo` for one image and `Share Photos` for a
collage. The latter sends all currently displayed images to the native share
sheet as one multi-item share; long-press still shares only the touched image.
A new UI regression proves that Mosaic presents one share action and removes
the featured/other split. The complete iPad Simulator scheme passes 159 tests:
155 passed and the same four physical-PhotoKit tests skipped intentionally. The
unsigned iPadOS 15 Release build also succeeds. Active work for this refinement
was approximately 0.5 hour. A temporary signed Release compatibility build of
the exact sharing source was installed and launched on the physical iPhone 17
Pro Max for owner testing; its device-family setting was then restored with no
project-file diff.

Real-device testing exposed that the production lifetime product was still
unavailable on both iPhone and iPad even though the Release artifacts used
`media.jenny.FrameWink.wallmode`. App Store Connect showed the root cause: the
all-region availability edit was still pending behind an enabled Save action.
After owner confirmation, that change was published successfully; the product
now reports Saved with 175 countries or regions, Family Sharing, and Add for
Review enabled. Both physical iPads were relaunched. The remaining check is
StoreKit sandbox propagation and price loading; the first non-consumable still
travels with the first app-version submission.

Local paid-feature testing no longer depends on that propagation. The existing
Debug physical-acceptance harness grants a process-scoped test entitlement
while retaining the real PhotoKit client, and is now installed and running on
both the physical iPad Pro and iPad mini 6. Release and TestFlight continue to
derive access only from verified StoreKit transactions. The harness discovery
gate was updated for Xcode 27's paired Wi-Fi metadata: it accepts only a paired
physical iPad and then proves current reachability with a read-only lock-state
query before building. Both device builds, installs, launches, and health
samples succeeded with live processes and nominal thermal state.

The presentation refinement removes the remaining configuration-dashboard
feel. Responsive Fit, Fill, pair, stack, and Mosaic decisions are automatic;
the only visible timing choices are literal `10s`, `30s`, `1m`, and `5m`, with
`30s` selected by default. Frame Controls now contains timing and one stable
scene-share action, while the receding top-right close control is the direct
exit. Frame Settings no longer duplicates album choice, review, layout, timing,
or manual refresh. It retains foreground display behavior, an optional night
schedule with its times behind disclosure, concise mounted-iPad guidance, and
local data controls. Legacy saved sources and album identifiers remain intact;
unsupported layout/timing values migrate to automatic presentation and a
visible timing choice.

The complete iOS 27 `iPad (A16)` Simulator scheme passes 158 tests with four
intentional physical-PhotoKit skips and zero failures out of 162 total. Two
private iOS 27 UIKit context-menu hierarchy warnings remain unchanged. The
unsigned generic iPadOS Release build, Xcode static analysis, and archive-mode
Xcode Cloud guard pass.
Five focused UI flows verify source integrity, blackout escape, direct timing
and sharing, one multi-photo share action, and the shorter Frame Settings
surface. The ten native 13-inch submission screenshots were regenerated and
visually checked; the obsolete saved-configuration asset is replaced by the
literal timing panel. The signed Debug acceptance build installed on both
physical iPads, but both were locked and refused only the foreground launch.
Active work for this refinement was approximately 1.25 hours.

The hand-picked collection refinement raises the cumulative PHPicker boundary
to 500 display-sized local copies, produces a first playable reel from ten,
and refines the active result at bounded checkpoints to at most 100
recommendations. The simplified home menu now routes source selection, picker
import, and review through one **Photos** sheet; destructive app-data controls
live under **Privacy & Data**. Frame Controls applies a **Photo Duration** tap
immediately, manual swipes follow the finger and transition directionally, and
safe Fit images receive restrained deterministic zoom without bypassing Reduce
Motion or resize suspension. Unsplash is not integrated: personal images remain
an explicit system-picker choice, and bundled examples remain project-owned or
licensed.

The final iOS 27 `iPad (A16)` Simulator scheme passes 166 tests with four
intentional physical-PhotoKit skips and zero failures out of 170 total. The
same two private iOS 27 UIKit context-menu hierarchy warnings remain. The
unsigned generic iPadOS Release build, static analysis, ten-screenshot
validation, and archive-mode Xcode Cloud guard all pass. Active work for this
refinement was approximately 3 hours. B-022 records the final device-state
boundary: the signed build installed over existing data on the physical iPad
Pro, but its locked screen refused only the foreground launch; the paired iPad
mini 6 was not reachable and therefore could not receive this exact build.
Wake and unlock either device, then rerun its `prepare` command. Large real
PHPicker selection, low-storage behavior, first-ten latency, Fit motion with
Reduce Motion, and finger-following swipe quality remain human device checks.

## Ten-photo sample refinement — 2026-08-14

- Status: implementation and local verification complete. Ten sanitized,
  publisher-supplied photos replace the three generated PNGs. Their real
  portrait/landscape dimensions flow through responsive layout; the shared
  loader, debug fixtures, curation tests, accessibility IDs, current App Review
  copy, asset record, and both screenshot libraries are aligned.
- Verification: 167 Simulator tests pass, four physical-PhotoKit tests skip by
  design, and zero fail out of 171. The unsigned Release build, static analysis,
  archive guard, built-product resource/privacy inspection, ten native
  submission screenshots, and eleven 1640 × 2360 source screenshots pass. The
  known iOS 27 context-menu and post-test `simctl` diagnostics are unchanged.
- Physical-install status: the exact signed build installed over existing data
  on the paired iPad Pro, but its locked screen refused foreground launch. The
  paired iPad mini 6 is visible over the local network but has not been unlocked
  recently and refused even installation. These are external device-state
  boundaries, not source, signing, or build failures. Unlock each device and
  rerun `prepare` for the remaining physical visual smoke check.
- Privacy/size: originals remain outside the repository and were not modified;
  every 2,048-pixel derivative is free of private embedded metadata. The full
  ten-photo JPEG set is approximately 5.1 MiB, smaller than the former three
  PNGs. Active work was approximately 1.5 hours.

## First-tap duration and compact-caption refinement — 2026-08-14

- Status: implementation and local verification complete. Frame Controls now
  writes through one playback binding and uses a panel-lifetime optimistic
  selection only for immediate feedback. Duration buttons have stable
  checkmark geometry and 48-point touch targets. Compact preview captions use
  viewport-aware type and bottom clearance instead of the iPad-only fixed
  offset.
- Verification: the rapid five-change duration regression and caption/card
  geometry regression pass on both iPad (A16) and temporarily compatible
  iPhone 17 Pro Max Simulators. The complete iPad Simulator scheme reports 169
  passed, four intentional physical-PhotoKit skips, and zero failures out of
  173. The unsigned generic-device Release build, static analysis, and
  archive-mode Xcode Cloud guard pass; the release product remains iPad family
  2 with iPadOS 15.0 minimum.
- Visual/install status: the ten 13-inch submission screenshots and eleven
  source QA screenshots were regenerated and inspected. The exact signed
  temporary compatibility source installed and launched on the physical iPhone
  17 Pro Max; its screenshot confirms the compact caption clears the setup
  card. The repository device family was restored after each compatibility
  build.
- Blocker: B-023 records two physical iPhone XCTest attempts that timed out
  enabling iOS Automation Mode before the one-tap test body ran. This does not
  invalidate the Simulator results or physical install. Manual first-tap
  confirmation on the installed phone remains the only device interaction
  check. Active work was approximately 1.25 hours.

## Native control and reversible-review refinement — 2026-08-14

- Status: implementation and local verification complete. Playback now shows
  Share, pause/play, and More while preserving finger-following swipe navigation
  and named VoiceOver previous/next actions. Frame Controls is a native Form
  with a four-option segmented Photo Duration picker. Dismiss-only sheets use
  leading Close actions; photo import uses a native modal Form; the home menu is
  symbol-labelled and grouped; local album covers use quiet placeholders; and
  both review sources provide a persisted five-second Undo for Never Show Again.
- Verification: the exact iOS 27 iPad (A16) Simulator scheme passes 172 tests,
  skips four intentional physical-PhotoKit checks, and fails zero of 176. The
  two existing private UIKit context-menu hierarchy warnings remain. The
  unsigned iPadOS 15 Release build, Xcode static analysis, archive-mode cloud
  guard, ten 2064 × 2752 submission screenshots, and eleven 1640 × 2360 QA
  screenshots pass. Visual inspection confirms one native popover edge, a
  centered title, native duration segments, and the direct playback share.
- Physical status: the signed exact source installed on the iPad Pro but could
  not launch while that iPad was locked. The paired iPad mini 6 was not
  reachable. Unlocking each and rerunning its scoped acceptance `prepare`
  command remains the device smoke check. Existing real Photos, oldest-2-GB,
  TestFlight sandbox, Xcode Cloud, and seven-day-soak gates remain open and are
  unchanged. Active work was approximately 2.25 hours.

## Universal iPhone and StoreKit retry refinement — 2026-08-14

- Status: implementation and local verification complete. FrameWink now ships
  as one iPhone/iPad target (`TARGETED_DEVICE_FAMILY = 1,2`) with iOS/iPadOS 15
  minimum. iPad remains the large-display experience; compact iPhone geometry
  intentionally prioritizes a readable single photo. Device-specific privacy,
  mounted-display, permission, and restart wording is now universal.
- StoreKit correction: directly launched Debug and Release builds use
  `media.jenny.FrameWink.wallmode`. The `.local` identifier remains confined to
  the scheme Test action and `SKTestSession`; normal Run no longer attaches the
  local fixture. A failed or empty product lookup exposes a retry action and
  can recover without restarting the app. Automated coverage proves that an
  unavailable product loads on the next request and restores the free state.
- Verification: the iPhone 17 Pro Max Simulator passes all 156 unit tests and
  17 UI tests, with four physical-PhotoKit UI checks skipped by design. The
  complete iPad (A16) Simulator scheme passes 173 tests, skips the same four,
  and fails zero out of 177. The universal unsigned Release build, static
  analysis, archive-mode Xcode Cloud guard, plist/JSON/shell validation, diff
  hygiene, built-product inspection, ten 6.9-inch iPhone screenshots, ten
  13-inch iPad submission screenshots, and eleven iPad QA screenshots pass.
  The two known private UIKit context-menu warnings and Xcode's post-test
  `simctl` diagnostic remain unchanged.
- Physical status: the exact signed Debug build installed and launched on the
  paired iPhone 17 Pro Max running iOS 27. Its built app reports device families
  1 and 2, iOS 15.0 minimum, the production app/product identifiers, and the
  bundled privacy manifest. It is running the normal Apple StoreKit sandbox
  path. The owner must still use Apple's account UI to confirm localized price,
  authorize the sandbox transaction, restore it, and exercise Family Sharing;
  those commerce steps cannot be automated or bypassed. Active work was
  approximately 2.5 hours.

## Compact edge-face composition refinement — 2026-08-14

- Status: implementation, local verification, and physical iPhone installation
  complete. Narrow portrait Fill now requires a comfortable important-content
  position as well as strict visibility. When source boundaries prevent that
  composition, FrameWink automatically uses whole-photo Fit. Centered faces
  retain full-bleed Fill, and wider iPad crop behavior is unchanged.
- Verification: all 158 iPhone unit tests pass. The complete iPad scheme passes
  175 tests, skips four intentional physical-PhotoKit cases, and fails zero of
  179. The focused 29-test layout suite, unsigned universal Release build,
  Xcode static analysis, and archive-mode Xcode Cloud guard also pass. The two
  known private iOS 27 UIKit hierarchy warnings and post-test `simctl`
  diagnostic remain unrelated and unchanged.
- Physical status: the exact signed Debug build installed over existing data
  and launched on the paired iPhone 17 Pro Max, iOS 27, with the production
  StoreKit sandbox path. Revisit the two owner-reported edge-face photos and
  confirm each switches to whole-photo Fit rather than clipping the subject.
  This final photo-specific visual judgment remains a human check because the
  private originals are not copied into the repository or automated artifacts.
  Active work was approximately 1 hour.

## Compact crop-retention refinement — 2026-08-14

- Status: implementation, full local verification, and physical iPhone
  installation complete. A compact single-photo scene now uses Fill only when
  at least 70% of the source remains. More severe aspect-ratio mismatches use
  whole-photo Fit even when Vision found no face or saliency rectangle. The
  prior edge-face placement rule remains additive, near-matching compact photos
  still fill, and established iPad/multi-photo composition is unchanged.
- Verification: the focused 31-test layout suite passes. Complete iPhone and
  iPad schemes each pass 177 tests, skip four intentional physical-PhotoKit
  cases, and fail zero of 181. The unsigned universal Release build, Xcode
  static analysis, and archive-mode Xcode Cloud guard also pass. Only the known
  private iOS 27 UIKit hierarchy warnings and post-test `simctl` diagnostic
  remain.
- Physical status: the exact signed Debug build installed over the existing
  reel and launched on the paired iPhone 17 Pro Max, iOS 27, using the normal
  StoreKit sandbox path. Revisit the owner-reported moon, dome, and statue
  photos in portrait and landscape and confirm FrameWink preserves the whole
  source instead of magnifying the incompatible crop. These private-photo
  judgments remain human checks; no attachment or device photo was added to
  the repository or automated evidence. Active work was approximately 1 hour.

## App Review candidate preparation — 2026-08-14

- Status: local release candidate complete; source publication and external
  App Store/Xcode Cloud setup remain in progress. The app target now ships as
  version 1.0 build 1, and the archive-mode CI guard rejects any other marketing
  version in addition to the established bundle, team, product, device-family,
  deployment-target, and privacy checks.
- Icon: a delegated three-variant image-generation pass produced and compared
  clean-gallery, integrated-wink, and compact-horizon marks at full and
  32-pixel sizes. The clean-gallery variant was selected, normalized to an
  opaque 1,024-pixel sRGB PNG, integrated into the asset catalog, and compiled
  into both iPhone and iPad icon renditions. Exact prompts and alternatives are
  retained under `Design/AppIconIterations/`.
- Screenshots: the ten-shot 1320 × 2868 iPhone and ten-shot 2064 × 2752 iPad
  submission sets were regenerated from the current app. Contact-sheet review
  found no clipping, blank scenes, stale display-style controls, private media,
  or misleading Free/Paid boundary. Every upload image is a JPEG without alpha.
  A standalone validation script now rechecks both exact filename manifests,
  counts, dimensions, alpha state, uniqueness, the IAP review image, and the
  production icon without booting a Simulator.
- Verification: the complete iPhone 17 Pro Max and iPad (A16) Simulator schemes
  each pass 177 tests, intentionally skip four physical-PhotoKit checks, and
  fail zero out of 181. The unsigned universal Release build, static analysis,
  unsigned local archive, plist/StoreKit/shell validation, archive-mode cloud
  guard, icon hash/dimension check, and diff hygiene all pass. The only runtime
  warnings are the two previously documented private iOS 27 UIKit context-menu
  hierarchy warnings; Xcode's successful test cleanup again reports its known
  internal `simctl` lookup diagnostic.
- Live release audit: App Store Connect still has no build or Xcode Cloud
  workflow, one obsolete iPad screenshot, stale iPad-only product copy/subtitle,
  blank App Review phone/email, unpublished privacy answers, and unset age-
  rating/content-rights declarations. Ten current iPhone screenshots are now
  uploaded but need ordering, and the required private IAP review screenshot is
  accepted. Xcode itself is signed out. Those externally mutable or publisher-
  attested items remain under B-009 through B-011. Active work for the local
  candidate was approximately 1.5 hours.
- EU compliance: App Store Connect marks Jenny Media LLC as a non-trader. The
  combination of an LLC, all-region distribution, and a paid IAP makes that a
  publisher/legal review item rather than an engineering assumption; B-024
  records the decision and any verification needed for EU storefronts.

## Live App Store and Xcode Cloud preparation — 2026-08-14

- Status: in progress. The App Privacy response is published, current universal
  copy and ordered iPhone/iPad screenshot galleries are live, content rights
  and the 4+ age rating are complete, and the private App Review contact is
  saved. The lifetime IAP is `Ready for Review` in Draft Submission 1. Build 6
  is intentionally internal-only and cannot be selected for customers. The
  submission-capable Build 8 succeeded from commit `037c4ab`; version 1.0 (8)
  and FrameWink Lifetime are together in a `Ready for Review` draft.
- Xcode Cloud: Build 1 succeeded on Apple infrastructure at commit `b8691b9`
  with Xcode 26.6 and macOS 26.6.2. `Validation` now analyzes and tests pushes
  to `main` on recommended iPhone and iPad destinations. `Internal TestFlight`
  is manual-only and archives with App Store Connect preparation, then
  distributes specifically to `Jenny Media Internal`.
- Build 3 failed before compilation because Xcode Cloud 26.6 exposed
  `CI_TEAM_ID` as Jenny Media LLC's App Store Connect team UUID, while Apple's
  current documentation describes the variable as the 10-character Developer
  Team ID. The project still resolved `DEVELOPMENT_TEAM = 5736QK4NZX`. The
  fail-closed guard now accepts those two verified identifiers and rejects all
  other teams before the archive rerun.
- Validation Build 2 passed static analysis and its shared build-for-testing
  source guard, then failed when Xcode Cloud reran the script in artifact-only
  `test-without-building` workers that do not contain the repository. The guard
  now skips only that exact missing-project worker phase; every phase that owns
  a source checkout still performs the full identity and privacy validation.
- Repository state: Xcode generated a project-level cloud manifest after the
  successful connection. It is committed with this release record so future
  clones preserve the product-to-cloud target mapping.
- Remaining legal decision: B-024 remains open. Apple and EU guidance strongly
  point toward trader status for an LLC selling a paid lifetime product, but
  the live declaration is intentionally unchanged until the owner decides.
- Active work for this live release pass is approximately 2.5 hours.

### Xcode Cloud archive and distributed-test repair — 2026-08-14

- `Internal TestFlight` Build 6 at commit `6f59253` completed its clean archive
  and TestFlight internal-distribution post-action. App Store Connect reports
  FrameWink 1.0 (6) as `Ready to Test` for `Jenny Media Internal`.
- Validation Build 5 analyzed successfully and ran 181 tests on recommended
  iPhone and iPad destinations. It passed 172, intentionally skipped four
  physical-PhotoKit checks, and exposed five deterministic failures: four
  StoreKit tests in artifact-only workers and one compact-height settings UI
  assertion.
- The StoreKit test catalog is now an explicit hosted-test resource, and Debug
  app startup defers the production StoreKit connection while a hosted XCTest
  configuration is active. A fresh iPad artifact-only run passes all four
  purchase/loading/refund/failure tests. The UI test now scrolls to the native
  `Mounted Display Tips` disclosure control and passes on iPad; the equivalent
  targeted iPhone run also passes.
- Validation Build 7 confirmed the compact UI fix and all non-StoreKit suites,
  but its iOS 26.5 artifact workers still could not expose the installed
  StoreKitTest catalog to `Product.products`. The suite now validates the
  bundled product contract structurally on every runner and reports explicit
  skips for the four runtime transactions only when that product is absent on
  an identified Xcode Cloud worker. Those runtime tests remain fail-closed
  elsewhere and pass locally, without skips, on both iPhone and iPad.
- The lifetime IAP is `Ready for Review` and is present in Draft Submission 1.
  Content rights are saved. Apple's internal-only Build 6 cannot be selected
  for customers, so the workflow was corrected to App Store Connect
  preparation. Build 8 succeeded from `037c4ab`, processed immediately, and is
  attached to version 1.0 in the same two-item `Ready for Review` draft. Final
  submission remains intentionally owner-gated and was not clicked.
- B-024 remains the only publisher/legal decision: whether Jenny Media LLC is
  an EU trader. No declaration was changed without the owner's choice.
- Validation Build 9 showed one Apple-infrastructure-only failure: the iPad
  (10th generation) worker's SpringBoard remained busy and denied all 17 UI
  test launches before test code executed. The identical clean manual retry,
  Build 10, succeeded in Analyze and Test on all eight destinations with 174
  passed, eight explicit skips, and zero failures out of 182. The cloud
  validation gate is closed.

### Submission-gate finalization — 2026-08-14

- Release control: App Store Connect now has version 1.0 saved for manual
  release. Approval will not automatically publish the app.
- EU compliance: the owner selected trader status for Jenny Media LLC and
  supplied the business contact details already approved for App Review. Apple
  is waiting for its email verification code; any later phone/document check
  and the final legal certification remain owner-gated under B-024.
- TestFlight preparation: Build 8 is attached to `Jenny Media Internal`, and
  the Account Holder is now its first tester. The paired physical iPhone 17 Pro Max,
  iPad Pro, and iPad mini 6 are visible to Xcode. The iPhone Mirroring session
  can open TestFlight; the iPad Pro currently contains the earlier local
  development build rather than TestFlight Build 8.
- Physical TestFlight smoke: iPhone Mirroring opened the installed version 1.0
  Build 8, completed TestFlight onboarding, loaded the paid automatic album
  with 86 prepared photos, started playback, and completed a manual swipe to a
  different photo. This proves launch, retained production entitlement,
  PhotoKit-backed preparation, playback, and navigation on the exact review
  binary; a new purchase, restore, refund, and Family Sharing remain untested.
- Submission audit: the submitted two-item package contains iOS 1.0 (8) and
  FrameWink Lifetime. App Store Connect reports version 1.0 `Waiting for
  Review`; manual release remains selected.
- Platform scope: the owner confirmed iPhone and iPad as the only supported
  first-release platforms. Public Apple-silicon Mac and Apple Vision Pro
  availability are disabled, and both `Jenny Media Internal` platform-testing
  options report `Not Available`. Xcode already disables Mac Catalyst and
  Designed for iPhone/iPad on Mac.
- Remaining follow-up gates are Apple's DSA verification/certification and
  exact-build sandbox purchase/restore, refund, Family Sharing, and physical
  iPad checks. These remain tracked while the submitted package waits for
  review.
- Documentation-only verification: `git diff --check` passes, and both Debug
  and Release target settings retain device family `1,2` while disabling Mac
  Catalyst and Designed for iPhone/iPad on Mac. No app binary changed, so the
  build and test suites were not rerun. Active documentation work was about
  0.3 hours; App Store Connect remains externally mutable and should be checked
  again if review or availability status changes.

### Public website launch — 2026-08-14

- Added a responsive public Next.js website under `website/` with landing,
  privacy, support, terms, robots, and sitemap routes. It reuses the production
  app icon and approved App Store screenshots and accurately describes the
  iPhone/iPad-only, local-first Free Smart Reel and $9.99 lifetime boundary.
- The site has no account, form, analytics, advertising, tracking script, or
  marketing cookie. The privacy page distinguishes ordinary Vercel hosting
  request processing from the app, which continues to have no Jenny Media LLC
  server.
- Local website validation passes: four Node tests, ESLint, the Next.js
  production build with all six public routes statically generated, and
  `npm audit` with zero known vulnerabilities.
- The Vercel project `framewink` uses Node 24 and `website` as its root.
  Final production deployment `dpl_6usSR2HTYPEuAa2WJJ4JfjejYgs8` from commit
  `4d89326` reached `Ready` with a clean Node 24 build, and
  `https://frame.jenny.media` serves the canonical site over HTTPS. The landing
  page, privacy, support, terms, robots, sitemap, and Open Graph image routes all
  returned HTTP 200 from the public domain. A root `.vercelignore` keeps Xcode
  sources, screenshots, and local artifacts out of the website upload.
- Automatic Git deployment remains pending authorization of the Vercel GitHub
  App for `Jenny-Media/FrameWink`. Xcode Cloud's Validation workflow also needs
  a Files and Folders exclusion for website-only changes. Neither item blocks a
  direct production website deployment.
- Active implementation, deployment, and validation time is approximately 2.1
  hours.

### Permanent price, website review, and marketing screenshots — 2026-08-14

- Status: implementation, production-price update, and public description
  correction are complete. The owner selected and
  confirmed a permanent $4.99 U.S. base price for
  FrameWink Lifetime while preserving the existing feature boundary and Family
  Sharing. App Store Connect now reports $4.99 in the United States, $4.24
  proceeds, and comparable prices across all 175 storefronts. The StoreKit
  catalog, deterministic purchase fixtures, product and distribution
  documentation, public website, and website regression tests use that price.
  Historical records of the former $9.99 plan remain intact.
- Local validation passes: the targeted 16-test purchase and StoreKit suite on
  both iPhone 17 Pro Max and iPad (A16) Simulators, six website tests, ESLint, the
  six-route static production build, `npm audit` with zero known
  vulnerabilities, and diff hygiene. The StoreKit transaction-update warnings
  in three direct StoreKitTest cases are unchanged test-harness warnings.
- The Xcode target now resolves
  `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO` in Debug and Release. Xcode
  destinations no longer contain an eligible compatible Vision Pro target, and
  the Xcode Cloud archive guard fails closed unless both Mac and Vision Pro
  compatibility switches remain disabled.
- All ten iPhone, ten iPad, eleven source-QA, and the private IAP review
  screenshot in the repository were regenerated from the current `$4.99`
  source state. `scripts/validate_app_store_assets.sh` passes, and contact-sheet
  inspection confirms distinct, populated screens. App Store Connect's already
  submitted galleries and private review image retain the former amount until
  Apple makes the submission editable.
- Three independent read-only website reviews covered visual quality,
  conversion/messaging, and accessibility/interaction. Their shared highest
  priorities were implemented: price and product-boundary accuracy, WCAG
  contrast and focus visibility, a working keyboard skip target, compact
  navigation, a hero launch CTA, shorter mobile FAQ pacing, 44-point touch
  targets, plain product language, route-specific metadata, image placeholders,
  and restrained motion that respects Reduce Motion. No launch-blocking visual
  or conversion finding remains; a broader future image set is optional polish.
- Production deployment `dpl_9HTSp5UmemJfy3WTT1wU3LFg8Bfk` reached `Ready`
  and is aliased to `https://frame.jenny.media`. The canonical Home, Privacy,
  Support, and Terms routes return HTTP 200; the live homepage contains `$4.99`
  and no `$9.99`. Final keyboard verification confirms the header availability
  link moves focus to the callout and the next Tab reaches its email action.
- After the owner's action-time confirmation, the submitted version 1.0
  description was corrected from `$9.99` to `$4.99` and saved in App Store
  Connect. A separate deterministic marketing-card generator now produces ten
  iPhone and ten iPad candidates from the native source captures. The cards use
  one benefit-led headline per image, real FrameWink UI, project-owned media,
  and the FrameWink palette; visual contact-sheet review and the App Store asset
  validator pass. Apple's `Waiting for Review` state prevents replacing the
  submitted screenshot galleries without first withdrawing the submission, so
  the marketing cards remain local candidates pending an owner decision or the
  next editable version. Active work is approximately 2.2 hours.

### Authentic landscape screenshot expansion — 2026-08-14

- Added a deterministic landscape UI capture test and regeneration script for
  a 13-inch iPad and 6.9-inch iPhone. The native source library now contains
  four distinct 2752 x 2064 iPad scenes and three distinct 2868 x 1320 iPhone
  scenes; the intentionally compact iPhone layout no longer wastes a slot on a
  duplicate Mosaic capture.
- Rejected the first AI-generated lifestyle draft because its generic tablet
  did not read as authentic Apple hardware. The replacement App Store cards
  use native FrameWink output directly, label it as an actual in-app screen,
  and contain no simulated device shell. The website is now iPad-first and
  uses the same native landscape captures for its hero and showcase.
- The expanded asset validator passes counts, dimensions, alpha, and uniqueness
  checks across the native and captioned portrait and landscape sets. Seven
  website regression tests, ESLint, and the static Next.js production build
  pass. Local browser inspection covers the settled hero and landscape/iPhone
  showcase. The owner subsequently withdrew version 1.0 so the galleries can be
  replaced; approval and upload are tracked below. Active work was approximately
  1.1 hours.

### Landscape-first gallery and authentic website pass — 2026-08-14

- Status: local implementation and verification complete; owner visual approval
  and App Store upload remain pending. The owner withdrew version 1.0 from
  review to make the galleries editable.
- Expanded the 13-inch iPad landscape capture from four to ten current native
  screens: single frame, Mosaic, review, automatic album selection, controls,
  zero-permission sample, night schedule, mounted guidance, lifetime purchase,
  and lifetime features. The proposed iPhone gallery remains ten portrait
  images so each family is presented in its natural geometry.
- Removed all pseudo-device shells from the marketing generators. Each card now
  labels and shows the unmodified native screen directly. Generated contact
  sheets are committed under `AppStore/Screenshots/Review/ContactSheets/` for
  owner review before any App Store Connect mutation.
- Reworked the local website hero: the wide yellow corner glow is gone, the
  oversized sentence headline is replaced by `Your photos. Beautifully
  framed.`, and `No second photo cloud.` is replaced by the connected promise
  `Your photos stay yours.` The hero uses a project-owned room background with
  a restrained, finite crossfade of actual landscape FrameWink screens, while
  the iPhone section shows actual portrait Frame and Review screens.
- Browser inspection passes at 1920 x 1080 and 500 x 1000. Seven website tests,
  ESLint, the static production build, the expanded UI capture, and the complete
  App Store asset validator pass. The owner then authorized Apple's Design
  Resources License, B-026 was resolved, and the temporary floating-screen hero
  was replaced by actual FrameWink captures composited into Apple's official
  13-inch iPad Pro landscape bezel. Active work was approximately 2.2 hours.

### Realistic lifestyle hero and portrait iPhone refinement — 2026-08-14

- Status: implemented and available in the retained local website preview.
  The owner rejected the first pristine room composition because the device
  lacked a believable physical relationship with the scene.
- Generated one new restrained apartment scene using the licensed official
  iPad-bezel composite as the product reference. The device now rests on a real
  tabletop stand with matching perspective, ambient light, contact shadow, and
  ordinary room texture. To protect product accuracy, the AI-rendered screen was
  replaced deterministically with exact FrameWink single-photo and Mosaic
  captures using the same perspective transform. The two otherwise identical
  scene assets crossfade only the screen content and still honor Reduce Motion.
- Added a Debug-only `portrait-frame` scenario that presents the bundled
  portrait city-tower sample as one iPhone frame page. The website now uses that
  native 1320 x 2868 capture instead of another stacked layout, and the iPhone
  heading is shortened to `Your photos, wherever you are.`
- Both iPhone 17 Pro Max and iPad Pro 13-inch Simulator Debug builds pass. The
  portrait scenario was launched and visually inspected on the iPhone
  Simulator. Seven website tests, ESLint, and the static production build pass.
  Active work was approximately 1.2 hours.

### Website and screenshot content audit — 2026-08-14

- Status: local implementation and verification complete; owner review and App
  Store Connect upload remain pending. The audit covers every image currently
  referenced by the website plus all proposed iPhone and iPad App Store cards.
- Playback imagery now uses deterministic Debug-only clean-frame states. The
  close button, playback bar, hint, and bottom options are absent from single-
  photo and Mosaic marketing captures. Native controls remain only where the
  card explicitly demonstrates timing, sharing, review, album selection,
  scheduling, mounted guidance, or purchase behavior.
- Removed artificial screenshot outlines, white figure cards, dark caption
  bands, and the nested-card presentation from the website and marketing asset
  generators. Images retain only restrained corner rounding and a shadow where
  separation from the page background is useful.
- Simplified the public copy around the direct product benefits: `Your photos.
  Beautifully framed.`, `Beautiful by default.`, `Made for the places you
  love.`, and `Your photos, wherever you are.` The iPhone showcase now pairs
  two clean playback captures instead of prioritizing controls or review UI.
- Rejected early blank/unsettled portrait captures during visual review. Both
  portrait capture scripts now wait six seconds by default and fail if a
  captured image has insufficient luminance variance, preventing blank cards
  from silently reaching the generated gallery.
- The replacement contact sheets pass visual inspection. The App Store asset
  validator, seven website tests, ESLint, and the static production build all
  pass. Active audit, recapture, and verification time was approximately 1.4
  hours.

### Subject-safe screenshot and website flow refinement — 2026-08-15

- Status: local implementation and verification complete; production website
  deployment and App Store Connect upload remain pending owner approval.
- Fixed the reported bird failure at the layout-policy level. Multi-photo
  placements now reject crops that retain less than 68% of the source, even
  when Vision produced no subject rectangle. The bundled white-bird sample also
  carries an explicit protected region covering the bird and its reflection,
  so it falls back to Fit instead of losing the head or body.
- Reworked deterministic screenshot fixtures to use more of the approved sample
  set. The iPad Mosaic now combines the aerial coast, spring flowers, open road,
  and sunset; review and album grids use the same brighter varied group. The
  primary iPhone frame shows the complete bird portrait, and the second frame
  uses the city tower instead of repeating the aerial image.
- Fixed the apparently blank website iPhone card by replacing it with a newly
  versioned Review Suggestions asset and loading both iPhone showcase images
  eagerly. The second card now visibly contains aerial, flower, and sunset
  review rows.
- Replaced the bare `1`, `2`, and `3` treatment in the camera-roll flow with
  compact Choose, Review, and Play symbols in restrained cards. The ordered-list
  semantics remain available to assistive technology without displaying the
  visually heavy numerals.
- Focused layout and sample-catalog tests pass on iPhone 17 Pro Max and iPad Pro
  13-inch Simulators. Landscape and portrait capture scripts pass their clean-
  chrome and blank-image guards; App Store asset validation, seven website
  tests, ESLint, production build, shell syntax, and diff hygiene pass. Active
  implementation and verification time was approximately 1.5 hours.

### Website image-cache invalidation — 2026-08-15

- Status: local implementation and browser verification complete; production
  deployment remains pending.
- Diagnosed the apparent return of the cut-bird Mosaic and repeated Taipei
  screenshots as stale Next.js image-optimizer output. The regenerated source
  WebP files were correct, but their reused public paths allowed an earlier
  transformed response to survive a development-server restart.
- Versioned the regenerated iPad showcase and lifestyle-scene filenames, wired
  both generation scripts to the new paths, and added regression assertions so
  the page cannot silently return to the stale paths.
- Seven website tests, ESLint, the static production build, generator shell
  syntax, asset dimensions, and browser rendering pass. The local hero now
  displays aerial, flower, road, and sunset imagery; the iPad showcase uses the
  same varied Mosaic and a distinct autumn-leaf controls example; the iPhone
  showcase uses clean bird and city-tower playback. Active work was
  approximately 0.4 hours.

### Website content-first showcase refinement — 2026-08-15

- Status: local implementation and verification complete; production website
  deployment and App Store Connect upload remain pending.
- Reduced the feature-card dead space by lowering the desktop card height from
  360 to 310 pixels and the number-to-title margin from 116 to 58 pixels, with
  proportional tablet and compact adjustments. The numbers remain useful as a
  scanning cue without floating apart from their content.
- Gave the deterministic Frame Controls capture its own bright autumn-leaf
  photo. It no longer repeats the aerial photo already visible in the adjacent
  four-photo Mosaic; the versioned website asset prevents the previous
  optimized image from reappearing through cache reuse.
- Replaced the iPhone Review Suggestions card with the clean, native city-tower
  playback capture. The iPhone showcase now demonstrates the primary product
  experience twice—whole-photo bird framing and clean tower playback—without
  transient controls or advanced setup UI.
- The ten-state iPad and three-state iPhone landscape screenshot workflow,
  App Store asset validation, seven website tests, ESLint, static production
  build, generator syntax, diff hygiene, dimensions, and local browser review
  all pass. Active implementation and verification time was approximately 0.6
  hours.

### iPad-first website positioning refinement — 2026-08-15

- Status: local implementation and verification complete; production website
  deployment remains pending.
- Removed the oversized two-screen iPhone showcase from the public homepage so
  the website keeps its visual emphasis on the primary iPad photo-frame use
  case. The App Store iPhone screenshot set remains available for customers who
  inspect the iPhone product page.
- Replaced the removed showcase with a compact compatibility note: `Also on
  iPhone`, `Works on iPhone too.`, and `The same private reel, adapted for a
  smaller screen.` This preserves clear universal-app positioning without
  asking the iPhone experience to compete with the iPad story.
- Added source-level regression coverage preventing portrait iPhone marketing
  captures and their former layout styles from returning to the homepage.
  Seven website tests, ESLint, the static production build, diff hygiene, and
  local browser review all pass. Active implementation and verification time
  was approximately 0.3 hours.

## Timebox rule

At 32 active hours, Milestones 0–5 should be complete. Use the remaining eight
hours only for hardening and release. Move incomplete optional behavior to the
backlog rather than extending the MVP.
