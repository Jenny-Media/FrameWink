# Test strategy and release record

## Automated tests

### Milestones 0–1 verification record — 2026-08-11

- Generic iPad Simulator app build: passed with no compiler warnings.
- Unit-test bundle build: passed with no compiler warnings.
- Simulator execution: five tests passed with zero failures or skips on the
  iOS 27 `iPad (A16)` Simulator.
- Four `PhotoImportServiceTests` cover bounded downsampling and
  persistence, partial failure, cancellation cleanup, and delete-all removal of
  images plus derived records.
- `BundledSampleImageLoaderTests` verifies that all three loose PNG resources
  load through the same bundle-file path used by the sample slideshow.
- First launch was visually verified in portrait without a Photos permission
  prompt. The bundled photo, sample label, title, privacy button, and photo
  picker entry point are visible within the iPad bounds.
- Runtime verification found and fixed two preview defects: fill-sized sample
  media expanded the root layout beyond portrait bounds, and `Image(name)`
  searched only the missing asset catalog rather than the copied PNG files.
- Static built-product inspection confirms `MinimumOSVersion = 15.0`,
  `UIDeviceFamily = [2]`, all three sample images are bundled, and no Photos
  usage-description key is emitted.
- Source scan found no photo-library authorization request, networking API,
  analytics reference, or StoreKit implementation.

The installed Xcode 27 toolchain only has iOS 27 Simulator runtimes. The app
target remains iPadOS 15; the test runner target is iOS 17 to match the minimum
version of XCTest bundled with this toolchain.

### Milestone 2 verification record — 2026-08-11

- Full Simulator suite: 18 tests passed with zero failures, skips, expected
  failures, or runtime warnings on the iOS 27 `iPad (A16)` Simulator.
- Seven `FrameLayoutChooserTests` cover Fit, centered Fill for panorama and
  square inputs, an edge-positioned face, unsafe multi-face fallback, paired
  portraits, and reflow after rotation.
- Six `FrameSessionControllerTests` cover drift-free timer catch-up,
  pause/resume, previous/next wraparound, a repeated 30-page fixture, page-count
  changes, and interval changes.
- Frame Mode was visually verified in portrait and landscape. The full-screen
  entry and exit controls render within safe areas, controls recede after four
  seconds to a persistent tap/swipe hint, automatic advance works, and manual
  next navigation wraps around the three-photo sample.
- Reduce Motion follows the system accessibility environment in both page and
  control transitions; its pure non-animated branch compiles and the remaining
  system-toggle behavior is a real-device interaction check.
- A fresh non-test launch emitted no FrameWink-owned errors or faults. The sole
  launch-time error was the iOS 27 Simulator's PointerUI service-port message.
  CoreVideo pixel-buffer errors appeared only while the hosted ImageIO tests
  were executing and did not reproduce during a fresh app launch.

Verification command:

```text
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-DerivedData CODE_SIGNING_ALLOWED=NO test
```

Still required on real hardware: touch/swipe and rotation checks, a sustained
30-photo playback run, foreground/background transitions, and memory/thermal
observation on the oldest supported device class.

### Milestone 3 verification record — 2026-08-11

- Full Simulator suite: 33 tests passed with zero failures, skips, expected
  failures, or runtime warnings on the iOS 27 `iPad (A16)` Simulator.
- Eight `SmartReelCuratorTests` cover high-confidence filters, strongest burst
  and duplicate winners, fixed-input determinism, hard exclusions, date/event
  caps, explicit recent/older representation, layout-fitness ranking, and a
  100-candidate/30-selection fixture.
- Five `LocalCurationStoreTests` cover revision invalidation, corrupted
  disposable caches, durable exclusions, cancellation with reusable partial
  signals, immediate reel updates, and refusing to persist an empty reel.
- Two `VisionPhotoAnalyzerTests` prove the bundled images always yield bounded
  conventional signals and exercise 100 sequential thumbnail analyses.
- The final 100-thumbnail Simulator fallback run took 0.24 seconds. A prior
  conservative run that attempted the iOS 27 Simulator's unavailable Espresso
  Vision backend took 1.899 seconds and increased peak resident memory by
  54.6 MB; both are inside the provisional 30-second/300-MB gates. These
  measurements do not substitute for a physical legacy iPad.
- PHPicker was exercised end to end using three photos placed in the Simulator
  library. All three imported, persisted, and produced review suggestions. The
  review grid rendered, `Never Show Again` removed one selection immediately,
  the two-photo reel played, and both the reel and exclusion survived relaunch.
- Runtime inspection caught and fixed an empty-reel defect: one unavailable
  optional Vision request could previously discard otherwise usable
  conventional signals. Vision enrichments now fail independently, and an
  all-rejected selection yields an actionable error instead of black playback.
- iOS 27 Simulator Vision requests are skipped because its backend repeatedly
  reports Espresso-context creation failures. Face-capture quality, saliency,
  and feature-print execution must be verified on physical hardware; their
  deterministic consumers are fixture-tested in Simulator.

Still required: physical Vision execution, the complete 100-photo performance
and peak-memory run on the oldest supported iPad, and a licensed human-labelled
displayability/duplicate evaluation set.

### Milestone 4 verification record — 2026-08-11

- Full Simulator suite: 43 tests passed with zero failures, skips, expected
  failures, or runtime warnings on the iOS 27 `iPad (A16)` Simulator.
- Four schedule/checklist tests cover evening dimming, overnight blackout across
  midnight, inactive/disabled schedules, and all required safety topics.
- Three controller tests verify idle-timer ownership only during foreground
  Frame Mode, idempotent repeated transitions, restoration of a pre-existing
  value, and immediate schedule refresh after configuration changes.
- Three local-store tests verify schedule/checklist persistence, safe corrupted
  settings fallback, and normalization of invalid time/opacity values.
- The Wall Mode setup screen was visually inspected on Simulator. The paid
  preview boundary, three schedule times, dimming strength, foreground-only
  limitation, Guided Access wording, and lower cable/orientation/
  Auto-Brightness/Guided Access/restart-recovery checks render within the sheet.
- The app does not write `UIScreen.brightness`; visual schedules are black
  overlays. Blackout suppresses its dormant interaction hint, while a tap can
  still reveal Frame Mode controls so the user is not trapped.

Physical checks still required: actual Auto-Lock prevention/restoration,
Guided Access status changes, foreground/background visual transitions,
perceived dim/blackout appearance, thermal response, charging/mount safety, and
the seven-day soak.

### Milestone 5 verification record — 2026-08-11

- Full Simulator suite: 58 tests passed with zero failures or skips on the iOS
  27 `iPad (A16)` Simulator.
- Four `StoreKitConfigurationTests` use the bundled local StoreKit file to load
  the $9.99 non-consumable, complete a verified purchase, call
  `AppStore.sync`, verify current entitlement, process a refund, exercise Ask
  to Buy/pending, and inject an App Store purchase failure.
- Ten injected-client `PurchaseControllerTests` cover startup with an offline
  verified entitlement, purchase success, cancellation, pending, failure,
  successful and no-purchase restore, StoreKit-unavailable state, unverified
  updates, and revocation.
- Four `WallModeControllerTests` confirm paid access is required and that losing
  entitlement immediately restores the idle timer and clears visual dimming.
- The local product identifier is
  `media.jenny.FrameWink.wallmode.local`. It is configured only for Debug;
  Release intentionally has an empty product ID pending the production choice.
- The paywall was visually inspected with the local $9.99 product. It shows the
  current paid Wall Mode behavior, preserves full-quality Free Smart Reel copy,
  exposes Restore Purchases, and labels automatic album refresh/unlimited
  sources/additional configurations as planned rather than included.
- A simulated launch without an active StoreKit purchase session produced the
  recoverable `Unable to Complete Request` path. The paywall remained usable
  and explicitly stated that the free Smart Reel was unchanged.

The immutable production identifier and Family Sharing policy are confirmed.
Creating the product, configuring pricing/localizations, and exercising
purchase/restore/refund in TestFlight sandbox remain App Store Connect work.

This Milestone 5 record describes the narrower build verified on August 11. The
paid-scope completion record below supersedes its planned-feature paywall copy.

### Milestone 6 verification record — 2026-08-12

- Full Simulator suite: 62 tests passed with zero failures or skips on the iOS
  27 `iPad (A16)` Simulator.
- Three `LocalImportedPhotoStoreTests` verify that a corrupt manifest rebuilds
  from valid imported JPEGs, records for deleted image files are pruned, and a
  review thumbnail is downsampled to the requested bound.
- `WallModeControllerTests` verifies that repeated refreshes do not publish an
  unchanged visual state. The controller still reacts immediately when the
  schedule state actually changes.
- Xcode static analysis completes with no diagnostics after the unit-test bundle
  is excluded from the Analyze action. An unsigned Release build for generic
  iOS devices also succeeds.
- Built-product inspection confirms an iPad-only `media.jenny.FrameWink` app
  with minimum OS 15.0, a compiled opaque 1,024-pixel AppIcon, a root
  `PrivacyInfo.xcprivacy`, no local `.storekit` file, and the production
  `media.jenny.FrameWink.wallmode` Wall Mode identifier.
- The Release executable links Apple system frameworks only. Source inspection
  found no `URLSession`, developer URL, analytics/tracking SDK, PhotoKit change
  request, `UserDefaults`, or `UIScreen.brightness` write.
- At the largest Simulator text size, the setup controls and Frame Mode caption
  remain visible and usable; button labels may wrap without clipping. Increase
  Contrast and Reduce Motion remained legible and functional. The generated app
  icon was also verified on the iPad Home Screen.
- Enabling VoiceOver keeps Frame Mode controls visible instead of letting them
  recede. Apple's first-run VoiceOver gesture tutorial appeared, so spoken
  traversal and activation are still a physical-device release check.
- Review cells now retain bounded 640-pixel thumbnails rather than full imported
  images, eager ImageIO decoding runs off the main thread, curation progress is
  throttled to roughly 10 UI updates per second, and unchanged Wall Mode state
  is no longer republished at 4 Hz. These code-level performance fixes do not
  replace a physical Instruments capture.
- Optional Vision enrichments are skipped under serious or critical thermal
  state; conventional local curation still produces a reel.

### Paid-scope completion verification record — 2026-08-12

- Full shared-scheme Simulator suite: 101 tests passed with zero failures, skips, expected
  failures, or runtime warnings on the iOS 27 `iPad (A16)` Simulator.
- The final unsigned generic-device Release build and Xcode static analysis
  both complete without diagnostics after the paid-scope changes.
- Five `AlbumSyncServiceTests` cover hidden/screenshot filtering, Strict
  Offline cloud-only behavior, preservation of a last-good copy when a changed
  asset is unavailable offline, stable-ID replacement, persisted burst
  metadata, removal of cache files for deleted assets, and transactional image
  rollback when metadata persistence fails.
- Three `LocalAlbumSourceStoreTests` cover configuration/record persistence,
  orphan pruning, corrupt metadata recovery, and cache-only deletion.
- Eight `AutomaticAlbumControllerTests` cover entitlement gating, explicit
  authorization, denied and Limited state handling, sync/curation,
  PhotoKit-change refresh, revocation, and transactional album/setting writes
  that preserve the active configuration and reel after persistence failure.
- Paid-pipeline and curator tests prove candidates beyond the free 100 limit are
  analyzed, local display history persists without per-slide write churn, and
  recently/repeatedly shown candidates receive a repeat penalty. A 5,000-photo
  bounded-similarity fixture completes in 0.49 seconds, while a complete
  5,000-candidate synthetic pipeline completes in 1.38 seconds with ten signal
  checkpoints and requires zero image loads on its unchanged second refresh.
- Cached analysis is keyed by the PhotoKit asset modification revision. Matching
  content restores conventional signals and an archived Vision feature print
  without decoding; changed content invalidates the cache and requires fresh
  analysis. The algorithm revision is now 2 so older incomplete caches rebuild.
- Layout/configuration tests cover bounded four-photo Mosaic geometry and
  entitlement-gated persistence, activation, update, deletion, and album IDs for
  multiple frame configurations.
- The automatic source requests read access only after the paid user action,
  observes only while entitled/configured, excludes hidden photos/screenshots,
  never issues a Photos-library mutation, and caches display-sized JPEGs in a
  separate deletable directory. Strict Offline passes network access disabled
  to PhotoKit; non-strict mode may let Apple Photos fetch iCloud originals.
- Simulator unit seams verify the state machine, storage, and absence of an
  algorithmic 5,000-item limit. Real authorization prompts, Limited Photos
  selection, iCloud residency, PhotoKit change delivery, Vision execution,
  storage consumption, and 1,000/5,000-asset device performance remain physical-
  device checks under B-004.
- The updated app installs and launches on the booted iPad Simulator without a
  Photos prompt. A portrait screenshot exposed and then verified the fix for a
  truncated `Add Photos` action; the settled launch log contains no FrameWink-
  owned error or fault beyond the known Simulator PointerUI service message.

### Slideshow performance-hardening verification record — 2026-08-12

- The shared scheme remains green after the transition and local-reel UI changes: 101 tests pass
  with zero failures, skips, expected failures, or runtime warnings on the iOS
  27 `iPad (A16)` Simulator. The unsigned generic-device Release build, Xcode
  static analysis, and the Xcode Cloud release-identity/privacy preflight also
  pass.
- The slideshow schedule check now runs once per second instead of four times
  per second. `FrameSessionController.tick` publishes state only when the
  visible page changes, including no-op coverage for one-page reels and elapsed
  intervals that wrap to the current page.
- A main-actor `NSCache` retains at most four decoded display images with an
  80 MiB cost limit. The next page is loaded ahead, duplicate requests share one
  in-flight task, and a memory warning clears cached images, cancels in-flight
  work, and prevents a late result from repopulating the purged generation.
- Bundled sample images use eager ImageIO decode in a detached task. Imported
  and automatic-album images continue through their existing detached ImageIO
  loaders. Captions switch without animation so a photo dissolve cannot render
  two readable captions on top of each other.
- A 32.13-second, 1,640 x 2,360 Simulator recording at 60 fps captured five
  automatic 0.65-second transitions. Sampling at 10 fps found only one or two
  dark samples at the start of each monotonic dissolve and no sustained blank
  image, spinner, or caption overlap. This is useful UI evidence, but it does
  not close the physical 2 GB-device requirement for slideshow smoothness under
  concurrent real Vision analysis or prove the approximately 300 MB memory
  ceiling.

Recovery status for the current MVP:

| Scenario | Local evidence | Remaining check |
|---|---|---|
| Picker cancellation | Automated cleanup test plus isolated XCUI flow that opens and cancels PHPicker | Exercise a real provider item on physical iPad |
| Local playback and delete all | Isolated XCUI flow loads a persisted personal reel from app-controlled local copies, enters Frame Mode, confirms deletion, and verifies fallback to Samples; destructive/reset controls expose at least 44-point label hit areas | Exercise a real provider import and physical Airplane Mode playback |
| Partial/cloud-provider failure | Successful items persist and failure is retryable | Exercise an iCloud-only selection offline/online |
| Permission denial / revocation | Automated controller tests fall back from automatic display, preserve cached state, and recover after restored access | Exercise real prompt/settings transitions |
| Limited Photos | Automated controller test treats Limited as readable without another prompt and displays a configured visible album | Verify selected-album visibility on physical iPad |
| Automatic album cloud-only/partial failure | Strict Offline skips cloud-only items; an unavailable changed asset retains its exact prior record and cache file | Exercise real iCloud residency online/offline |
| Deleted automatic-album asset | Sync prunes its metadata and only its app-controlled cache file | Verify real PhotoKit change notification |
| Imported file deleted outside the manifest | Manifest is pruned and repaired by test | None for app-owned files |
| Full disk / failed persistence | Fault-injected free import and paid album metadata failures roll back new images; failed album/setting writes retain the active durable configuration, options, cache, and reel | Trigger storage exhaustion on a disposable device |
| Corrupt disposable cache/reel | Invalid cache is discarded or rebuilt by test | None |
| Corrupt durable exclusions | Error remains visible rather than silently forgetting `Never Show Again`; separate Free and automatic-album reset actions overwrite only the local veto list and rebuild suggestions without deleting photos | None for app-controlled storage |
| Memory pressure / thermal | Bounded thumbnails; an 80 MiB/four-image display cache; eager off-main decode; cancellation and late-result suppression after a memory warning; thermal fallback | Physical memory warning, Instruments, and thermal run |

Imported photo copies, automatic-album caches, and their derived analysis data
are excluded from device backup. Unit tests verify the exclusion resource flag
on both local storage trees; small wall and saved-frame settings remain eligible
for normal device backup.

The shared scheme now includes `FrameWinkUITests`. Its isolated first-launch
flow verifies Sample Mode appears without a Photos authorization alert, opens
PHPicker only after `Choose My Photos`, cancels the system picker, and returns
to Sample Mode. A separate bundled-media fixture goes through the production
private import store and saved-reel load path, displays the personal reel in
Frame Mode, confirms deletion from a 58-point accessibility target, and verifies
Samples/`Choose My Photos` return with no delete action. This closes the local
picker-cancellation, offline-copy playback, and delete-all UI reruns. A third
flow rotates the iPad to landscape, enters Frame Mode, performs a real swipe to
the exact next persisted photo, returns to portrait, and verifies that photo
remains active. Real provider, iCloud, Airplane Mode, physical touch, and
permission-transition behavior remains physical-device work.

The local release packet now includes the App Privacy answer and policy draft,
App Review notes, a ten-shot Free/Paid screenshot plan with ten visually checked
native 13-inch assets, localized TestFlight tester notes, and exact Xcode Cloud
workflow recipes. Stable support/privacy URLs, product setup, a hosted
repository, the Xcode Cloud workflow, and TestFlight installation remain
external release work.

### Photo import

- Downsampling produces bounded pixel dimensions.
- Stable identifiers do not collide.
- Partial PHPicker failure preserves successful imports.
- Cancellation does not leave orphaned temporary files.
- Delete-all removes imported files, reels, cached signals, and exclusions tied
  to those files.

### Curation

- Hidden/screenshots are excluded when automatically sourced.
- Burst/time buckets choose at most the configured number of winners.
- Near-duplicate fixtures collapse correctly.
- Ranking is deterministic for fixed input, revision, and seed.
- User exclusions are hard vetoes.
- Event/date caps and recent/older balance apply.
- Cancellation and resumption do not corrupt cached state.

### Layout

- Landscape, portrait, square, panorama, and extreme aspect ratios.
- Single Fit and Fill output valid crop rectangles.
- Paired portraits do not overlap and preserve each subject.
- Faces near every edge remain visible within tolerance.
- Multi-face photos do not use an unsafe crop.
- Screen rotation produces a valid new layout.

### Frame session

- Timer pause/resume and manual navigation.
- Entering/leaving restores owned state.
- Foreground/background transitions do not duplicate timers.
- End-of-reel behavior is stable.
- Reduce Motion disables or simplifies motion-heavy transitions.

### Purchases

- Verified purchased transaction unlocks.
- Unverified transaction does not unlock.
- Pending, cancellation, failure, revocation, refund, and StoreKit-unavailable
  states remain recoverable.
- Restore is idempotent.
- Free experience does not depend on StoreKit availability.

## Fixture-photo set

Use photos owned/licensed for testing and App Store bundling. Include:

- Strong landscapes and portraits.
- Two compatible portrait photos for pairing.
- Exact and near duplicates.
- Burst-like sequences.
- Blur and motion blur.
- Underexposure and overexposure.
- Screenshots, documents, and receipts.
- Panoramas and extreme crops.
- One and multiple faces.
- Faces near each edge.
- Photos with important non-face subjects.
- Mixed dates/events.

Bundled user-facing sample photos must be clearly labelled as examples. Test
fixtures that demonstrate poor quality do not need to appear in the sample reel.

## Real-device matrix

Minimum practical matrix:

| Device class | Purpose | Available? | Result |
|---|---|---|---|
| iPad Air 2 or iPad mini 4 | 2 GB legacy performance floor | TBD | — |
| iPad 5th generation or early iPad Pro | Secondary legacy behavior | TBD | — |
| A12-or-newer iPad | Modern baseline | TBD | — |
| Current iPad | Current OS and App Store behavior | TBD | — |

## Performance scenarios

For 100 picker candidates and representative 1,000/5,000-asset paid albums,
record:

- Time to first usable reel.
- Full indexing time.
- Peak resident memory.
- Jetsam/crashes.
- Thermal state.
- Transition smoothness during analysis.
- Cancellation and resume behavior.
- Storage used by imported images and caches.

Provisional gates:

- Personal 100-photo reel in under 30 seconds on the oldest target.
- Peak resident memory below approximately 300 MB during analysis.
- No visible slideshow hitching.
- No serious/critical thermal state during a 30-minute analysis test.
- All indexing work is cancellable and safe to resume.

## Privacy and networking test

- First launch produces no Photos authorization prompt.
- Sample Mode works with networking disabled.
- Imported Smart Reel works in Airplane Mode.
- Paid automatic albums prompt only after the explicit `Choose an Album`
  action; denial does not affect Sample Mode or Free Smart Reel.
- `PHPhotoLibraryPreventAutomaticLimitedAccessAlert` prevents iOS from showing
  its own recurring Limited-access alert at launch.
- Apple Photos—not a FrameWink endpoint—may download an iCloud original needed
  by an automatic album. Download-driven PhotoKit notifications must not restart
  preparation already in progress.
- Hidden photos and screenshots are excluded from automatic selection, and the
  app issues no PhotoKit mutation request.
- No developer-controlled endpoint or third-party SDK exists in the binary.
- Delete Imported Photos and Delete Automatic Album Cache remove the respective
  app-controlled photo files without changing originals.
- Privacy policy, App Privacy answers, and actual implementation agree.

## Seven-day unattended test

For each real device, record:

| Field | Value |
|---|---|
| Device/model | — |
| OS version | — |
| Source/reel size | — |
| Start/end | — |
| Power interruptions | — |
| App terminations | — |
| Manual recoveries | — |
| Memory/thermal observations | — |
| Result | Not run |

The record is initialized. No physical wall device has been assigned yet, so
the seven-day clock has not started; see blocker B-005.

Exercise normal slideshow use, overnight visual blackout, Wi-Fi loss, photo
source changes, foreground/background transitions, and at least one deliberate
app termination. Document reboot behavior separately because automatic relaunch
is not promised.

Release gate: at least 95% of devices/runs complete without unplanned manual
recovery.

## App Store release checklist

- [x] The build has a purpose-specific Photos usage-description key; App Review
  notes explain that it is used only after the paid automatic-album action.
- [x] Free and paid functionality are accurately described.
- [x] Restore Purchases is visible.
- [x] App Review notes give the Wall Mode product path and StoreKit test steps.
- [x] Privacy policy draft states no developer server/upload/analytics.
- [x] Privacy policy and support pages are published at stable HTTPS URLs in
      the public repository and saved in App Store Connect.
- [x] Ten native 2064 x 2752 submission JPEGs contain no alpha, clearly separate
      Free from Paid Wall Mode, and do not imply an ambient sensor, automatic
      Guided Access, reboot recovery, or another unavailable kiosk capability.
- [x] Compatibility copy says iPadOS 15+ rather than every old iPad.
- [x] Battery, heat, ventilation, and damaged-device guidance is present.
- [ ] Xcode Cloud clean archive and TestFlight installation succeed.

The executable `ci_scripts/ci_pre_xcodebuild.sh` is recognized automatically by
Xcode Cloud. Its validation path passes locally. Its archive path now validates
the confirmed production Wall Mode product identifier and also guards the Jenny
Media team, production bundle ID, iPad-only family, iPadOS 15 minimum, and both
privacy property lists.

## iPad Pro Simulator connection — 2026-08-12

The iOS 27 `iPad Pro 13-inch (M5)` Simulator
(`1BDA7ABF-4236-406E-8ACD-7E3B10569753`) was already booted. FrameWink built,
installed, and launched there as `media.jenny.FrameWink` (launch PID `73339`).
The settled first-launch screen showed the bundled Sample Photos experience and
no Photos permission dialog. This verifies the named Simulator target; it does
not satisfy physical iPad gates B-004 or B-005.

## Physical iPad smoke and automated test — 2026-08-12

Apple's `devicectl` reports a wired, paired physical iPad Pro 12.9-inch (3rd
generation), product `iPad8,5`, running iPadOS 26.6 with Developer Mode enabled.
The signed Debug build used Jenny Media LLC team `5736QK4NZX`, installed as
`media.jenny.FrameWink`, launched successfully, remained live, and visibly
rendered the bundled sample slideshow. The initial no-permission sample flow
therefore has physical-device smoke evidence.

The physical test run produced:

- All 98 unit tests passed.
- All 3 UI tests passed, including picker cancellation, persisted local-frame
  playback/deletion, swipe navigation, and portrait/landscape transitions.
- The 100-image Vision benchmark passed in 12.140 seconds with 0.0 MB reported
  peak growth, inside its 30-second gate.
- The 5,000-candidate curator benchmark passed in 1.363 seconds.
- All 4 local StoreKit configuration tests passed, covering Family Sharing
  metadata plus purchase, restore, pending, failure, and refunded-entitlement
  behavior. These use Xcode's local StoreKit session and do not replace a
  TestFlight sandbox account check.

This closes the physical install/launch gap but does not yet prove real PhotoKit
authorization/iCloud behavior, TestFlight sandbox purchase/restore, thermals,
Guided Access, Auto-Lock restoration, or the seven-day unattended soak. B-004
and B-005 remain open for those acceptance checks.

## Physical acceptance automation

`scripts/physical_acceptance.sh` now provides `prepare`, `verify-albums`,
`sample`, and `soak` commands. Its explicitly launched Debug harness grants only a local test Wall
Mode entitlement while retaining the production `PhotoKitLibraryClient`, so a
tester can exercise the real Photos prompt, Limited access, album changes, and
iCloud residency without making a purchase. Release and TestFlight builds do
not contain that behavior.

The harness writes a photo-free heartbeat containing foreground, idle-timer,
Guided Access, thermal, Low Power Mode, and battery state. The host monitor adds
process presence, reachability, lock-state output, and screenshots. All output
goes to ignored `TestArtifacts/PhysicalAcceptance/`; identifiers and private
test photos are not release artifacts. Exact owner steps and pass/fail criteria
for PhotoKit, TestFlight sandbox StoreKit, Family Sharing, Wall Mode, and the
seven-day run are in `docs/PHYSICAL_ACCEPTANCE.md`.

The initial automation validation on 2026-08-12 built and installed the harness
on the physical iPad. iPadOS correctly denied the foreground launch while the
iPad was locked, and a host sample recorded the device as connected with no
FrameWink process rather than producing a false pass. The complete iPad
Simulator scheme now passes all 102 unit tests and three runnable UI tests, with
the real-PhotoKit UI test intentionally skipped there. The acceptance environment also launched on Simulator and wrote an
active, nominal-thermal, idle-timer/Guided-Access heartbeat at its expected app-
container path.

After the iPad was unlocked, the physical harness launched and remained live.
The baseline screenshot showed Wall Mode Setup at `No album selected` with no
Photos prompt and `Choose Album` as the explicit authorization trigger. The
photo-free heartbeat reported the app active, nominal thermal state, battery at
95% while charging, Low Power Mode off, idle-timer ownership off outside Frame
Mode, and Guided Access off. The host heartbeat-copy destination was corrected
from a directory to an explicit filename, and a second sample captured every
field successfully.

After Full Photos access was granted, a synchronous per-album asset scan left
the picker on **Loading albums…** for more than ten seconds. Album and asset
discovery were moved off the UI actor, eager per-album scans were removed, and
recoverable error/empty states were added. The `verify-albums` physical-only UI
test then launched the real-PhotoKit harness, tapped **Choose Album**, and
observed the album list within its ten-second gate. Full test-album selection,
synchronization, iCloud, and change-notification acceptance remain open.
The command relaunches the interactive harness after XCTest completes so the
iPad is not left on the test runner's black screen or App Library.

A subsequent physical trial explained an apparent one-photo reel: the selected
album contained 326 images, but Strict Offline allowed only the one original
already resident on the iPad. PhotoKit returned `networkAccessRequired` for the
other 325 items. FrameWink now classifies that response as an iCloud-only skip,
shows the exact count plus **Allow iCloud Downloads and Refresh**, and refreshes
immediately when Strict Offline is disabled. The same physical album now shows
325 iCloud downloads needed rather than generic failures. The same physical
album then downloaded and committed all 326 private display copies after
explicit owner approval.

## Content-first refinement verification — 2026-08-12

- The complete iOS 27 `iPad (A16)` Simulator scheme passes 111 tests: 106 unit
  tests and five UI tests, with zero failures, expected failures, or runtime
  warnings. The sixth UI test is the intentional physical-only PhotoKit check
  and skips on Simulator.
- UI automation proves the sample home has one primary action and one
  contextual secondary action, maintenance is behind More, Frame Settings has
  no user-facing Wall Mode or Strict Offline control, picker cancellation stays
  permission-safe, local playback/deletion works after relaunch, and frame
  navigation survives landscape/portrait rotation.
- Unit coverage proves a legacy Strict Offline preference migrates to normal
  iCloud-capable behavior, the simple active frame configuration updates in
  place, and PhotoKit change notifications cannot restart an album preparation
  already in progress. A genuine change delivered after preparation becomes
  idle still triggers automatic refresh.
- Full-screen playback no longer displays technical source captions; its
  visible chrome is close, previous, pause/play, next, and More. Home and Frame
  Settings continue to expose source/status context before playback.
- The signed replacement build installed on the connected iPad Pro 12.9-inch
  (3rd generation). After unlock, the same 326-photo album advanced through 84,
  138, 167, 198, and 230 prepared items without resetting, then completed with
  the process live, charging, and nominal-thermal. This closes B-015.
- The first completed curation exposed a separate real-device regression: only
  two of 326 otherwise displayable photos survived duplicate suppression.
  Private metadata confirmed all 326 records were durable, with zero hidden or
  screenshot candidates and no hard-quality rejection. Vision feature-print
  distances had been divided by 40, collapsing ordinary photos under the 0.12
  duplicate cutoff. Curation revision 3 removes that scaling, and a regression
  test covers the normalization. Reinstalling over the same data rebuilt the
  album to 86 ready photos with **Start Frame** enabled; B-017 records the fix.

## Responsive Frame refinement verification — 2026-08-12

- Focused simulator coverage passes 32 tests with zero failures: content source
  selection and preparation presentation, layout selection and motion safety,
  photo-anchor reflow, session timing, and overlay visibility policy.
- The complete iOS 27 `iPad (A16)` Simulator scheme passes 128 tests with zero
  failures, expected failures, or runtime warnings; the one skipped test is the
  intentional physical-only real-PhotoKit album-discovery check. An unsigned
  generic-device Release build and the Xcode Cloud archive identity/privacy
  guard both pass. The only build warning is a deprecation inside Apple's
  StoreKitTest SDK header, not FrameWink source.
- Automatic-album preparation is explicitly tested to return an empty chosen
  source rather than falling back to a bundled sample. The UI renders a neutral
  on-device preparation backdrop until real selected-source slides are ready.
  First-time individual-photo import uses the same honest presentation and
  suppresses both sample imagery and sample-labeled home chrome.
- Layout tests cover compact single-photo fallback, bounded lookahead for
  compatible wide portrait pairs, tall landscape stacks, a mostly-single
  composition balance, entitlement-gated event-bound Mosaic, crop bounds, and
  preservation of the featured photo across reflow.
- Session tests prove that a resize-driven page remap does not reset the
  playback deadline and that an interactive resize preserves the exact
  remaining interval. Coordinator coverage drives repeated geometry remaps
  through begin/end resize and verifies the photo anchor, play state, timer,
  and display-history boundary together.
- The iOS 27 `iPad (A16)` Simulator built and launched the deterministic local
  reel. Portrait home remained readable with a single primary and contextual
  secondary action. Direct Frame Mode rendered edge-to-edge with no status or
  multitasking chrome and settled to a clean photo-only screen after controls
  and the temporary tap/swipe hint receded.
- UI automation verifies the complete playback-chrome lifecycle: guidance and
  controls recede independently, tap restores the controls, pausing keeps them
  visible, a swipe advances without reopening chrome, rotation preserves the
  active photo, and tapping during scheduled blackout reveals the escape
  control.
- The physical iPad mini 6 is connected and recognized as `iPad14,1` on iPadOS
  27. It is registered to the Jenny Media LLC development team; the signed
  physical-acceptance build installs, launches, and retains a live process at
  nominal thermal state.
- The signed replacement build installed and launched on the iPad Pro
  12.9-inch. A host sample found the process running, charging, and nominal
  thermal. While its real 1,925-item album refreshed, the preparation screen
  retained an actual cached album photo rather than showing bundled sample
  imagery.

## Progressive large-album verification — 2026-08-13

- The complete iOS 27 `iPad (A16)` Simulator scheme passes 131 tests with zero
  failures, expected failures, or runtime warnings. The one skipped test is the
  intentional physical-only PhotoKit album-discovery check. The only build
  warning remains the deprecation inside Apple's StoreKitTest SDK header. An
  unsigned generic-device Release build also succeeds.
- A new XCUI regression launches a three-photo durable reel, swipes the ready
  home preview before **Start Frame**, observes the exact next photo, and
  confirms that the app remains on the setup screen rather than entering Frame
  Mode.
- Unit coverage verifies that a large sync requests a deterministic,
  date-spanning first batch, commits durable metadata at 30-item intervals,
  distinguishes the early prepared subset from a larger reusable cache, and
  exposes a playable initial reel while the final synchronization is still
  active. A later full pass replaces the provisional reel normally.
- The real PhotoKit export now requests a high-quality 2,560-pixel
  representation rather than the largest current image. On the physical iPad
  Pro, progress moved from 29 to 243 of 1,925 in 36 seconds and later to 1,497;
  on the iPad mini 6 it moved from 87 to 336 of 653 in 37 seconds. This is
  approximately 5–7 prepared photos per second on both devices, with each
  process live and thermal state nominal.
- The mini completed its 653-item album and retained immediate playback after
  reinstall. The Pro durably committed all 1,925 display copies, then a relaunch
  of the progressive build exposed a representative 30-photo reel with **Start
  Frame** enabled within seconds while the status visibly continued
  `improving your reel` through the remaining analysis. The final pass replaced
  that provisional result with 100 ready photos without a crash or thermal
  warning.
- These results prove target-sized real PhotoKit retrieval, progressive
  usability, resumable local checkpoints, and real-device lifecycle health.
  They do not replace the oldest-supported 2 GB device gate, a human-labelled
  curation review, Airplane Mode playback, or the seven-day wall soak.

## Immediate real-album playback correction — 2026-08-13

- The owner reproduced a critical playback defect on the connected iPad Pro:
  after **30 photos ready**, **Start Frame** displayed one photo but immediate
  swipes and arrow controls did not change it. The app process remained live,
  charging, and nominal-thermal.
- Non-photo inspection found 30 unique reel selections mapped to 30 durable
  records. Sampled first/second cache files had different SHA-256 hashes and
  visibly different content, proving that import and curation had prepared more
  than one playable photo.
- Debug accessibility instrumentation isolated an inconsistent state: the
  responsive view had 27 pages after portrait pairing, while the playback
  session still held zero pages. Its stored layout signature already matched,
  so the old synchronization guard skipped page-count repair. The temporary
  diagnostics were removed after verification.
- Synchronization now compares both signature and page count. Arrow, swipe,
  and timer paths reconcile current pages before advancing, and a manual page
  change updates its stable photo anchor and display-history decision in the
  same state mutation. Arrow controls expose `Photo n of m` to VoiceOver.
- `FrameSessionControllerTests` now recreates a matching-signature/zero-page
  session for a 30-page reel, advances immediately, and proves the new photo
  anchor survives a responsive reflow. All 14 focused tests pass.
- The complete iOS 27 `iPad (A16)` Simulator scheme passes 132 tests with zero
  failures, expected failures, or runtime warnings. Two physical-only real-
  PhotoKit checks skip intentionally. The unsigned generic iPadOS Release build
  succeeds.
- On the physical iPad Pro, the local three-photo UI flow passed Next,
  Previous, swipe, pause/resume, and rotation. The new configured-real-album
  test then entered the current configured 30-photo reel: Next changed both the
  accessible position and actual display to the distinct second cache file, and
  a subsequent swipe displayed a page containing none of the prior page's
  photos. This closes B-019 for the reported device and source.
