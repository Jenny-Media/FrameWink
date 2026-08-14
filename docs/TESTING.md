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

Still required: physical Vision execution, the complete 500-photo performance
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
- Every multi-photo Fit placement occupies at least 78% of its tile; unsafe
  low-occupancy Mosaic groups reduce their photo count or become single pages.
- Screen rotation produces a valid new layout.

### Frame session

- Timer pause/resume and manual navigation.
- Entering/leaving restores owned state.
- Foreground/background transitions do not duplicate timers.
- End-of-reel behavior is stable.
- Reduce Motion disables or simplifies motion-heavy transitions.
- Long-pressing an individual tile exposes `Share Photo`; VoiceOver exposes the
  same action without requiring a long press.

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

For 500 picker candidates and representative 1,000/5,000-asset paid albums,
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

- First playable personal reel from ten candidates in under 30 seconds on the
  oldest target.
- A 500-candidate import completes, remains cancellable/resumable, and refines
  the active reel without returning to bundled samples.
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
- Delete Imported Photos and Remove Downloaded Album Photos remove the respective
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

## Ten-photo start and visual album grid — 2026-08-13

- Automatic-album synchronization now prioritizes a deterministic,
  date-spanning ten-item batch, persists checkpoints at 10, 30, 60, and later
  30-item intervals, and builds provisional reels at ten and thirty candidates
  before the full-album result. If an export fails, the first stage waits for
  ten successfully prepared candidates rather than counting the failed item.
- Controller regressions prove that the ten-photo reel is playable while sync
  is active, the thirty-photo checkpoint replaces it before the full pass, and
  album-cover requests preserve the requested album identifier and pixel bound.
  Synchronizer tests prove checkpoint durability and representative ordering.
- The album picker is a lazy adaptive cover grid with stable album identity,
  name/count labels, a selected-album checkmark, VoiceOver labels, placeholders,
  cancellable local-first cover requests, and a 32 MiB/80-thumbnail cache.
  Cover availability does not delay the album metadata or empty/error states;
  the preferred cover may use Apple Photos' iCloud fetch after local fallbacks.
- Deterministic screenshots were visually inspected on the iOS 27 `iPad (A16)`
  and `iPad mini (A17 Pro)` Simulators. Both show three clean columns with square
  covers and no clipping; the grid can adapt to narrower resized windows.
- Focused `AlbumSyncServiceTests` and `AutomaticAlbumControllerTests` pass. The
  complete shared scheme passes 135 tests with two intentional real-PhotoKit
  physical-only skips, zero failures, zero expected failures, and zero runtime
  warnings. The generic iPad Simulator Debug build and unsigned generic iPadOS
  Release build both succeed without compiler diagnostics.
- Still required on a physical iPad: confirm real PhotoKit cover thumbnails do
  not delay the ten-second album-grid gate, measure time to the first playable
  ten-candidate reel, observe its live replacement near thirty candidates, and
  verify swipe/arrow playback throughout the remaining large-album preparation.

## Album-cover performance, Living Photo motion, and tall stacks — 2026-08-13

- Album covers now request 384-pixel square thumbnails through a
  `PHCachingImageManager` and a four-request limiter. Each album tries up to six
  recent non-hidden, non-screenshot assets locally before allowing Apple Photos
  to fetch the preferred iCloud-backed cover. The 32 MiB/80-image cache remains
  bounded and is invalidated with cached cover identifiers after library
  changes. Loading and unavailable states are visibly distinct.
- A new physical-only UI regression waits for the album metadata grid and then
  requires at least one cover within twenty seconds. The signed build installed
  and launched on both connected iPads, but XCTest timed out enabling iPadOS
  automation mode on both before the test body ran. B-020 tracks this
  validation boundary; the script returns the devices to interactive
  FrameWink after an attempted run.
- `FramePhotoMotionPlanner` deterministically chooses face-safe zoom-in,
  zoom-out, horizontal, vertical, or diagonal pan endpoints per photo. Plans
  use 3.5–7% scale and at most 1.8% offset, fall back to a gentler scale when
  important content has less slack, and decline unsafe or Fit motion. Reduce
  Motion, paused playback, multi-photo pages, and interactive resize disable
  it. Automatic changes dissolve; manual navigation uses a 32-point
  directional dissolve.
- Tall automatic layout is no longer fixed at two. Geometry and a 220-point
  minimum cell height select two for ordinary portrait windows, three at a
  500×1000-style window, and four at an exceptional 360×1024-style window.
  Unsafe four-up crops retry a smaller group; short 360×600 windows remain
  single-photo. Unit tests cover all thresholds, non-overlap, anchor inclusion,
  deterministic motion, and important-region safety.
- The complete iOS 27 `iPad (A16)` Simulator scheme passes 145 tests with three
  intentional physical-only skips, zero failures, zero expected failures, and
  zero runtime warnings. The clean unsigned generic-device Release build and
  archive-mode Xcode Cloud identity/privacy guard pass. The signed Debug build
  is installed and launched over existing data on the iPad Pro 12.9-inch (3rd
  generation) and iPad mini 6.

## Occupancy-aware collages, sharing, and responsive covers — 2026-08-13

- Owner-observed physical testing confirms real album covers progressively
  appear, Living Photo motion is visible and restrained, narrow Stage Manager
  windows can show 3–4 landscape photos, and important regions remain safe.
- Album metadata now carries a bounded list of recent non-hidden,
  non-screenshot cover candidates. The first eighteen albums are preheated;
  each visible lazy-grid tile requests a thumbnail sized from its measured
  point width and display scale. Local candidates are tried first, then every
  eligible candidate can use PhotoKit's iCloud-enabled request. Tiles distinguish
  local loading, cloud downloading, ready, and unavailable states.
- A four-request limiter, 32 MiB/80-image cache, a 24-asset discovery cap per
  album, cancellation-aware tile tasks, and bounded preheat keep the grid
  appropriate for older 2 GB iPads. Manual physical comparison with Photos is
  still qualitative; exact Photos-app parity is not claimed.
- Pure layout tests cover low-occupancy Mosaic rejection, the 78% fitted-tile
  threshold, deterministic motion, and the motion policy's Reduce Motion,
  resize, and multi-photo branches. A UI regression long-presses an exact local
  photo tile and requires the `Share Photo` context action.
- The affected `FrameLayoutChooserTests` and
  `AutomaticAlbumControllerTests` pass on the iOS 27 iPad mini Simulator. A
  generic iPadOS 15 device compile succeeds. The long-press UI regression also
  passes serially on the iPad (A16) Simulator. A combined parallel shared-scheme
  run passed 122 unit tests after an automatic restart but was marked failed
  when the Xcode beta UI-test runner was killed before establishing its
  connection; serial UI execution is the current workaround. Manual physical
  confirmation of the share sheet remains required. The unsigned Release build
  and archive-mode Xcode Cloud identity/privacy/product guard both pass.

## Source integrity and live-layout audit — 2026-08-13

- A reported speed-change regression was traced to `RootView` observing the
  complete active saved configuration. Updating only its interval published a
  new value, and the view incorrectly reapplied that configuration's stale
  photo source. The observer now reacts only to configuration-ID activation,
  while playback presentation edits save the source currently on screen.
- The same audit found two related asynchronous overrides. Making a purchased
  configuration visible during entitlement restoration could apply its source,
  and finishing background personal-photo curation always selected My Photos.
  Both side effects are removed; readiness updates data while explicit user
  actions retain ownership of source selection.
- An XCUI regression starts on a deliberately stale saved Samples
  configuration, switches to My Selected Photos, pauses playback, changes
  speed to five seconds and style to Fit, and proves a personal photo remains
  visible with no bundled sample appearing after either edit.
- Automatic composition previously left the first page single in reels larger
  than four, making a live resize appear unresponsive even though crop geometry
  was recalculated. The anchored first page now pairs compatible portraits in
  a wide window or stacks compatible landscapes in a tall window. The reel
  remains mostly single-photo, compact windows remain single-photo, and
  face-safe crop fallback is unchanged.
- Focused state/configuration/layout tests pass 22 of 22. The complete iOS 27
  `iPad (A16)` Simulator scheme passes 139 tests with two intentional
  physical-only PhotoKit skips, zero failures, zero expected failures, and zero
  runtime warnings. The unsigned generic iPadOS Release build succeeds.
- The signed audited Debug app is installed and launched on the connected iPad
  Pro and iPad mini 6 without deleting their existing FrameWink data. Remaining
  human check: enter Frame Mode with a real album, drag the Stage Manager window
  from a narrow/compact shape to a sufficiently wide or tall shape, and confirm
  the current photo remains anchored while crop/fit changes immediately and a
  compatible pair/stack appears when available.

## Playback-menu, album-cache, and UI/performance audit — 2026-08-13

- Frame Mode keeps Previous, Pause/Play, Next, and More visible when controls
  are shown, but removes the app-owned top-leading close button. The More menu
  exposes Share Photo/Share Featured Photo, per-tile choices for other photos
  in a collage, and Exit Frame. Long-press remains available for an exact tile;
  the parent swipe gesture is simultaneous so it does not preempt the context
  menu. This checkpoint's split multi-photo share control was later superseded
  by D-023 and the single scene-share regression below.
- Album catalog loading has independent state. Closing and reopening the picker
  immediately shows the existing catalog and covers while a refresh proceeds,
  rather than replacing the grid with Loading albums. Cover cache keys include
  bounded candidate identity, PhotoKit changes no longer flush every decoded
  cover, and the first eighteen covers are preheated again only when their
  identity or measured tile dimension changes.
- Two controller regressions prove cached catalog visibility during delayed
  refresh and deduplicated measured-size preheating. UI regressions prove the
  top corner stays free, Share and Exit are available in More, long-press still
  exposes Share Photo, and blackout tap still reaches Exit Frame.
- The complete iOS 27 `iPad (A16)` Simulator scheme passes 153 tests with zero
  failures and four intentional real-PhotoKit physical skips. The iOS 27 beta
  runner reports two private UIKit context-menu hierarchy warnings only during
  native long-press menu presentation. The unsigned Release build, Xcode static
  analysis, and archive guard pass; the built release contains only device
  family 2 (iPad).
- A symbolicated single-run ETTrace launch capture on the same Simulator spans
  13.310 seconds, of which 13.084 seconds is idle and 0.226 seconds is active on
  the sampled main thread. The largest named FrameWink-specific inclusive stack
  is `SampleSlideshowView.body` construction at 0.031 seconds. No album or
  PhotoKit work appears in first-launch stacks. System-framework symbols are
  incomplete in the current iOS 27 beta runtime, so the trace is directional
  Simulator evidence, not a physical-device latency claim.
- The physical `verify-albums` harness now also requires a closed/reopened real
  picker to restore both its catalog and one visible cover within two seconds.
  Its connected iPad Pro run built and installed successfully, but iPadOS timed
  out enabling XCTest automation before the test body; the script relaunched
  the interactive acceptance harness. Manual timing and a later automation
  retry remain under B-021.

## Direct Frame Controls panel — 2026-08-13

- Playback `More` opens a native anchored popover rather than cascading menus.
  Auto/Fit/Fill/Mosaic (when entitled) and 5/10/30/60-second timing choices are
  visible together; selecting one does not close the panel. Share and Exit
  Frame remain direct actions, while an optional list is used only to target a
  non-featured photo in a collage.
- Focused iPad Simulator UI tests cover opening the panel, finding each direct
  control, changing speed and layout without reactivating bundled samples, and
  reaching Exit Frame during a scheduled blackout. The initial run exposed an
  accessibility-container identifier that masked child buttons; scoping it to
  the panel title fixed the hierarchy without changing the visible UI.
- The complete scheme passes 153 tests with four intentional physical-PhotoKit
  skips and zero failures on the iOS 27 `iPad (A16)` Simulator. A first complete
  run hit four transient StoreKit `productUnavailable` results; the StoreKit
  suite then passed 4/4 in isolation and the clean complete rerun passed. The
  two recorded runtime warnings are the previously documented private iOS 27
  beta UIKit context-menu hierarchy warnings. The generic unsigned Release
  build succeeds with `MinimumOSVersion` 15.0 and iPad-only device family 2;
  the archive-mode Xcode Cloud identity, privacy, and production-product guard
  passes.
- The same Jenny Media LLC-signed Debug app was installed without uninstalling
  on the physical iPad Pro 12.9-inch (3rd generation) and iPad mini 6. Both
  device process checks reported one running FrameWink process after launch.
- The repository remains `TARGETED_DEVICE_FAMILY = 2`; iPhone is explicitly a
  post-MVP evaluation, not an untested widening of this release.

## Compact Frame Controls correction — 2026-08-13

- An owner screenshot from the temporary physical-iPhone build revealed that
  compact popover adaptation used a nearly full-height sheet and inherited the
  playback capsule's white foreground. The white-on-white inheritance hid the
  title, close button, and bordered Share action even though accessibility
  still exposed the controls.
- Frame Controls now resets to system semantic foreground/background colors,
  requests a 500-point draggable sheet when popovers adapt on iOS 16+, and
  rendered the then-current Share action full width above Exit Frame. The later
  D-023 refinement changed only that action's multi-photo semantics; iPad
  retains the anchored popover.
- The direct-controls regression passes on both the iPad (A16) and a temporary
  iPhone 17 Pro Max Simulator compatibility build. The iPhone capture visibly
  includes the title, close button, style/speed controls, prominent Share Photo,
  and Exit Frame without clipping. The temporary project-family edit used for
  that compact test was reverted; the repository remains iPad-only.
- The complete iPad Simulator scheme passes 153 tests with four intentional
  physical-PhotoKit skips and zero failures after the correction. The same two
  previously tracked private iOS 27 beta context-menu hierarchy warnings are
  present; no new runtime warning was introduced. The clean unsigned iPadOS 15
  Release build succeeds.

## Progressive album catalog and direct exit refinement — 2026-08-13

- Removed the eager cover-candidate fetch from `PhotoKitLibraryClient.albums()`.
  The initial result now contains collection title, identity, and estimated
  count only, so `AlbumPickerView` replaces its blocking loading state before
  thumbnails are ready. Visible lazy-grid tiles discover up to six eligible
  candidates and request local-then-iCloud covers through the existing
  four-request limiter. Cached cover candidates now participate in reopen
  preheating, and PhotoKit changes invalidate both candidate and image caches.
- The real-library album-list acceptance timeout is tightened from ten seconds
  to three seconds. Cover loading remains a separate progressive assertion with
  a twenty-second allowance for iCloud, and the reopen path still requires a
  cached grid and cover in two seconds.
- Frame Controls hides the compact sheet drag indicator and supplies one system
  background, eliminating the stacked top edges visible in the owner's iPhone
  capture. Share is a non-prominent bordered action whose icon is balanced by an
  equal trailing spacer so its text center matches the sheet center. The new
  `frame-quick-close-control` exits directly from the top right while playback
  controls are visible; an isolated UI regression taps it without opening More.
- `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -project FrameWink.xcodeproj -scheme FrameWink -sdk iphonesimulator
  -destination 'platform=iOS Simulator,name=iPad (A16),OS=27.0'
  -derivedDataPath /private/tmp/framewink-derived test` passes 142 unit tests
  and 16 UI tests, with four real-PhotoKit UI tests skipped intentionally and
  zero failures: 154 passes, 158 total.
- A focused temporary iPhone 17 Pro Max Simulator compatibility run of
  `testFrameControlsPanelOffersDirectSettingsShareAndExit` passes. Its retained
  screenshot shows a single sheet edge, fully visible controls, and centered
  Share text. The temporary `TARGETED_DEVICE_FAMILY = 1,2` edit was reverted;
  the committed application remains iPad-only.
- The unsigned generic-device Release build and Xcode static analysis succeed.
  The Xcode Cloud archive guard passes with bundle ID `media.jenny.FrameWink`,
  Jenny Media LLC team `5736QK4NZX`, iPad family 2, iPadOS 15.0 minimum, and the
  production Wall Mode product identifier.
- Existing iOS 27 beta warnings remain: two private UIKit context-menu hierarchy
  warnings during long-press, plus a post-test diagnostic warning because one
  Xcode runner invocation did not inherit `DEVELOPER_DIR` for `simctl`. Neither
  warning caused a test failure. Real-library initial metadata timing and iCloud
  cover latency still require the connected iPad checks below.
- The signed refinement build installed and launched over existing data on the
  connected iPad Pro. A retry of all three real-library checks timed out while
  iPadOS enabled UI automation, before any test body ran; the harness then
  relaunched the interactive app. B-021 records this tooling boundary and the
  short manual metadata/cover timing check that remains.
- After the final cache-preheat and hit-target hardening, the complete 158-test
  scheme passed again, as did fresh Xcode static analysis and the unsigned
  Release build. That exact signed source was reinstalled and launched on the
  iPad Pro. A temporary iPhone-family compatibility build was also signed,
  installed, and launched on the paired physical iPhone 17 Pro Max; the project
  family setting was immediately restored to iPad-only and has no repository
  diff. The final physical `verify-albums` retry again timed out enabling iPadOS
  automation before any app assertion, then restored the interactive harness.

## Single scene-share action — 2026-08-13

- Replaced the multi-photo `Share Featured` plus `Other Photos` split with one
  `Share Photos` button. It supplies every image in the current scene to one
  `UIActivityViewController`. Single-photo scenes retain `Share Photo`, and the
  long-press context action still shares exactly the touched photo.
- Focused iPad Simulator UI coverage passed for direct Frame Controls sharing,
  a multi-photo Mosaic scene exposing only one share action, and the exact-photo
  long-press action: 3/3 passed.
- The complete iOS 27 `iPad (A16)` Simulator scheme passed 142 unit tests and 17
  UI tests. Four physical-PhotoKit UI tests skipped intentionally, producing
  155 passes, four skips, and zero failures across 159 tests.
- The existing two private iOS 27 UIKit context-menu hierarchy warnings and
  post-test `simctl` diagnostic remain non-failing. No new runtime warning was
  introduced.
- The unsigned generic-device Release build succeeded for iPadOS 15 and device
  family 2.
- A Jenny Media LLC-signed Release compatibility build was verified with
  `UIDeviceFamily` 1 and 2, minimum OS 15.0, and production product identifier
  `media.jenny.FrameWink.wallmode`, then installed and launched over existing
  data on the paired physical iPhone 17 Pro Max. The temporary family edit was
  restored immediately; the repository remains iPad-only.

## Production StoreKit availability publication — 2026-08-13

- The owner reproduced **Purchase unavailable** on a physical iPad using the
  signed Release build. Its built `Info.plist` had already been verified to use
  production product identifier `media.jenny.FrameWink.wallmode`, so this was
  not the earlier Debug/local-StoreKit configuration issue.
- App Store Connect showed `FrameWink Lifetime` with Family Sharing, a $9.99
  schedule across 175 countries or regions, and an enabled Save button. With
  owner confirmation, Save completed and the page reported **Saved** with
  **Add for Review** enabled.
- FrameWink was terminated and relaunched successfully on both the physical
  iPad Pro 12.9-inch (3rd generation) and iPad mini 6 without deleting app data.
- Real-device acceptance remains pending Apple sandbox metadata propagation:
  reopen the paywall and verify a localized price, then perform the transaction
  with a sandbox tester or TestFlight. App Store Connect requires this first
  non-consumable to be submitted with the first app version.

## Local paid-feature unlock on physical iPads — 2026-08-13

- `FRAMEWINK_PHYSICAL_ACCEPTANCE=1` remains compiled only in Debug and selects
  the test purchase client with a purchased entitlement while leaving the real
  PhotoKit client active. It does not persist an entitlement flag and cannot
  affect Release or TestFlight behavior.
- Xcode 27 reports reachable paired Wi-Fi devices with connection state
  `disconnected` until a command opens their tunnel. The physical-acceptance
  script now requires `pairingState == paired` and then proves reachability with
  `devicectl device info lockState`; shell syntax validation passes.
- Separate signed Debug harness builds installed and launched successfully on
  the iPad Pro 12.9-inch (3rd generation), iPadOS 26.6, and iPad mini 6,
  iPadOS 27.0. Existing app data was retained.
- Follow-up samples reported both FrameWink processes live and reachable with
  nominal thermal state. The iPad Pro reported battery unplugged; the iPad mini
  reported battery full. Actual StoreKit purchase, restore, and Family Sharing
  remain separate Sandbox/TestFlight acceptance checks.

## Automatic presentation and literal timing refinement — 2026-08-13

- Removed user-facing Auto/Fit/Fill/Mosaic choices while preserving the tested
  responsive layout engine. Paid automatic presentation can still choose a
  balanced Mosaic when the current photos and window make it appropriate.
- Frame Controls now exposes `10s`, `30s`, `1m`, and `5m`, selects `30s` for a
  new frame, retains one `Share Photo`/`Share Photos` action, and relies on the
  receding top-right close control for exit. Legacy 5-second timing migrates to
  10 seconds; the old implicit 7-second default migrates to 30 seconds.
- Frame Settings now contains display wake behavior, an optional night
  schedule with disclosed time editing, concise Mounted iPad Tips, and local
  data/privacy controls. Album choice, review, layout, timing, and manual album
  refresh remain in their existing direct or automatic paths rather than being
  duplicated there.
- Migration coverage proves that a legacy Mosaic/7-second record becomes
  automatic/30-second without losing its selected source, album identifier,
  album title, active ID, or durable archive. Timing coverage proves the exact
  available labels and default.
- Five focused XCUI flows pass for source retention after a timing change,
  direct blackout escape, the timing/share panel, single scene-level collage
  sharing, and the reduced Frame Settings surface.
- The full iOS 27 `iPad (A16)` Simulator scheme passes 158 tests and skips the
  four intentional physical-PhotoKit checks, with zero failures and zero
  expected failures across 162 total. Xcode records the same two private UIKit
  context-menu hierarchy warnings already documented for iOS 27 beta.
- The unsigned generic iPadOS Release build and Xcode static analysis succeed.
  The Xcode Cloud archive preflight passes the privacy manifests, Jenny Media
  LLC team, production bundle/product identifiers, iPad-only family, and
  iPadOS 15 minimum checks.
- All ten 2064 × 2752 submission JPEGs were regenerated and validated without
  alpha. Visual inspection confirms the progressive album grid, selected
  30-second timing, automatic multi-photo share state, progressively disclosed
  schedule, and concise mounted-iPad guidance.
- The signed Debug physical-acceptance build installed over existing data on
  both the iPad Pro and iPad mini 6. Both devices were locked at launch time, so
  iPadOS rejected the foreground launch after installation. Unlocking either
  device and tapping FrameWink, or rerunning `prepare`, is the remaining device
  smoke step; the install and signing stages already succeeded.

## Larger hand-picked collection and simplified Photos flow — 2026-08-13

- Free hand-picked storage is bounded at 500 imported candidates across picker
  sessions. Import remains sequential and cancellable, checks for at least 512
  MiB of free filesystem space before each item, publishes durable checkpoints
  at 10/30/100/250/500, and reports excess picker selections without treating
  them as retryable failures. The first ten candidates can produce a playable
  reel while import continues; later checkpoints refine the active reel to at
  most 100 recommendations without reverting the selected source to samples.
- Unit coverage verifies the policy constants, progressive checkpoints,
  cross-session capacity, low-storage stop, 500-candidate analysis, 100-result
  selection, and an `AppModel` sequence that exposes a ten-photo reel while a
  forty-photo import is still active before refining through 30 and 40.
- Home **More** now contains only **Photos**, **Frame Settings** (or the paid
  feature entry), and **Privacy & Data**. The Photos sheet consolidates current
  source, Choose/Add Photos, Choose/Change Album, and Review Photos. Privacy &
  Data owns `Delete Imported Photos`, `Remove Downloaded Album Photos`, and
  exclusion reset. An XCUI regression proves the consolidated action opens
  Apple's PHPicker and returns cleanly after Cancel.
- Frame Controls labels timing as **Photo Duration**. The selection state is
  updated before persistence so one tap visibly selects a duration. Manual
  drags move the current page with the finger and complete with a directional
  move-plus-opacity transition; automatic changes retain the calmer dissolve.
  Living Photo motion extends to safe Fit images with a centered 2.5–3.5%
  deterministic zoom and no pan, and remains disabled for unsafe important
  regions, Reduce Motion, resize, pause, preview, and multi-photo scenes.
- Final complete command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -destination
  'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F'
  -derivedDataPath /private/tmp/FrameWink-DerivedData -resultBundlePath
  /private/tmp/FrameWink-Final-20260813.xcresult test`. Result: 166 passed,
  four intentional physical-PhotoKit skips, zero failures, zero expected
  failures, and 170 total on iOS 27 `iPad (A16)` Simulator.
- The same two private iOS 27 UIKit context-menu hierarchy warnings appear in
  the native long-press test. Xcode's post-test diagnostic also failed to find
  `simctl` in its internal environment after the successful run; neither
  warning changes the zero-failure result.
- The exact final source passes an unsigned generic iPadOS Release build, Xcode
  static analysis, and `CI_XCODEBUILD_ACTION=archive
  ci_scripts/ci_pre_xcodebuild.sh`. The latter validates Info.plist, the privacy
  manifest, `media.jenny.FrameWink`, Jenny Media LLC team `5736QK4NZX`, iPad
  family 2, iPadOS 15.0, test identifiers, and the production StoreKit product.
- Ten 2064 × 2752 JPEG submission screenshots were regenerated with no alpha.
  Visual inspection covered the sample home, immediate album grid, literal
  30-second Frame Controls state, centered scene Share action, and paid-feature
  sheet. The first late-evening capture exposed two black frame screenshots:
  all entitled debug scenarios had inherited the fixture's 11 p.m. blackout.
  Screenshot seeding now enables the schedule only for schedule, checklist, and
  explicit blackout scenarios, so submission images are deterministic at any
  host time. Regeneration restored the photo-backed Frame Controls and Mosaic
  images; the affected blackout, timing/share, and multi-photo-share XCUI tests
  then passed 3/3.
- The signed Debug physical-acceptance build installed over existing data on
  the paired iPad Pro 12.9-inch (3rd generation), iPadOS 26.6. The device was
  locked, so iPadOS rejected only the foreground launch. The paired iPad mini 6
  was not reachable and could not receive this exact build. This is B-022, an
  external device-state boundary rather than a source/build failure.
- Still required on unlocked physical hardware: a large PHPicker selection and
  second-session accumulation, first-ten time to frame, full 500-photo storage,
  memory and thermal behavior, cancel/resume and Airplane Mode, one-tap timing,
  finger-following swipes, safe Fit motion, and Reduce Motion behavior. The
  permission prompt, picker choices, and low-storage setup remain human-owned.

## Ten sanitized bundled samples — 2026-08-14

- The three generated PNG examples were replaced by ten publisher-supplied,
  display-sized JPEG derivatives: seven landscape and three portrait. The
  originals remain unmodified outside the repository. The derivatives total
  approximately 5.1 MiB, less than the prior three PNGs.
- `exiftool` reports only JPEG file/JFIF format fields. It finds no EXIF, GPS,
  IPTC, TIFF, XMP, camera/device serial, creator, copyright, capture date, or
  location data. A new automated regression rejects those private metadata
  dictionaries and verifies all ten catalog IDs/resources are unique, decode,
  and exactly match their declared pixel dimensions.
- Bundled slides now carry their real dimensions into the responsive layout
  engine instead of assuming every example is 1536 × 1024. Debug review,
  automatic-album, cover, curation, and screenshot fixtures use the same JPEG-
  capable loader and current resources.
- Exact complete command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -destination
  'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F'
  -derivedDataPath /private/tmp/FrameWink-DerivedData -resultBundlePath
  /private/tmp/FrameWink-Samples-20260814.xcresult test`. Result: 167 passed,
  four intentional physical-PhotoKit skips, zero failures, zero expected
  failures, and 171 total on the iOS 27 `iPad (A16)` Simulator.
- The suite retains its existing manual finger-following directional swipe,
  automatic dissolve/Living Photo, safe Fit motion, calm multi-photo, Reduce
  Motion, and resize-suspension coverage. The two known private iOS 27 UIKit
  context-menu warnings remain; Xcode's post-test diagnostic again failed to
  locate `simctl` outside the explicit developer-directory environment after
  the successful run.
- The exact source passes an unsigned generic-device Release build and Xcode
  static analysis. The archive guard passes with the explicit Xcode path and
  validates privacy files, iPad-only family 2, iPadOS 15.0 minimum, Jenny Media
  LLC team, production bundle ID, and StoreKit product. Its first invocation
  reproduced the already recorded machine-wide `xcode-select` B-016 boundary;
  the documented `DEVELOPER_DIR` invocation passed.
- Built-product inspection finds exactly ten `sample-*.jpg` resources, zero
  retired sample PNGs, no private sample metadata, `UIDeviceFamily = [2]`, and
  `MinimumOSVersion = 15.0`.
- All ten native 2064 × 2752 submission JPEGs and the broader eleven-image
  1640 × 2360 source library were regenerated and visually inspected. The
  retired saved-configuration screenshot was removed; its replacement is the
  current direct Frame Controls panel. The source capture script now requires
  the correct iPad geometry and exact eleven-image output.
- The signed exact Debug acceptance build installed over existing data on the
  paired iPad Pro, but its locked screen rejected only foreground launch. The
  paired iPad mini 6 was also locked and rejected the installation tunnel.
  Unlocking the devices and rerunning `prepare` remains the physical visual
  smoke check; the Simulator, Release, signing, and Pro installation stages are
  already successful.

## First-tap duration and compact-caption refinement — 2026-08-14

- Frame Controls no longer waits for a parent redraw to acknowledge a duration
  tap. Its direct playback binding is paired with a panel-lifetime optimistic
  appearance, and the parent assigns a fully updated playback value before
  persisting. Every duration button is 48 points tall with fixed checkmark
  space. Press scaling is disabled by Reduce Motion.
- `testFrameDurationRespondsToEverySingleTap` taps `10s`, `5m`, `1m`, `30s`,
  and `10s` once each, verifies every target is at least 44 points, and requires
  the selected trait after every tap.
  `testSampleCaptionStaysAboveTheCompactSetupCard` verifies the sample title
  does not intersect the compact setup surface. Both pass on iOS 27 iPad (A16)
  and iPhone 17 Pro Max Simulators; the temporary Debug app/UI-test family
  widening was restored with no project-file diff.
- Exact complete iPad command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -destination
  'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F'
  -derivedDataPath /private/tmp/FrameWink-DerivedData -resultBundlePath
  /private/tmp/FrameWink-Refinement-20260814-0059.xcresult test`. Result: 169
  passed, four intentional physical-PhotoKit skips, zero failures, zero
  expected failures, and 173 total.
- The two known private iOS 27 UIKit context-menu hierarchy warnings remain.
  Xcode's post-test diagnostic again could not find `simctl` in its internal
  environment after the successful run. The exact source also passes the
  unsigned generic iPadOS Release build, Xcode static analysis, and
  `CI_XCODEBUILD_ACTION=archive ci_scripts/ci_pre_xcodebuild.sh`; the built
  product reports `media.jenny.FrameWink`, `UIDeviceFamily = [2]`, and iPadOS
  15.0 minimum.
- Ten 2064 × 2752 JPEG submission screenshots and eleven 1640 × 2360 PNG QA
  screenshots were regenerated. Visual inspection confirms the selected
  30-second duration has a stable checkmark, accent outline, and centered label;
  the rest of the Frame Controls surface remains uncluttered.
- A signed temporary compatibility Debug build installed and launched on the
  physical iPhone 17 Pro Max. Its 1320 × 2868 screenshot confirms the sample
  title clears the setup card. Two attempts to execute the narrow physical
  timer UI test timed out while iOS enabled Automation Mode before the test body
  ran; B-023 records that non-blocking tooling boundary. Manually tapping each
  duration once on the installed phone remains required.

## Native control and reversible-review audit — 2026-08-14

- Playback exposes one direct `Share Photo` or `Share Photos`, pause/play, and
  More control. Previous and next remain finger-following horizontal swipes;
  each photo exposes named Previous Photo and Next Photo VoiceOver actions with
  the current page position. Focused UI coverage proves the arrows are absent,
  scene Share is direct for one- and multi-photo pages, long-press remains the
  exact-photo share path, and rotation/swipe behavior still works.
- Frame Controls is a system NavigationView/Form with a native segmented
  Photo Duration picker and leading Close action. Rapid `10s` → `5m` → `1m` →
  `30s` → `10s` selection passes with one tap per segment. The selected state
  remains optimistic while persistence uses the existing playback binding.
- The Photos, Privacy & Data, personal review, and automatic review sheets now
  use cancellation-position Close actions. Import progress, cancellation,
  completion, retry, and deletion failure use one native modal Form rather than
  an app-owned dimming overlay. The initial-personal-import UI regression proves
  that this sheet appears without exposing bundled sample imagery.
- `Never Show Again` is a full-size native destructive action. Its Undo removes
  only the just-added durable exclusion, restores the exact curated selection
  and order, saves the repaired reel, and disappears after use or five seconds.
  Pipeline, automatic-controller, and end-to-end review UI regressions pass.
- Local album covers use a quiet photo placeholder during local candidate work;
  a spinner remains only for actual iCloud download. Home menu items have native
  labels, grouped symbols, and a divider before Privacy & Data.
- Exact complete command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug
  -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F'
  -derivedDataPath /private/tmp/FrameWink-NativeControls-Derived
  -resultBundlePath /private/tmp/FrameWink-NativeControls-Final-20260814-0904.xcresult
  CODE_SIGNING_ALLOWED=NO test`. Result: 172 passed, four intentional
  physical-PhotoKit skips, zero failures, and zero expected failures out of 176.
  The same two private iOS 27 UIKit context-menu hierarchy warnings remain, and
  Xcode's post-test diagnostic again lacked `simctl` outside the explicit
  developer environment after the successful run.
- The exact source passes unsigned generic iPadOS Release build, Xcode static
  analysis, and `CI_XCODEBUILD_ACTION=archive ci_scripts/ci_pre_xcodebuild.sh`.
  The built app remains `media.jenny.FrameWink`, iPad family 2, and iPadOS 15.0
  minimum. Both screenshot scripts pass, and visual contact-sheet inspection
  found no clipping, double sheet edges, blank paid frames, or misplaced text.
- The signed exact source installed over existing data on the paired iPad Pro;
  its locked screen refused only foreground launch. The paired iPad mini 6 was
  not reachable. These external device-state results are recorded under B-004;
  unlock and rerun `prepare` before manual touch and Photos-library checks.

## Universal iPhone and direct-device StoreKit audit — 2026-08-14

- Target/build settings: every app and test configuration now reports
  `TARGETED_DEVICE_FAMILY = 1,2`; the application deployment target remains
  15.0. The exact unsigned Release product reports bundle identifier
  `media.jenny.FrameWink`, `UIDeviceFamily = [1, 2]`, `MinimumOSVersion = 15.0`,
  product identifier `media.jenny.FrameWink.wallmode`, ten bundled sample JPEGs,
  and one root `PrivacyInfo.xcprivacy`.
- StoreKit isolation: Debug and Release app builds use the production product
  identifier. The shared scheme's normal Launch action does not attach a local
  StoreKit catalog. Its Test action and explicit `SKTestSession` checks retain
  the fixture-only `media.jenny.FrameWink.wallmode.local` product. The new
  purchase-controller regression first returns unavailable, retries without a
  restart, loads the product on the second request, and returns entitlement to
  free while preserving the purchase path.
- iPhone unit command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -project FrameWink.xcodeproj -scheme FrameWink -destination
  'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE'
  -derivedDataPath /private/tmp/FrameWink-Universal-iPhone-Units
  -resultBundlePath /private/tmp/FrameWink-Universal-iPhone-Units-20260814.xcresult
  -only-testing:FrameWinkTests test`. Result: 156 passed, zero skipped, zero
  failed on iPhone 17 Pro Max Simulator, iOS 27.
- iPhone UI command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -project FrameWink.xcodeproj -scheme FrameWink -destination
  'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE'
  -derivedDataPath /private/tmp/FrameWink-Universal-iPhone-UI-Final2
  -resultBundlePath /private/tmp/FrameWink-Universal-iPhone-UI-Final2-20260814.xcresult
  -only-testing:FrameWinkUITests test`. Result: 17 passed, four intentional
  physical-PhotoKit skips, zero failed out of 21.
- Complete iPad command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug
  -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F'
  -derivedDataPath /private/tmp/FrameWink-Universal-iPad-Final
  -resultBundlePath /private/tmp/FrameWink-Universal-iPad-Final-20260814.xcresult
  CODE_SIGNING_ALLOWED=NO test`. Result: 173 passed, four intentional
  physical-PhotoKit skips, zero failed out of 177.
- Release command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Release
  -destination 'generic/platform=iOS' -derivedDataPath
  /private/tmp/FrameWink-Universal-Release CODE_SIGNING_ALLOWED=NO build`.
  Static analysis uses the same project/scheme with Debug,
  `generic/platform=iOS Simulator`, and `analyze`. Both pass. The archive guard
  passes with
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
  CI_XCODEBUILD_ACTION=archive ci_scripts/ci_pre_xcodebuild.sh`.
- `plutil -lint` passes for app and privacy plists; `jq empty` passes for the
  StoreKit fixture; every changed shell script passes `/bin/sh -n`; and
  `git diff --check` is clean. Screenshot scripts produced ten 1320 × 2868
  no-alpha iPhone JPEGs, ten 2064 × 2752 no-alpha iPad JPEGs, and eleven
  1640 × 2360 iPad PNGs. Visual inspection found no clipping, double sheet
  edges, blank paid scenes, or misplaced universal wording.
- `scripts/physical_acceptance.sh prepare-storekit` built, installed, and
  launched the exact signed Debug source on the paired iPhone 17 Pro Max,
  iOS 27. The installed binary uses the real Apple StoreKit sandbox path and
  production product identifier. A human must still sign in through Apple's
  sandbox UI, verify the localized price, authorize the transaction, restore,
  and test Family Sharing. Simulator uses the known private UIKit context-menu
  hierarchy warnings; Xcode's successful test runs still emit the known
  post-test diagnostic that its internal environment cannot locate `simctl`.

## Compact edge-face composition audit — 2026-08-14

- The reported failure is reproducible in pure geometry: on a 430 x 932 compact
  viewport, a portrait source with a face near the right source boundary can
  satisfy strict crop visibility while leaving the face in the outer quarter
  of the screen. Exact centering would require unavailable pixels beyond the
  source image.
- `FrameLayoutChooserTests` now proves both sides of the policy. An edge face
  that cannot receive a 7% visible inset and near-center placement falls back
  to unit-crop Fit; an equivalent centered face retains full-bleed crop with
  its center at exactly 0.5. The complete 29-test layout suite passes.
- iPhone unit command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -destination
  'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE'
  -derivedDataPath /private/tmp/FrameWink-FaceCrop-iPhone-Tests-2
  -resultBundlePath /private/tmp/FrameWink-FaceCrop-iPhone-Tests-20260814-2.xcresult
  -only-testing:FrameWinkTests test`. Result: 158 passed, zero skipped, and
  zero failed on iPhone 17 Pro Max Simulator, iOS 27.
- Complete iPad command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -destination
  'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F'
  -derivedDataPath /private/tmp/FrameWink-FaceCrop-iPad-Tests-2
  -resultBundlePath /private/tmp/FrameWink-FaceCrop-iPad-Tests-20260814-2.xcresult
  test`. Result: 175 passed, four intentional physical-PhotoKit skips, and
  zero failed out of 179.
- The unsigned universal Release build and Xcode static analysis pass. The
  archive guard validates both privacy files, production identity, StoreKit
  product, deployment target, and universal device families. The full scheme
  retains two known private iOS 27 UIKit hierarchy warnings; Xcode's successful
  UI run again emitted its known post-test diagnostic about internally locating
  `simctl`.
- `scripts/physical_acceptance.sh prepare-storekit` built, installed over the
  existing data, and launched the exact signed source on the paired iPhone 17
  Pro Max. Owner confirmation on the two private source photos remains required:
  each should display the whole image when full-bleed cannot give the detected
  face a comfortable position. The originals remain private and were not
  copied into fixtures, screenshots, or the repository.

## Compact source-retention audit — 2026-08-14

- The owner supplied one physical iPhone frame capture and three private
  landscape examples. The moon source is approximately 2:1; portrait Fill on a
  430 x 932 viewport would retain only about 23% of it. The previous centered-
  crop path returned immediately when Vision supplied no important rectangle,
  so subject-placement checks could not reject that deterministic over-crop.
- Compact single-photo Fill now requires `crop.width * crop.height >= 0.70`.
  This normalized value is the source fraction retained because an aspect-fill
  crop trims only one axis. The gate is independent of Vision and does not
  apply to regular iPad single pages or multi-photo cells.
- New regressions prove that a 2:1 source uses Fit on a 430 x 932 portrait
  viewport, a 3:2 source uses Fit on a 932 x 430 landscape viewport when more
  than 30% would be lost, and a near-matching 1:2 portrait with a comfortably
  centered face still uses Fill. The focused layout result is 31 passed with
  zero failures or skips.
- Complete iPhone command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -destination
  'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE'
  -derivedDataPath /private/tmp/FrameWink-CropRetention-iPhone
  -resultBundlePath /private/tmp/FrameWink-CropRetention-iPhone-20260814.xcresult
  test`. Result: 177 passed, four intentional physical-PhotoKit skips, and zero
  failed out of 181.
- Complete iPad command uses the same project/scheme with destination
  `platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F`, derived
  data `/private/tmp/FrameWink-CropRetention-iPad`, and result bundle
  `/private/tmp/FrameWink-CropRetention-iPad-20260814.xcresult`. Result: 177
  passed, four intentional physical-PhotoKit skips, and zero failed out of 181.
- The unsigned universal Release build, static analysis, and archive-mode cloud
  guard pass. The two private iOS 27 UIKit context-menu hierarchy warnings and
  Xcode's post-test internal `simctl` diagnostic are unchanged.
- `scripts/physical_acceptance.sh prepare-storekit` installed the exact signed
  source over existing data and launched it on the paired iPhone 17 Pro Max.
  Owner observation of the private moon/architecture photos remains required;
  the app should choose whole-photo Fit when the compact viewport cannot retain
  70% in Fill.

## App Review candidate preflight — 2026-08-14

- Destination discovery command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -project FrameWink.xcodeproj -scheme FrameWink -showdestinations`. Result:
  iPhone 17 Pro Max and iPad (A16) iOS 27 Simulators, both physical iPads, and
  the physical iPhone are available; the scheme is universal.
- Complete iPhone command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug
  -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE'
  -derivedDataPath /private/tmp/FrameWink-Review-iPhone -resultBundlePath
  /private/tmp/FrameWink-Review-iPhone-20260814.xcresult
  CODE_SIGNING_ALLOWED=NO test`. Result: 177 passed, four intentional physical-
  PhotoKit skips, and zero failures out of 181.
- Complete iPad command uses the same project, scheme, configuration, and code-
  signing flag with destination
  `platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F`, derived
  data `/private/tmp/FrameWink-Review-iPad`, and result bundle
  `/private/tmp/FrameWink-Review-iPad-20260814.xcresult`. Result: 177 passed,
  four intentional physical-PhotoKit skips, and zero failures out of 181.
- Release command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Release
  -destination 'generic/platform=iOS' -derivedDataPath
  /private/tmp/FrameWink-Review-Release CODE_SIGNING_ALLOWED=NO build`. Result:
  success with no app compiler diagnostics. The equivalent Debug generic iOS
  Simulator `analyze` action also succeeds.
- Archive packaging command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Release
  -destination 'generic/platform=iOS' -archivePath
  /private/tmp/FrameWink-Review-1.0.xcarchive CODE_SIGNING_ALLOWED=NO archive`.
  Result: success. The archived app reports `media.jenny.FrameWink`, version
  1.0 build 1, iOS 15.0 minimum, device families 1 and 2, no non-exempt
  encryption, one root privacy manifest, and compiled iPhone/iPad icons.
- Screenshot commands:
  `scripts/capture_app_store_iphone_submission_screenshots.sh` and
  `scripts/capture_app_store_submission_screenshots.sh`. Both generated ten
  current screenshots successfully. Visual contact-sheet review passed; `sips`
  confirms 1320 × 2868 and 2064 × 2752 JPEGs respectively, all without alpha.
- Asset and configuration checks: the production icon is 1024 × 1024, opaque,
  and byte-identical to the selected clean-gallery candidate with SHA-256
  `5f4881ffb1a29b9a06a18bc1297828bb68cffdb9830dbd7422145b988b772e8a`.
  `plutil -lint`, `jq empty`, `/bin/sh -n`, the archive-mode
  `ci_scripts/ci_pre_xcodebuild.sh`, and `git diff --check` all pass.
- Warnings/remaining device work: both test bundles retain the two known private
  iOS 27 UIKit context-menu hierarchy warnings, Apple's StoreKitTest headers
  emit their SDK deprecation warning, and Xcode's successful cleanup emits the
  known internal `simctl` lookup diagnostic. The previous real-device photo,
  StoreKit sandbox, Family Sharing, iCloud, and long-running mounted-display
  checks remain the physical gates recorded in `docs/DISTRIBUTION.md`; no new
  device behavior was inferred from Simulator results.
