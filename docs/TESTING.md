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
- [x] Xcode Cloud clean archive and internal TestFlight distribution succeed.
- [x] Public Apple-silicon Mac and Apple Vision Pro availability are disabled,
      and both corresponding `Jenny Media Internal` TestFlight platform options
      report `Not Available`.
- [ ] Install the latest TestFlight build on physical iPhone and iPad and repeat the
      sandbox purchase/restore acceptance check.

The executable `ci_scripts/ci_pre_xcodebuild.sh` is recognized automatically by
Xcode Cloud. Its validation path passes locally. Its archive path now validates
the confirmed production Wall Mode product identifier and also guards the Jenny
Media team, production bundle ID, universal iPhone/iPad family, iOS/iPadOS 15
minimum, and both privacy property lists.

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
- IAP review screenshot: App Store Connect rejected the 1320 × 2868 6.9-inch
  product screenshot in its IAP-specific field despite accepting that size for
  the product page. A metadata-free 1242 × 2688 derivative at
  `AppStore/Screenshots/Review/IAP/FrameWink-Lifetime-review-1242x2688.jpg`
  was then accepted and finished processing without an error. It visibly shows
  the lifetime product, $9.99 purchase control, Restore Purchases, Family
  Sharing, and the free/paid boundary, and is used only by App Review.
- Repeatable asset gate: `scripts/validate_app_store_assets.sh` verifies the
  exact ordered filename manifests, count, dimensions, alpha state, and file
  uniqueness of both ten-shot submission sets; the accepted IAP review image;
  and the universal 1,024-pixel icon plus asset-catalog reference. It does not
  require a running Simulator or mutate the submission directories.
- Warnings/remaining device work: both test bundles retain the two known private
  iOS 27 UIKit context-menu hierarchy warnings, Apple's StoreKitTest headers
  emit their SDK deprecation warning, and Xcode's successful cleanup emits the
  known internal `simctl` lookup diagnostic. The previous real-device photo,
  StoreKit sandbox, Family Sharing, iCloud, and long-running mounted-display
  checks remain the physical gates recorded in `docs/DISTRIBUTION.md`; no new
  device behavior was inferred from Simulator results.

## First Xcode Cloud build and workflow configuration — 2026-08-14

- Xcode Cloud Build 1 succeeded against commit `b8691b9` using Xcode 26.6
  (17F113) on macOS Tahoe 26.6.2 (25G82). The manual build queued for 12 seconds,
  ran for two minutes, and completed its iOS Build action with zero warnings,
  static-analysis issues, test failures, or build errors.
- The success proves that Apple can clone `Jenny-Media/FrameWink`, discover the
  committed shared `FrameWink` scheme, run the pre-build guard, resolve signing,
  and build the universal app. It does not substitute for the still-pending
  archive, TestFlight processing, or physical StoreKit/PhotoKit acceptance.
- The follow-on `Validation` workflow uses required Analyze and Test actions on
  `main`; Test uses the shared scheme on both recommended iPhone and iPad
  destinations. The manual-only `Internal TestFlight` workflow archives iOS
  with App Store Connect preparation and distributes the archive to the
  `Jenny Media Internal` group.
- Xcode generated `FrameWink.xcodeproj/xcshareddata/xcodecloud/manifest.json`
  after onboarding. `jq empty` validates the file before it is committed.
- The first `Internal TestFlight` attempt, Build 3 at commit `3338357`, failed
  in `ci_pre_xcodebuild.sh` before compilation or distribution. The cloud log
  showed the correct bundle ID and product but supplied `CI_TEAM_ID` as Jenny
  Media LLC's App Store Connect team UUID. Xcode's resolved Release setting
  remained `DEVELOPMENT_TEAM = 5736QK4NZX`. The guard now recognizes both
  verified Jenny Media identifiers; local checks exercise the Developer Team
  ID, the App Store Connect UUID, and a rejected unrelated-team value before
  the cloud archive is rerun.
- Validation Build 2 succeeded in Analyze and in the initial build-for-testing
  guard, but its distributed simulator workers failed before tests because
  Xcode Cloud reran `ci_pre_xcodebuild.sh` after restoring artifacts without a
  repository checkout. The worker action is `test-without-building`, as listed
  in Apple's Xcode Cloud environment-variable reference. The guard now exits
  successfully only when that exact action has no project directory. A local
  fixture check verifies the artifact-only path passes while a missing project
  for a normal action still fails.

## Xcode Cloud archive and distributed-test verification — 2026-08-14

- `Internal TestFlight` Build 6 at commit `6f59253` succeeded end to end:
  clean archive, TestFlight internal-distribution post-action, and processing
  to FrameWink 1.0 (6) `Ready to Test` in `Jenny Media Internal`.
- Build 6 used Apple's `TestFlight (Internal Testing Only)` preparation. Apple
  correctly made it unavailable for customer submission. The workflow now uses
  App Store Connect preparation, which remains TestFlight-capable and makes its
  archive eligible for App Store release. Build 8 succeeded from `037c4ab` in
  four minutes with both Archive and TestFlight post-action green. App Store
  Connect accepted version 1.0 (8) into the two-item review draft.
- Validation Build 5 completed Analyze, then reported 172 passed, four intended
  physical-PhotoKit skips, and five failures out of 181. Four failures were
  `StoreKitConfigurationTests` returning `productUnavailable` on distributed
  artifact-only iOS 26.5 workers; the fifth was a compact iPhone SE settings
  UI assertion for a disclosure control below the initial viewport.
- `FrameWink.storekit` is now copied explicitly into the hosted unit-test
  bundle. During Debug hosted tests, app startup waits for the test process to
  install its `SKTestSession` before opening the normal purchase connection.
  This preserves production/TestFlight behavior while making artifact-only
  workers deterministic.
- Fresh iPad artifact command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  test-without-building -xctestrun
  /private/tmp/FrameWinkCloudFix-iPadFresh/Build/Products/FrameWink_FrameWink_iphonesimulator27.0-arm64.xctestrun
  -destination id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F
  -only-testing:FrameWinkTests/StoreKitConfigurationTests`. Result: four
  passed, zero failures.
- The same artifact-only runner executes
  `FirstLaunchPrivacyUITests/testFrameSettingsKeepsOnlyDisplayGuidanceAndLocalDataControls`
  after the test scrolls to the native disclosure button. Result: one passed,
  zero failures. The targeted normal-scheme iPhone run passes the same UI test
  and all four StoreKit tests.
- Validation Build 7 confirmed the compact-height UI repair and every
  non-StoreKit suite, but Apple's iOS 26.5 Xcode Cloud artifact workers still
  returned an empty `Product.products` result for all four StoreKit runtime
  tests. The catalog is present in the test bundle, yet that worker does not
  expose it to `storekitd` as an IDE-launched test does.
- StoreKit coverage now has two explicit layers. A platform-independent test
  parses the bundled `FrameWink.storekit` file and asserts the product ID,
  non-consumable type, Family Sharing flag, and reference name on every runner.
  Runtime purchase, refund, Ask to Buy, and failure tests remain mandatory and
  pass locally on both iPhone and iPad Simulators. Only when the product is
  absent on an identified Xcode Cloud worker do those four runtime tests report
  an explicit skip with the runner limitation; they continue to fail closed in
  every other environment.
- Post-change targeted commands on iPhone 17 Pro Max and iPad Air (11-inch)
  Simulators each passed all five StoreKit tests with zero skips and zero
  failures. Xcode's post-success missing-`simctl` diagnostics remain
  non-failing cleanup noise.
- Expected diagnostics remain: StoreKitTest purchase-anchor/update-listener
  warnings in direct product tests, the intentional simulated failure's
  `ASDServerErrorDomain`, an iOS 27 duplicate private WebKit accessibility
  class warning, the launch-screen advisory, and Xcode's post-success `simctl`
  cleanup diagnostic. None failed the run.
- Validation Build 9 exercised the intended coverage split: four
  physical-PhotoKit checks and four Xcode Cloud StoreKit runtime checks were
  explicitly skipped. One iPad (10th generation) worker then reported 17 UI
  errors because SpringBoard was busy and denied every app launch before any
  test code ran. A clean manual rebuild of the same commit isolated that
  infrastructure failure.
- Validation Build 10 at commit `d6d7026` succeeded in Analyze and Test across
  all eight recommended iPhone/iPad destinations: 182 total, 174 passed, eight
  explicit skips, and zero failures. Every worker's `test-without-building`
  command succeeded. This closes the cloud validation gate without weakening
  local StoreKit runtime coverage.

## Permanent price, platform bridge, and website verification — 2026-08-14

- App Store Connect's confirmed product view reports the permanent U.S. price
  as `$4.99`, proceeds as `$4.24`, comparable prices across all 175 storefronts,
  Family Sharing enabled, and the IAP still `Waiting for Review`.
- Focused iPhone command:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  test -project FrameWink.xcodeproj -scheme FrameWink -destination
  'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE'
  -derivedDataPath /tmp/framewink-final-iphone
  -only-testing:FrameWinkTests/PurchaseControllerTests
  -only-testing:FrameWinkTests/StoreKitConfigurationTests`. Result: 16 passed,
  zero failed.
- The same focused command on iPad (A16) destination
  `B3A8D8D4-D576-4245-A0EC-ED914C0C744F`, using derived data
  `/tmp/framewink-final-ipad`, also passed all 16 tests with zero failures.
  Three direct StoreKitTest purchases retain the known transaction-listener
  test-harness warning; FrameWink itself installs its transaction listener at
  launch. Xcode's post-success `simctl` diagnostic remains non-failing cleanup
  noise.
- Resolved Release settings are `SUPPORTED_PLATFORMS = iphoneos
  iphonesimulator`, `TARGETED_DEVICE_FAMILY = 1,2`,
  `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO`, and
  `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO`. The archive-mode command
  `CI_XCODEBUILD_ACTION=archive
  DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
  ci_scripts/ci_pre_xcodebuild.sh` passes and now guards both compatibility
  settings. `xcodebuild -showdestinations` exposes no eligible compatible Mac
  or Vision Pro destination.
- The iPhone, iPad, source-QA, and private IAP review images were regenerated
  from the current `$4.99` source state. The three capture scripts completed,
  contact-sheet inspection passed, and
  `scripts/validate_app_store_assets.sh` reports every required count,
  dimension, alpha, and uniqueness check valid.
- Website verification covers six Node regression tests, ESLint, a successful
  static Next.js production build, and `npm audit --audit-level=moderate` with
  zero known vulnerabilities. Independent visual, conversion, and
  accessibility reviews found no launch blocker after the fixes. Browser smoke
  checks cover the keyboard skip target, FAQ behavior, responsive navigation,
  `$4.99` rendering, and route metadata.
- Vercel production deployment `dpl_9HTSp5UmemJfy3WTT1wU3LFg8Bfk` reached
  `Ready` and aliases `https://frame.jenny.media`. Live Home, Privacy, Support,
  and Terms requests return HTTP 200. Rendered production HTML contains `$4.99`
  but not `$9.99`, preserves each route's canonical URL, omits homepage social
  artwork from detail routes, and exposes a focusable `#availability` target.

## App Store marketing screenshot verification — 2026-08-14

- App Store Connect's submitted public description was changed from `$9.99` to
  `$4.99`, saved, and re-read with no former price remaining in the field.
- `scripts/generate_app_store_marketing_screenshots.sh` deterministically
  generated ten 1320 × 2868 iPhone JPEGs and ten 2064 × 2752 iPad JPEGs from
  the current native submission captures. The generator uses ImageMagick 7,
  project-owned media, real app UI, and no third-party artwork.
- Contact-sheet inspection confirmed that all twenty cards are populated and
  distinct, titles stay clear of the device compositions, and the screens do
  not overpromise weather, remote upload, automatic relaunch, whole-library
  access, or background scheduling.
- `bash -n scripts/generate_app_store_marketing_screenshots.sh` and
  `scripts/validate_app_store_assets.sh` pass. The validator covers counts,
  exact dimensions, alpha absence, and per-set uniqueness for both native and
  marketing galleries.
- Live upload remains intentionally untested: Apple prevents screenshot
  replacement while version 1.0 is `Waiting for Review`. Withdrawing would
  change the submission to `Developer Rejected` and require resubmission.

## Landscape screenshot and website authenticity verification — 2026-08-14

- `MarketingLandscapeScreenshotTests` passed on the iPad Pro 13-inch (M5)
  Simulator and iPhone 17 Pro Max Simulator. `XCUIScreen` captures were rotated
  without scaling to native 2752 x 2064 and 2868 x 1320 landscape output.
- Four distinct iPad scenes cover single-photo playback, a four-photo Mosaic,
  direct Frame Controls, and Review Suggestions. Three distinct iPhone scenes
  cover playback, controls, and review; the redundant compact Mosaic capture
  is deliberately omitted.
- `scripts/generate_landscape_marketing_assets.sh` produces captioned cards
  with the native screen shown directly and no generated or illustrated Apple
  hardware. `scripts/validate_app_store_assets.sh` passes exact count,
  dimension, alpha, and uniqueness validation for all portrait and landscape
  source and marketing sets.
- Website verification passes seven Node tests, ESLint, and the Next.js
  production build. A settled 1280 x 720 browser capture confirms the iPad-first
  hero uses the native screen without covering FrameWink controls; the iPhone
  companion is explicitly captioned as an actual in-app screen.

## Landscape-first replacement gallery verification — 2026-08-14

- `scripts/capture_app_store_landscape_screenshots.sh` passed on the iPad Pro
  13-inch (M5) and iPhone 17 Pro Max Simulators. The iPad UI test completed ten
  deterministic states in 76.5 seconds; the compact iPhone landscape smoke set
  completed three states in 30.8 seconds. The only build warning is the known
  StoreKitTest SDK deprecation warning; the debugger emitted its existing host
  version message.
- `scripts/generate_landscape_marketing_assets.sh` and
  `scripts/generate_app_store_marketing_screenshots.sh` generated ten landscape
  iPad and ten portrait iPhone proposed upload cards without simulated hardware.
  `scripts/validate_app_store_assets.sh` passes required counts, exact 2752 x
  2064 and 1320 x 2868 dimensions, no alpha, and uniqueness.
- Visual contact-sheet inspection confirmed actual app UI on every card and no
  generic tablet/phone render. The iPad sequence prioritizes playback and
  automatic layouts before configuration; the iPhone sequence preserves the
  compact portrait experience.
- Website verification passes seven Node tests, ESLint, and the static Next.js
  production build. Headless browser captures at 1920 x 1080 and 500 x 1000
  confirm the uniform hero background, readable headline, responsive CTA, room
  scene, and actual native screen treatment. Reduce Motion continues to disable
  the finite hero crossfade.
- Not tested: upload and resubmission are intentionally pending owner approval.
  The owner subsequently approved both screenshot sets and authorized Apple's
  Design Resources License. The website hero now uses two derivative official-
  bezel composites; source inspection verifies that the standalone Apple bezel
  is not included in the repository.

## Lifestyle compositing and portrait iPhone verification — 2026-08-14

- The new hero begins with an AI-assisted 1672 x 941 room scene generated from
  the licensed iPad reference. Visual inspection confirms a physical stand,
  plausible console contact, aligned perspective, ordinary materials, and
  substantially less showroom-like staging than the rejected draft.
- The final two WebP assets do not rely on generated app UI. Exact native
  FrameWink single-photo and four-photo Mosaic captures were rounded, projected
  into the same screen quadrilateral, and composited over the generated screen.
  Inspection confirms both variants use clean playback with transient close,
  Share, Pause, More, and guidance controls hidden.
- A Debug iPhone 17 Pro Max build launched the new `portrait-frame` scenario
  and produced a native 1320 x 2868 screenshot showing the bundled portrait
  city-tower sample as one Fit photo rather than a stacked composition. The
  iPad Pro 13-inch Debug build also passes after the scenario addition.
- Website validation passes seven Node tests, ESLint, and the static Next.js
  production build. The local preview was reloaded with the new assets and
  heading. No App Store Connect or production website mutation was performed.

## Screenshot content and chrome audit verification — 2026-08-14

- `scripts/capture_app_store_landscape_screenshots.sh` passed on the iPad Pro
  13-inch (M5) and iPhone 17 Pro Max Simulators. The clean Frame and Mosaic UI
  tests assert that `frame-quick-close-control` and
  `frame-playback-control` do not exist; the dedicated controls capture asserts
  that `frame-controls-panel` does exist.
- `scripts/capture_app_store_submission_screenshots.sh` and
  `scripts/capture_app_store_iphone_submission_screenshots.sh` passed serially
  with the new six-second settle interval and post-capture blank-image guard.
  The guard rejected the earlier unsettled captures and the regenerated native
  sets passed.
- Contact-sheet inspection confirms clean playback on the first iPad and first
  two iPhone marketing cards. Controls appear only on the explicit timing and
  sharing card; setup, review, scheduling, mounting, and purchase UI appears
  only on cards describing those functions.
- `scripts/validate_app_store_assets.sh` reports all required counts,
  dimensions, alpha, and uniqueness checks valid. In `website/`, `npm test`
  passes seven tests, `npm run lint` passes, and `npm run build` statically
  generates all public routes.
- The only iOS build warning remains Apple's iOS 27 StoreKitTest deprecated
  header warning. App Store Connect upload, replacement, and resubmission are
  intentionally untested pending owner approval.

## Subject-safe marketing media verification — 2026-08-15

- Focused command on the iPhone 17 Pro Max Simulator:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet test -project FrameWink.xcodeproj -scheme FrameWink -destination
  'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE'
  -derivedDataPath /private/tmp/framewink-subject-safe-tests
  -only-testing:FrameWinkTests/FrameLayoutChooserTests
  -only-testing:FrameWinkTests/BundledSampleImageLoaderTests`. Result: success.
- The equivalent focused command on iPad Pro 13-inch (M5) destination
  `1BDA7ABF-4236-406E-8ACD-7E3B10569753`, using derived data
  `/private/tmp/framewink-subject-safe-tests-ipad`, also succeeds. Coverage
  includes the 68% minimum retained-source rule and the white-bird sample's
  protected subject rectangle.
- `scripts/capture_app_store_landscape_screenshots.sh` passed its ten-screen
  iPad and three-screen iPhone UI workflow. The refreshed Mosaic visibly shows
  four bright landscape-compatible photos with no cut bird and no transient
  controls.
- `scripts/capture_app_store_iphone_submission_screenshots.sh` and
  `scripts/capture_app_store_submission_screenshots.sh` regenerated all ten
  portrait screens per family and passed the post-capture blank-image guard.
  Visual inspection confirms the complete bird portrait, distinct tower
  portrait, populated review screen, varied album covers, and aerial coast.
- `scripts/validate_app_store_assets.sh`, seven website Node tests, ESLint, the
  static Next.js production build, script syntax checks, and `git diff --check`
  pass. Local browser inspection confirms both eager iPhone images render and
  the Choose/Review/Enjoy symbols replace the former numerals.
- Expected warnings are limited to Apple's iOS 27 StoreKitTest deprecated
  header warning and the screenshot UI runner's existing debugger-version
  lookup message. Real-device rendering, production deployment, App Store
  upload, and resubmission remain intentionally untested.

## Website image-cache invalidation verification — 2026-08-15

- `scripts/generate_landscape_marketing_assets.sh` and
  `scripts/generate_website_lifestyle_hero.sh` generated new versioned website
  assets. ImageMagick reports 1672 x 941 lifestyle scenes and 1600 x 1200 iPad
  showcase captures; both generator scripts pass `bash -n`.
- In `website/`, `npm test` passes seven tests, `npm run lint` passes, and
  `npm run build` compiles and statically generates every public route.
- The restarted local Next.js server returns HTTP-backed optimized images from
  the new `v5` lifestyle and `v2` iPad paths. Browser inspection confirms the
  hero and iPad showcase render the aerial, flowers, road, and sunset Mosaic
  instead of the cached Taipei/bird/leaf composition. The controls example is
  now aerial, and the iPhone bird and review screens remain populated.
- Production deployment and external-cache behavior remain untested in this
  local verification pass.

## Website content-first showcase verification — 2026-08-15

- `scripts/capture_app_store_landscape_screenshots.sh` passed on the iPad Pro
  13-inch (M5) Simulator and iPhone 17 Pro Max Simulator. The UI workflow built
  and launched the affected Debug screenshot path on both device families,
  captured ten iPad states and three iPhone states, and preserved native 2752 x
  2064 and 2868 x 1320 output. The controls capture visibly uses the distinct
  `sample-autumn-leaves` image and retains the native duration panel.
- `scripts/generate_landscape_marketing_assets.sh` generated the versioned
  1600 x 1200 `ipad-landscape-controls-v3.webp` and the 660 x 1434
  `iphone-portrait-tower-clean-v1.webp`. The first no longer duplicates the
  adjacent aerial Mosaic content; the second is a populated, clean playback
  view with no close button, playback bar, or setup sheet.
- In `website/`, `npm test` passes seven tests, `npm run lint` passes, and
  `npm run build` compiles and statically generates all public routes.
  `scripts/validate_app_store_assets.sh`, generator shell syntax,
  `git diff --check`, and explicit ImageMagick dimension checks also pass.
- Browser review at `http://localhost:3010/` confirms the tighter 310-pixel
  feature cards, the varied iPad Mosaic/autumn-controls pairing, and the clean
  bird/tower iPhone pairing. The local preview server remains available for
  owner review.
- The only iOS warning is Apple's existing iOS 27 StoreKitTest deprecated
  header warning. The screenshot runner also emits its known debugger-version
  lookup message. Physical-device behavior was not changed by this Debug-only
  screenshot-fixture update. Production deployment, App Store upload, and
  resubmission remain intentionally untested.

## iPad-first website positioning verification — 2026-08-15

- In `website/`, `npm test` passes all seven contract tests, `npm run lint`
  passes, and `npm run build` compiles and statically generates every public
  route.
- The website source and rendered homepage contain the compact `Works on
  iPhone too.` compatibility note without the redundant `Also on iPhone`
  kicker and no longer reference any `iphone-portrait-*.webp` marketing image.
  The associated two-phone layout styles were also removed.
- Browser review at a 1280 x 720 viewport confirms the compatibility note reads
  as a restrained transition between the iPad showcase and the three-step
  product flow. Wide layouts use one compact row, while narrow layouts stack
  the same short copy. It contains no competing device screenshots or
  advanced-feature UI.
- Source-level assertions cover the `From your photos to a frame in a few
  taps.` heading and reject the former fixed-time Camera Roll claim.
- No app runtime, App Store screenshot asset, product capability, or platform
  availability setting changed. Production deployment remains untested.

## Website typography and wrapping verification — 2026-08-15

- Browser inspection at a 1280 x 720 viewport covered the complete homepage
  and the Privacy, Support, and Terms routes. The document width equals the
  viewport width on every checked route, and no visible heading, paragraph,
  card, button label, FAQ question, or navigation label crosses the viewport.
- The homepage audit identified two awkward but unclipped wraps: the three-line
  hero title and the three-line iPad showcase title. Their targeted fluid type
  scales now produce balanced two-line treatments at the audited desktop size.
- Regression assertions require balanced heading wrapping, the revised hero
  and showcase scales, and safe wrapping for long body and link text.
- In `website/`, all seven contract tests, ESLint, and the static production
  build pass. App behavior and native App Store screenshot assets are
  unaffected; production deployment remains untested.

## Website type-spacing and lifestyle-screen alignment verification — 2026-08-15

- `scripts/generate_website_lifestyle_hero.sh` regenerated the versioned
  1672 x 941 `hero-lifestyle-frame-v6.webp` and
  `hero-lifestyle-mosaic-v6.webp` scenes. Shell syntax, exact output
  dimensions, and focused regression assertions for the screen mask and
  perspective corners pass.
- Browser review at a 1280 x 720 viewport confirms the primary hero title uses
  two lines at 49.6 pixels with `-1.736px` computed tracking. The regenerated
  lifestyle image loads from the `v6` path, fills the iPad screen opening at
  the top and lower-right edges, and leaves the physical bezel intact.
- Automated browser inspection of the homepage, Privacy, Support, and Terms
  found no overflowing document or text element. In `website/`, all seven
  contract tests, ESLint, the static production build, generator syntax, and
  `git diff --check` pass. Production deployment remains untested.

## Regenerated lifestyle hero device-composite verification — 2026-08-15

- The built-in image generation edit workflow produced the 1672 x 941
  `Design/Website/hero-lifestyle-base-v2.png` source from the existing room and
  the clean native aerial capture. Visual inspection at 3x confirms even bezel
  thickness and aligned rounded inner-screen corners without UI chrome.
- `scripts/generate_website_lifestyle_hero.sh` deterministically generates
  1672 x 941 `hero-lifestyle-frame-v7.webp` and
  `hero-lifestyle-mosaic-v7.webp`. The second state uses the same base pixels,
  an oversized perspective warp, and a destination-space Bezier mask; 3x
  inspection confirms no old content, seam, gap, or bezel overlap at any edge.
- Browser review at 1280 x 720 confirms both versioned optimized images load and
  the 12-second crossfade changes only the iPad display. The room, device,
  stand, and surrounding objects remain stationary between states. Website
  tests, lint, production build, generator syntax, dimensions, and diff hygiene
  pass. Production deployment remains untested.

## Dual-scenario iPad website photography verification — 2026-08-15

- `scripts/generate_website_lifestyle_hero.sh` passes `bash -n` and generates
  the 1672 x 941 `hero-tabletop-frame-v1.webp`,
  `hero-tabletop-mosaic-v1.webp`, and
  `ipad-wall-mounted-mosaic-v1.webp` derivatives. All three combine Apple's
  licensed iPad Pro bezel with actual native FrameWink captures; visual
  inspection confirms clean playback without controls and no exposed
  placeholder-device edge.
- The tabletop pair shares identical room, stand, bezel, perspective, and
  shadow pixels so its 12-second crossfade changes only the FrameWink content.
  The separate mounted scene visibly communicates the wall-display use case.
- In `website/`, `npm test` passes all seven contract tests, `npm run lint`
  passes, and `npm run build` compiles and statically generates every public
  route. Generator syntax, exact dimensions, and `git diff --check` pass.
  Production deployment and physical-device behavior remain untested; no app
  runtime code changed.

## Flat iPad website presentation verification — 2026-08-15

- `scripts/generate_website_lifestyle_hero.sh` passes `bash -n` and generates
  matching 1500 x 1150 sRGBA `ipad-flat-frame-v1.webp` and
  `ipad-flat-mosaic-v1.webp` derivatives. Both combine Apple's licensed iPad
  Pro bezel with the clean native single-photo and Mosaic captures. Visual
  inspection confirms a consistent bezel, complete rounded screen opening,
  correct camera and hardware details, and no controls over either capture.
- Focused assertions require the flat asset paths, fixed graphic stage,
  finite crossfade, and Reduce Motion fallback while rejecting former room,
  stand, wall, perspective-warp, and lifestyle references from the homepage
  and generator.
- In `website/`, `npm test` passes all seven contract tests, `npm run lint`
  passes, and `npm run build` compiles and statically generates every public
  route. The active local preview at `http://localhost:3010/` serves both flat
  assets and the `Actual FrameWink screens` caption with no former tabletop or
  wall asset path. Diff hygiene passes. No app runtime or App Store screenshot
  asset is changed by this website-only refinement; production deployment and
  physical-device behavior remain untested.

## Background-free iPad presentation verification — 2026-08-15

- Focused assertions require the hero and iPad showcase figures to remain free
  of their former background, rounded-card,
  shadow, and padding treatments while preserving the device-level shadow.
- The hero must continue using the real clean single-photo and Mosaic captures
  in a finite ten-second content cycle, with the secondary state disabled when
  Reduce Motion is enabled.
- In `website/`, `npm test` passes all seven contract tests, `npm run lint`
  passes, and `npm run build` compiles and statically generates every public
  route. The local preview serves both `ipad-flat-frame-v1.webp` and
  `ipad-flat-mosaic-v1.webp` plus the authentic-screen caption, and diff
  hygiene passes. This refinement does not change the app runtime or App Store
  screenshot set; production deployment remains untested.

## Side-by-side iPad website showcase verification — 2026-08-15

- `scripts/capture_website_pair_screenshot.sh` passes `bash -n` and its focused
  `MarketingLandscapeScreenshotTests/testCaptureWebsitePairedPhotoScreen` run
  passes on the iPad Pro 13-inch (M5) iOS 27.0 Simulator. The Debug-only
  `paired-frame` scenario supplies exactly the bundled water-bird and
  city-tower portraits to the normal automatic layout path; the UI assertion
  sees two photo action targets while the exported clean playback capture has
  no quick-close or playback controls.
- The capture script exports a 1600 x 1200 sRGB bounded source, and
  `scripts/generate_website_lifestyle_hero.sh` passes `bash -n` and produces a
  1500 x 1150 sRGB licensed-iPad-bezel derivative. Visual inspection confirms
  a genuine 50/50 paired layout, complete subjects, an even bezel, and no
  screen gaps or repeated hero photos.
- `xcodebuild -showdestinations` discovers both iPhone and iPad Simulator
  families. A Debug build passes on the iPhone 17 Pro Max iOS 27.0 Simulator,
  and `FrameWinkTests/FrameLayoutChooserTests` passes on the iPad Pro 13-inch
  (M5) iOS 27.0 Simulator. Xcode emits only the existing Apple StoreKitTest
  `SKPaymentTransactionState` deprecation warning and the screenshot run's
  existing debugger-version lookup note.
- In `website/`, `npm test` passes all seven contract tests, `npm run lint`
  passes, and `npm run build` compiles and statically generates every public
  route. The active local preview serves `ipad-flat-pair-v1.webp` and the new
  side-by-side caption while rejecting the prior four-photo caption. Asset
  dimensions and `git diff --check` pass. The production app path, App Store
  screenshot count, and physical-device behavior are unchanged and were not
  retested; production website deployment remains pending.

## Post-review website hardening verification — 2026-09-04

- `scripts/capture_website_pair_screenshot.sh` passed on the iPad Pro 13-inch
  (M5) iOS 27.0 Simulator and exported clean single, Mosaic, and paired screens.
  `scripts/generate_website_lifestyle_hero.sh` then regenerated the licensed
  flat-bezel derivatives. The paired screen visibly contains the bundled
  water-bird and evening-sail photos, exposes two photo targets, and contains no
  playback chrome. Xcode emitted only the existing StoreKitTest deprecation and
  debugger-version lookup notes.
- In `website/`, `npm test` passes all eight contract tests, `npm run lint`
  passes, and `npm run build` compiles and statically generates `/`, `/privacy`,
  `/support`, `/terms`, `/robots.txt`, `/sitemap.xml`, `/icon.png`, and
  `/apple-icon.png`. `git diff --check` passes.
- Browser verification against `http://127.0.0.1:3001/` confirms meaningful
  content, no framework overlay, no page errors, no application console errors,
  and the expected navigation and section landmarks. The document width equals
  the viewport at 1,181, 1,024, 901, and 390 pixels; the formerly broken hero
  remains wholly inside the viewport and changes to one column at 1,180 pixels.
- Visual checks confirm the sail-pair asset is served under its versioned path,
  the 1,024-pixel iPhone strip has no text collision, and the 390-pixel layout
  stacks its compact cyclist preview cleanly. Axe reports zero WCAG A/AA
  violations on the homepage and Support page; the homepage retains five manual
  contrast checks for decorative glyphs or elements whose pseudo-elements hide
  their computed background from Axe.
- The refreshed `og.png` is 1200 x 630, contains the exact current FrameWink
  headline, and is reduced from 854 KB to 165 KB. The dedicated favicon and
  Apple touch icon are 48 x 48 and 180 x 180 respectively. A local development
  vitals run recorded CLS 0, FCP 76 ms, LCP 96 ms, and TTFB 47 ms; production
  Core Web Vitals remain untested until deployment.

## Public copy and iPhone proof verification — 2026-09-04

- Audited every public route, shared navigation, metadata, FAQ, image alt text,
  and purchase, privacy, and compatibility copy. Internal implementation terms
  such as Mac Catalyst, StoreKit, entitlement, analytics SDK, private app
  container, and derived curation data no longer appear in public copy. The
  revised language keeps the concrete device, privacy, purchase, photo-limit,
  and app-open behavior users need to understand.
- Enlarged the compact iPhone proof from a 62–72 pixel treatment to a responsive
  112–132 pixel treatment. Browser inspection confirms it remains sharp,
  balanced with the adjacent copy, and centered cleanly when the section stacks
  on a phone-sized viewport.
- In `website/`, `npm test` passes all nine contract tests, `npm run lint`
  passes, and `npm run build` compiles and statically generates every public
  route. Browser checks confirm `/`, `/privacy`, `/support`, and `/terms` render
  the revised copy and contain none of the audited internal terms. Production
  verification remains pending until the pull-request deployment completes.

## Official iPhone 17 Pro Max bezel verification — 2026-09-04

- Downloaded Apple's current iPhone 17 product-bezel package from Apple Design
  Resources after owner authorization and selected the official Deep Blue
  iPhone 17 Pro Max portrait PNG. The 1470 x 3000 bezel remains unmodified; the
  FrameWink cyclist frame sits beneath its exact 1320 x 2868 transparent screen
  opening at +75+66. A 190-pixel rounded-rectangle alpha mask clips the screen
  content before compositing so the photo cannot escape through the transparent
  outer corners; the complete composite is then resized to 735 x 1500.
- The homepage displays the device at 200–230 pixels wide, meeting Apple's
  200-pixel minimum onscreen size. No CSS border, synthetic hardware detail,
  added reflection, or added device shadow is applied to the product image.
- Browser inspection confirms the complete bezel, side controls, rounded
  display, masked photo corners, and Dynamic Island remain visible at a
  1,280-pixel desktop width and
  at a 390-pixel phone width. The responsive section has no horizontal overflow,
  and the phone-sized layout centers the 200 x 408 pixel rendered device without
  colliding with either adjacent section.
- In `website/`, all nine contract tests, ESLint, and the static production build
  pass. The generator script passes `bash -n`, the rendered WebP is 735 x 1500
  with transparency, and `git diff --check` passes.

## Xcode Cloud playback-test alignment verification — 2026-09-05

- Reproduced the failed Validation action locally before editing. Both the
  iPhone 17 Pro Max and iPad (A16) runs failed
  `testBlackoutTapRevealsEscapeControl` and
  `testSceneOffersOneShareActionMatchingTheResponsiveLayout` because the tests
  looked for controls before tapping the intentionally clean screenshot
  scenarios. Captured accessibility hierarchies confirmed the photos and
  scheduled blackout were rendered while playback chrome was absent.
- Focused verification passed on iPhone destination
  `B41C6094-A3CA-48E6-AA25-1E08D0B98BCE` and iPad destination
  `B3A8D8D4-D576-4245-A0EC-ED914C0C744F` with:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild
  -quiet -project FrameWink.xcodeproj -scheme FrameWink -destination
  'platform=iOS Simulator,id=<device-id>'
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testBlackoutTapRevealsEscapeControl
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testSceneOffersOneShareActionMatchingTheResponsiveLayout
  test`.
- Complete shared-scheme verification passed on both destinations. The iPhone
  result bundle reports 186 tests: 181 passed, 5 skipped, and 0 failed. The
  iPad result bundle reports 186 tests: 182 passed, 4 skipped, and 0 failed.
  Result bundles are
  `/private/tmp/FrameWink-Full-Fix-iPhone.xcresult` and
  `/private/tmp/FrameWink-Full-Fix-iPad.xcresult`.
- Release Analyze passed with the generic iOS Simulator destination, and
  `CI_XCODEBUILD_ACTION=analyze ci_scripts/ci_pre_xcodebuild.sh` passed the
  plist, privacy, identity, device-family, deployment-target, version, and test
  bundle checks. Xcode emitted only the existing StoreKitTest deprecation and
  debugger-version notes; its post-test diagnostic collector also reported a
  local `simctl` lookup warning after successful runs. No physical-device test
  is required for this test-only change. Xcode Cloud rerun remains pending.

## Favorites album and progressive eligible-count verification — 2026-09-07

- The album catalog now publishes names before exact counts begin. A controller
  regression holds each count request for 100 milliseconds, verifies both
  albums are already visible with pending counts, then verifies the results
  arrive sequentially with a maximum concurrency of one.
- Counts use PhotoKit metadata only at utility priority outside the UI actor;
  they do not request or decode image data. Videos are excluded by the image
  fetch, and hidden photos and screenshots are excluded while enumerating.
  Album rows update individually and yield between albums. Choosing an album or
  leaving the chooser cancels outstanding count work; a regression verifies a
  second queued count never begins after album preparation starts.
- A zero-eligible-photo album remains in the catalog and becomes a disabled
  `No photos available for FrameWink` tile. A pure regression verifies that a
  defensive Favorites source is inserted only when PhotoKit omits its smart
  album collection; that source queries favorite still images directly. The
  same regression verifies that both native and fallback Favorites metadata is
  identified semantically and sorts ahead of alphabetic albums, allowing the
  picker to show its heart symbol without matching localized display text. The
  tile keeps stable album identity while title, heart, and selection badges are
  lightweight overlays; the checkmark occupies the top-left and the Favorites
  heart the top-right, with the eligible count retained below the thumbnail.
- The complete iOS 27 iPhone 17 Pro Max Simulator suite passes 184 tests with
  5 environment-limited skips and zero failures. Result bundle:
  `/private/tmp/FrameWink-Favorites-Overlay-iPhone.xcresult`.
- The complete iOS 27 iPad (A16) Simulator suite passes 185 tests with
  4 environment-limited skips and zero failures. Result bundle:
  `/private/tmp/FrameWink-Favorites-Overlay-iPad.xcresult`.
- Release static analysis completes. Expected toolchain output is limited to
  Apple's StoreKitTest deprecation, Xcode's debugger/simctl diagnostic notes,
  StoreKit test-session runtime notices, two system SwiftUI hosting warnings,
  and analyzer precompiled-module lookup warnings. No FrameWink source warning
  or analyzer diagnostic is reported.
- The user confirmed Favorites is visible and selectable with full Photos
  access on the physical iPhone. Still required: visually confirm its new first
  position and heart symbol, verify a video-only Favorites album remains visible
  but disabled after counting, confirm counts refresh after Photos changes, and
  confirm scrolling/tapping remain smooth during a large library scan. These
  physical checks are required before replacing Build 19 in the 1.0.1 App Store
  draft.
- Physical installation preparation completed on the paired iPhone 17 Pro Max:
  `xcodebuild` built a development-signed Debug app with the command-line-only
  `CURRENT_PROJECT_VERSION=20` override, leaving project versioning unchanged.
  `devicectl device install app` replaced installed version 1.0.1 (19) with
  1.0.1 (20), `devicectl device process launch --terminate-existing` succeeded,
  and the FrameWink process remained present after launch. Installation and
  launch do not establish the manual Favorites or responsiveness checks above.
- After the Favorites ordering and icon refinement, the same signed-device
  workflow produced version 1.0.1 (21), installed it over build 20, launched it,
  and confirmed the FrameWink process remained present. The project file still
  retains its original build number; 21 is a command-line-only development
  override.
- After the Photos-familiar title and selection-overlay refinement, version
  1.0.1 (22) was built with the same command-line-only override, installed over
  build 21, launched, and confirmed running on the paired iPhone. This proves
  installation and launch, while the final visual judgment remains manual.
- After the direct photo actions and clearer frame-review refinement, a signed
  Debug app was built from the exact feature worktree with the command-line-only
  `CURRENT_PROJECT_VERSION=23` override. The project version remains unchanged.
  `devicectl` installed and launched 1.0.1 (23) on the paired iPhone 17 Pro Max,
  and an installed-app query independently confirmed that version and build.
  The paired iPad Pro rejected its lock-state query and install because it had
  not been unlocked recently, so its installation remains pending. Installation
  and launch do not replace the manual More-menu, source-switch, review-recovery,
  or VoiceOver checks.
- After adding persistent individual recovery through `Hidden from Frame`, the
  same signed-device workflow produced development-only version 1.0.1 (24).
  `devicectl` installed and launched it on the paired iPhone 17 Pro Max, and an
  installed-app query independently confirmed version 1.0.1 and build 24. Once
  unlocked, the paired iPad Pro accepted the same signed artifact; launch and
  an independent installed-app query also confirmed 1.0.1 (24). Installation
  and launch do not replace the remaining interaction and VoiceOver checks.

## Version 1.0.1 release-candidate verification — 2026-09-06

- The complete shared scheme passed on the iPhone 17 Pro Max iOS 27.0
  Simulator: 186 total, 181 passed, 5 skipped, and 0 failed. Result bundle:
  `/private/tmp/FrameWink-101-iPhone.xcresult`.
- The complete shared scheme passed on the iPad (A16) iOS 27.0 Simulator: 186
  total, 182 passed, 4 skipped, and 0 failed. Result bundle:
  `/private/tmp/FrameWink-101-iPad.xcresult`.
- An unsigned Release build passed for `generic/platform=iOS`, and Release
  Analyze passed for `generic/platform=iOS Simulator`. The archive preflight
  guard passed with `CI_XCODEBUILD_ACTION=archive`.
- The resolved Release settings retain bundle identifier
  `media.jenny.FrameWink`, purchase identifier
  `media.jenny.FrameWink.wallmode`, device families 1 and 2, and disabled Mac
  and Apple Vision Pro designed-for-iPhone/iPad distribution. The built app
  reports marketing version 1.0.1, minimum OS 15.0, device families 1 and 2,
  and `ITSAppUsesNonExemptEncryption=false`; its privacy manifest is present.
- `plutil -lint` passes for `Info.plist` and `PrivacyInfo.xcprivacy`; `jq empty`
  passes for the StoreKit configuration; `sh -n` passes for the release guard;
  and `git diff --check` passes.
- Xcode reports the existing StoreKitTest deprecation, test-only transaction
  listener notices, SwiftUI hosting-view hierarchy notices, debugger-version
  lookup note, and post-test `simctl` diagnostic-collector note. None caused a
  build, analysis, or test failure, and this release-preparation branch does not
  change those code paths.
- Still required: review and merge the release branch, run the manual Xcode
  Cloud Internal TestFlight archive from the exact merged commit, and smoke-test
  that binary on physical iPhone and iPad hardware. App Store submission remains
  owner-gated.

## Direct photo actions and frame-review verification — 2026-09-07

- The home More menu now opens the private system picker and automatic album
  chooser directly. It offers source switching only when two or more sources
  exist, and the resulting `Photo Source` sheet contains only the available
  source choices. Review is also a direct current-source action.
- `Photos in This Frame` replaces suggestion terminology. Visual inspection of
  the deterministic iPhone review scenario confirms a clear included-photo
  count, source-aware explanation, large photo cards, quieter 44-point `Never
  Show Again` controls, and no clipping. The action affects only FrameWink;
  Undo now reads `Removed from this frame`, and the empty state offers a
  confirmed restore-and-rebuild path.
- Whenever exclusions exist, review now presents a visible `Hidden from Frame`
  entry. Its lazy photo grid supports `Allow Again` for one durable exclusion
  and a confirmed `Allow All` action. Unit regressions cover persisted
  exclusion loading, one-photo restoration for picker imports, and cached
  automatic-album recuration without another album synchronization. XCUI
  regressions cover returning one older choice and restoring all from an empty
  frame on both compact iPhone and iPad layouts.
- A focused iPhone 17 Pro Max Simulator run passed four direct-action and review
  UI tests with zero failures. Result bundle:
  `/private/tmp/FrameWink-PhotoUX-iPhone-Focused.xcresult`.
- The all-excluded restore regression passed independently on both supported
  families with zero failures. Result bundles:
  `/private/tmp/FrameWink-PhotoUX-Restore-iPhone.xcresult` and
  `/private/tmp/FrameWink-PhotoUX-Restore-iPad.xcresult`.
- The complete iPhone 17 Pro Max iOS 27.0 Simulator suite passed 190 tests with
  5 environment-limited skips and zero failures. Result bundle:
  `/private/tmp/FrameWink-HiddenPhotos-Full-iPhone.xcresult`.
- The complete iPad (A16) iOS 27.0 Simulator suite passed 191 tests with 4
  environment-limited skips and zero failures. Result bundle:
  `/private/tmp/FrameWink-HiddenPhotos-Full-iPad.xcresult`.
- Release Analyze succeeded for `generic/platform=iOS Simulator`, and
  `CI_XCODEBUILD_ACTION=analyze ci_scripts/ci_pre_xcodebuild.sh` passed the
  plist, privacy, identity, device-family, deployment-target, version, and test
  bundle checks. `git diff --check` is clean.
- A final refinement makes both individual and allow-all automatic-album
  recovery recurate from cached photos instead of synchronizing PhotoKit again.
  Focused controller and empty-frame XCUI reruns pass on iPhone 17 Pro Max and
  iPad (A16) after the change.
- The review-card action regression now checks all three mixed-photo cards,
  rather than only the first, for a visible, tappable control at least 44 points
  tall. It passes on iPhone 17 Pro Max and iPad (A16) iOS 27.0 Simulators after
  constraining image layout inside each card. Result bundles:
  `/private/tmp/FrameWink-ReviewControls-iPhone.xcresult` and
  `/private/tmp/FrameWink-ReviewControls-iPad.xcresult`.
- Expected diagnostics remain Apple's StoreKitTest deprecation, test-only
  transaction-listener notices, two system SwiftUI hosting warnings, debugger
  version lookup notes, and Xcode's post-test `simctl` diagnostic-collector
  note. None caused a build, analysis, or test failure.
- Still required on physical iPhone and iPad: check More-menu ordering, source
  switching and dismissal, the all-excluded recovery path, and VoiceOver copy.
  No App Store build or screenshot asset was produced in this pass.
- After fixing the aspect-ratio-dependent review-card action layout, the same
  signed-device workflow produced development-only version 1.0.1 (25).
  `devicectl` installed and launched it on the paired iPhone 17 Pro Max and iPad
  Pro, and independent installed-app queries confirmed 1.0.1 (25) on both.
  The project build number remains unchanged; manual review of mixed portrait
  and landscape cards is still required on each device.

## Lifetime purchase fallback verification — 2026-09-07

- A deterministic `paywall-unavailable` scenario reproduces missing StoreKit
  product metadata. The paywall keeps a tappable `Purchase FrameWink Lifetime`
  primary action and the separate `Restore Purchases` action. Tapping Purchase
  invokes the purchase client and surfaces its recoverable unavailable-product
  message; it is not a metadata-only retry.
- The focused regression passes on iPhone 17 Pro Max and iPad (A16) iOS 27.0
  Simulators. Result bundles:
  `/private/tmp/FrameWink-PaywallFallback-iPhone-3.xcresult` and
  `/private/tmp/FrameWink-PaywallFallback-iPad-3.xcresult`.
- The same signed-device workflow produced development-only version 1.0.1
  (26). `devicectl` installed and launched it on the paired iPhone 17 Pro Max
  and iPad Pro, and independent installed-app queries confirmed 1.0.1 (26) on
  both. The project build number remains unchanged.
- Still required: confirm the fallback button visually on the physical iPad. A
  real localized price and App Store purchase sheet require a TestFlight/App
  Store build or an Xcode-run StoreKit test session; a direct `devicectl` Debug
  launch does not prove them.
- Physical observation: on iPad, tapping the build 26 fallback action reports
  `FrameWink Lifetime is temporarily unavailable from the App Store`. That
  message is produced only after `Product.products(for:)` returns no matching
  production product. The built plist contains bundle ID
  `media.jenny.FrameWink` and product ID `media.jenny.FrameWink.wallmode`; its
  embedded Xcode-managed development profile uses explicit application ID
  `5736QK4NZX.media.jenny.FrameWink` and remains valid through 2027-08-13.
- A live public storefront check on 2026-09-07 lists FrameWink as free with
  In-App Purchases and lists `FrameWink Lifetime` at $4.99 in the U.S.; several
  additional storefront pages also expose the IAP. Because development-signed
  apps use Apple's sandbox, the next physical gate is signing in under Settings
  > Developer > Sandbox Apple Account and retrying. Production availability
  should be checked separately in the App Store-installed build.
- The user repeated the build 26 purchase attempt after signing into a Sandbox
  Apple Account and received the same unavailable-product result. Subsequent
  bundle inspection found `FrameWink.storekit`, whose only product is the
  `.local` test identifier, inside the development application even though the
  file is explicitly a test resource. The synchronized app folder now excludes
  that catalog, and `StoreKitConfigurationTests` verifies it remains available
  from the test bundle while absent from `Bundle.main`.
- The focused bundle-boundary regression passes on iPhone 17 Pro Max and iPad
  (A16) iOS 27.0 Simulators. Result bundles:
  `/private/tmp/FrameWink-StoreKitBoundary-iPhone-Only.xcresult` and
  `/private/tmp/FrameWink-StoreKitBoundary-iPad-Only.xcresult`. A parallel run
  of the larger StoreKit test class hit its existing Ask-to-Buy session flake on
  iPhone; the isolated new regression and iPad class run passed.
- A development-signed generic-device build with the command-line-only
  `CURRENT_PROJECT_VERSION=27` override succeeded. Direct product inspection
  confirms version 1.0.1 (27), bundle identifier `media.jenny.FrameWink`,
  production product identifier `media.jenny.FrameWink.wallmode`, and no
  `.storekit` file in `FrameWink.app`. Release Analyze and the release guard
  pass, and `git diff --check` is clean.
- `devicectl` installed build 27 over build 26 on the paired iPad Pro, launched
  it, and independently reported 1.0.1 (27). This proves the corrected artifact
  is running, but only a manual purchase attempt can establish whether Apple's
  sandbox now returns the product.
- The user performed that build 27 attempt with the Sandbox Apple Account and
  received the same unavailable-product result. This disproves the embedded
  local catalog as the runtime cause. FrameWink uses an explicit App ID;
  In-App Purchase has no standalone entitlement key, so the sparse signed
  entitlement dictionary is expected and must not be "fixed" with an invented
  entitlement. TestFlight is not currently installed on the paired iPad. The
  next comparison is to install Internal TestFlight Build 19, or the released
  App Store build if TestFlight is unavailable, and verify whether the paywall
  loads Apple's localized price without initiating a purchase.
- The user installed Internal TestFlight build 19 on the same iPad and confirmed
  that the Lifetime product loads. This is positive physical evidence for the
  production identifier and App Store Connect sandbox path. The failure is
  isolated to the command-line generic Debug build installed and launched with
  `devicectl`, not to FrameWink's shipping StoreKit configuration. Future release
  acceptance must use the exact TestFlight binary; local development should use
  the test-bundle-only StoreKit catalog for deterministic transaction coverage.
- Final pre-merge shared-scheme verification passes on iPhone 17 Pro Max with
  192 passed, 5 environment-limited skips, and 0 failures, and on iPad (A16)
  with 193 passed, 4 environment-limited skips, and 0 failures. Result bundles:
  `/private/tmp/FrameWink-Favorites-Release-iPhone.xcresult` and
  `/private/tmp/FrameWink-Favorites-Release-iPad.xcresult`. Release Analyze and
  `CI_XCODEBUILD_ACTION=archive ci_scripts/ci_pre_xcodebuild.sh` pass. Expected
  diagnostics remain Apple's StoreKitTest deprecation, test-only transaction
  listener notices, system SwiftUI hosting warnings, and Xcode's debugger and
  post-test diagnostic-collector notes.

## Xcode Cloud review-card regression — 2026-09-07

- Validation Build 20 tested exact merge commit
  `c950c5b2c4bbe08b2556dca33b9cc60c7b552b8e`. Analyze succeeded; Test passed
  187 of 197 tests and failed two assertions in
  `testReviewNeverShowUsesNativeActionAndCanUndo`.
- The hosted destination correctly reported an off-screen third review action
  as not currently hittable and rendered the SwiftUI 44-point minimum as
  `43.99999999999994`. The updated regression scrolls each identified action
  into view and accepts only sub-half-point layout rounding. The production
  review-card layout remains unchanged.
- The focused corrected test passes on iPhone 17 Pro Max and iPad (A16) iOS
  27.0 Simulators. Result bundles:
  `/private/tmp/FrameWink-ReviewCardFix2-iPhone.xcresult` and
  `/private/tmp/FrameWink-ReviewCardFix2-iPad.xcresult`. The only compiler
  diagnostic is Apple's existing StoreKitTest deprecation warning.
- PR #8 merged the correction as exact main commit
  `2f23f472c73966757e144ec2d4ca97eeb7e028db`. Xcode Cloud Validation Build 21
  passed both Analyze and Test for that commit. Internal TestFlight Build 22
  then passed its clean iOS Archive action and `TestFlight Internal Testing -
  iOS` post-action using Xcode 26.6 on macOS Tahoe 26.6.2.
- App Store Connect independently shows version 1.0.1 build 22 as
  `Ready to Submit`, assigned to `Jenny Media Internal`. This proves cloud
  archive, processing, and internal distribution. The owner then confirmed the
  new photo-source flow works in the TestFlight installation, providing a
  manual physical interaction check for that flow. Full iPhone-and-iPad smoke
  coverage and VoiceOver wording remain open and were not inferred from this
  focused check.

## Outcome-based photo-choice verification — 2026-09-07

- The More menu now presents one `Choose What Plays` destination instead of
  parallel photo, album, and source-switch commands. The chooser always shows
  `Pick Individual Photos`, `Use an Album`, and separately grouped
  `Sample Photos`, with plain-language details and a native selected state.
- The empty individual-photo choice opens PHPicker after the explanation; an
  existing individual-photo or album choice switches the active frame source.
  The home card retains `Add More Photos` and `Choose a Different Album` for
  routine maintenance. Review remains independently available as
  `Review Photos in This Frame`.
- Five focused XCUI regressions pass with zero failures on iPhone 17 Pro Max
  and iPad (A16) iOS 27.0 Simulators. Result bundles:
  `/private/tmp/FrameWink-ChooseWhatPlays-iPhone.xcresult` and
  `/private/tmp/FrameWink-ChooseWhatPlays-iPad.xcresult`, plus the locked-album
  entitlement regression in `/private/tmp/FrameWink-AlbumChoice-iPhone.xcresult`
  and `/private/tmp/FrameWink-AlbumChoice-iPad.xcresult`. After tightening the
  configured-but-locked entitlement edge case, both affected chooser tests
  were rebuilt and passed again in
  `/private/tmp/FrameWink-ChooserGuard-iPhone.xcresult` and
  `/private/tmp/FrameWink-ChooserGuard-iPad.xcresult`.
- Captures exported from both result bundles were inspected. The compact iPhone
  layout shows complete choice labels and descriptions; the iPad form sheet
  keeps both choices, the Lifetime lock, and the active sample checkmark visible
  without clipping. Physical touch and VoiceOver wording remain manual checks.
- The final complete shared-scheme run passes 193 tests with 5
  environment-limited skips and zero failures on iPhone 17 Pro Max. On iPad
  (A16), 193 tests pass and 4 are skipped; the unrelated
  `testStoreKitTestAskToBuyReturnsPendingWithoutUnlocking` observed residual
  purchased state in the full run, then passed immediately when rerun alone.
  The preceding 197-test iPad full run passed before the fifth focused chooser
  regression was added. Result bundles:
  `/private/tmp/FrameWink-ChooseWhatPlays-Final-iPhone.xcresult`,
  `/private/tmp/FrameWink-ChooseWhatPlays-Final-iPad.xcresult`, and
  `/private/tmp/FrameWink-AskToBuy-Rerun-iPad.xcresult`. Expected
  diagnostics remain Apple's StoreKitTest deprecation, test-only transaction
  listener notices, SwiftUI hosting-view hierarchy warnings, debugger lookup
  notes, and the post-test `simctl` collector warning.
- Release Analyze passes for the generic iOS destination with signing disabled.
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
  CI_XCODEBUILD_ACTION=archive ci_scripts/ci_pre_xcodebuild.sh` also passes the
  archive release guard. Its sandboxed `xcodebuild` metadata query logs the
  existing CoreSimulator-service diagnostics after the plist and privacy
  manifest checks, without failing the guard.

## Review Undo clearance — 2026-09-09

- Baseline: added four UI checks on main `72c4618`, before changing production
  code. The short imported grid on landscape iPad passed; the full matrix
  reproduced the overlap in five of eight runs: automatic albums on both
  device families in both orientations, and imported photos on landscape
  iPhone. At the bottom of the scroll range, the hidden-photo control extended
  approximately 36 points below the Undo button's top edge.
- Fix: moved the conditional bottom safe-area inset from the outer
  `NavigationView` to its `ScrollView` for both sources. The scroll content now
  reserves room for the actual Undo bar height without a fixed spacer.
- Initial verification passed 33 of 34 selected checks on each device; the
  automatic-album landscape case was interrupted by Simulator SpringBoard
  crashes. A sequential retry passed on iPad; on iPhone, its setup could not
  scroll to the target card after rotation before launch. The regression now
  rotates the running app, waits for landscape geometry, and targets gestures
  to the review scroll view. The final run passes all four layout checks on
  each device (eight runs, no failures or skips). Together with the earlier
  27 unit and three existing UI checks per device, all 34 selected checks have
  passing evidence on both iPhone and iPad. Both application and test targets
  build successfully; `git diff --check` passes.
- The selected tests include both affected controller suites, four layout
  checks, existing Undo, individual recovery, and empty-frame recovery. The
  layout checks also open Hidden from Frame while Undo is still visible and
  retain screenshots in the result bundle. Inspected portrait captures show
  the complete hidden-photo entry above the Undo bar on both device families.
- Diagnostics: the initial test build emitted Apple's existing StoreKitTest
  deprecation warning. Xcode also reported debugger-version lookup and
  post-test diagnostic-collector `simctl` lookup warnings. No app runtime
  warning was reported in the result summary.
- Commands below ran from `/private/tmp/framewink-review-undo`. Both discovered
  destinations run iOS 27.0. The initial sandboxed destination lookup could
  not access CoreSimulator; approved execution outside that sandbox succeeded.

```sh
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcodebuild -showdestinations -project FrameWink.xcodeproj -scheme FrameWink

common=(
  -quiet -project FrameWink.xcodeproj -scheme FrameWink
  -derivedDataPath /private/tmp/FrameWink-Undo-DerivedData
)
devices=(
  -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F'
  -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE'
)
layout_checks=(
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewHiddenPhotosRemainAboveUndo
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewHiddenPhotosRemainAboveUndoInLandscape
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testAutomaticReviewHiddenPhotosRemainAboveUndo
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testAutomaticReviewHiddenPhotosRemainAboveUndoInLandscape
)

# Before the production fix:
xcodebuild "${common[@]}" \
  -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' \
  -resultBundlePath /private/tmp/FrameWink-Undo-Baseline-iPad.xcresult \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewHiddenPhotosRemainAboveUndoInLandscape test
xcodebuild "${common[@]}" "${devices[@]}" "${layout_checks[@]}" \
  -resultBundlePath /private/tmp/FrameWink-Undo-Baseline-Both.xcresult test-without-building

# After the production fix:
xcodebuild "${common[@]}" "${devices[@]}" "${layout_checks[@]}" \
  -resultBundlePath /private/tmp/FrameWink-Undo-Fixed-Both.xcresult \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewNeverShowUsesNativeActionAndCanUndo \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewCanRestoreAnOlderNeverShowChoice \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewEmptyStateCanRestoreExcludedPhotos \
  -only-testing:FrameWinkTests/AppModelRecoveryTests \
  -only-testing:FrameWinkTests/AutomaticAlbumControllerTests test

# Isolate the interrupted landscape case, then verify the stabilized UI checks:
xcodebuild "${common[@]}" "${devices[@]}" \
  -disable-concurrent-destination-testing \
  -resultBundlePath /private/tmp/FrameWink-Undo-Landscape-Retry.xcresult \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testAutomaticReviewHiddenPhotosRemainAboveUndoInLandscape test-without-building
xcodebuild "${common[@]}" "${devices[@]}" "${layout_checks[@]}" \
  -resultBundlePath /private/tmp/FrameWink-Undo-Final-UI.xcresult test
git diff --check
```

## Combined photo-choice and Undo verification — 2026-09-09

- Preserved the photo chooser installed on the iPad, integrated the four
  Undo layout regressions, and recorded the user-confirmed physical fix.
- Final combined verification passes all 12 selected UI tests on each of
  iPhone 17 Pro Max and iPad (A16): 24 runs, zero failures, and zero skips.
  Coverage includes photo choice, Lifetime gating, source preservation, review
  entry, both review sources and orientations, Undo, and hidden-photo recovery.
  App and test builds and `git diff --check` pass. Diagnostics are limited to
  the existing Apple StoreKitTest deprecation and debugger-version lookup
  notes; the result bundle reports no app runtime warnings.
- Exact command from `/private/tmp/framewink-favorites`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet \
  -project FrameWink.xcodeproj -scheme FrameWink \
  -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' \
  -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' \
  -derivedDataPath /private/tmp/FrameWink-Undo-Publish-DerivedData \
  -resultBundlePath /private/tmp/FrameWink-Undo-Publish.xcresult \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewHiddenPhotosRemainAboveUndo \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewHiddenPhotosRemainAboveUndoInLandscape \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testAutomaticReviewHiddenPhotosRemainAboveUndo \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testAutomaticReviewHiddenPhotosRemainAboveUndoInLandscape \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewNeverShowUsesNativeActionAndCanUndo \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewCanRestoreAnOlderNeverShowChoice \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewEmptyStateCanRestoreExcludedPhotos \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testChooseWhatPlaysExplainsIndividualPhotosBeforeSystemPicker \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testLockedAlbumChoiceExplainsLifetimeBeforeRequestingPhotosAccess \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReadyFrameOffersClearPhotoChoiceAndReviewActions \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testChangingPlaybackSettingsKeepsTheSelectedPhotoSource \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testHomeUsesOnePrimaryActionAndMovesMaintenanceBehindMore \
  test
git diff --check
```

- Remaining manual evidence: physical iPhone/iPad touch and VoiceOver checks,
  an iPad resized-window check, and iOS/iPadOS 15 runtime compatibility. This
  Simulator change does not establish real PhotoKit, purchase, thermal,
  brightness, Guided Access, or long-running device behavior. Subsequent installation of this exact review-view change alongside the newer
  photo chooser succeeded on the iPad Pro. The user confirmed the fix works
  on 2026-09-09; see the installation commands in `docs/PLAN.md`. This does
  not establish VoiceOver or resized-window acceptance. No TestFlight
  distribution or App Store submission was performed.

## Xcode Cloud album-count cancellation test — 2026-09-09

- Build 23 (`01c2362f-3b95-406b-824e-ad026197fdd0`) analyzed main
  `8b69555b09d2aeb8f40a84bc6e7d3025296f40cf` successfully, then failed
  `AutomaticAlbumControllerTests.testSelectingAlbumCancelsRemainingEligiblePhotoCounts`
  at the active-request assertion: `1` instead of `0`. The existing
  StoreKitTest SDK deprecation was a warning, not the failure.
- The original test passed ten local iPhone repetitions. Its fixed
  100-millisecond sleep does not synchronize with utility-task cancellation
  cleanup. A temporary 300-millisecond delay in the mock's cancellation
  cleanup reproduced that same active-request assertion; replacing the sleep
  with the state wait passed under the same injected delay. Both experiments
  used the final cancellation-only fixture. The temporary delay and old wait
  were removed afterward.
- The final fixture suspends via an AsyncStream that ends on task cancellation,
  rather than a timer that could complete before album selection. The test
  waits for zero active requests, requires an explicit cancellation record for
  the first album, checks the second count never started, and rejects published
  count values. A defer requests cleanup even if setup/assertions fail.
- The complete affected controller suite passes on iPhone 17 Pro Max and iPad
  (A16), iOS 27.0: 23 tests per destination, 46 executions, zero failures,
  skips, or result-summary runtime warnings. App and test builds pass. The
  initial fixture initializer compile error was corrected before these runs.
  The restored final cancellation test also passes 20 repetitions on each
  family (40 executions, zero failures or skips).
- Expected diagnostics: Apple's existing StoreKitTest deprecation warning and
  Xcode's post-test internal `simctl` diagnostic-collector lookup warning.
  The initial sandbox-only destination lookup could not reach CoreSimulator;
  approved access discovered both families and ran the tests successfully.
- Commands ran from `/private/tmp/framewink-album-count-fix`:

```sh
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcodebuild -showdestinations -project FrameWink.xcodeproj -scheme FrameWink
common=(
  -quiet -project FrameWink.xcodeproj -scheme FrameWink
  -derivedDataPath /private/tmp/FrameWink-AlbumCount-Tests
)
iphone=(-destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE')
ipad=(-destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F')
check=(-only-testing:FrameWinkTests/AutomaticAlbumControllerTests/testSelectingAlbumCancelsRemainingEligiblePhotoCounts)

# Original main before changes: 10 passing repetitions.
xcodebuild "${common[@]}" "${iphone[@]}" "${check[@]}" -test-iterations 10 \
  -resultBundlePath /private/tmp/FrameWink-AlbumCount-Baseline.xcresult test
# Final source: full affected suite on both device families.
xcodebuild "${common[@]}" "${iphone[@]}" "${ipad[@]}" \
  -only-testing:FrameWinkTests/AutomaticAlbumControllerTests \
  -parallel-testing-enabled NO \
  -resultBundlePath /private/tmp/FrameWink-AlbumCount-Fixed2.xcresult test
# Temporary mock cleanup delay: old wait fails, corrected wait passes.
xcodebuild "${common[@]}" "${iphone[@]}" "${check[@]}" \
  -resultBundlePath /private/tmp/FrameWink-AlbumCount-Delayed-OldWait.xcresult test
xcodebuild "${common[@]}" "${iphone[@]}" "${check[@]}" \
  -resultBundlePath /private/tmp/FrameWink-AlbumCount-Delayed-NewWait.xcresult test
# Final source restored, without the temporary delay.
xcodebuild "${common[@]}" "${iphone[@]}" "${ipad[@]}" "${check[@]}" \
  -test-iterations 20 \
  -resultBundlePath /private/tmp/FrameWink-AlbumCount-Repeated.xcresult test
git diff --check
```

- No production code, signing, workflow settings, or TestFlight distribution
  changed. No additional physical test is required for this test-only fix.
  Xcode Cloud confirmation remains pending.

## Hosted compact-landscape review test synchronization — 2026-09-09

- Xcode Cloud Validation Build 24 at `29b9f6d` passed Analyze and the repaired
  album-count regression. It finished with 192 passed, 9 environment-limited
  skips, and one failure: the iPhone SE (3rd generation), iOS 26.5 worker
  failed in `testAutomaticReviewHiddenPhotosRemainAboveUndoInLandscape` while
  querying an off-screen Never Show Again button's `isHittable` property.
  XCTest reported an invalid activation point at line 507, before the Undo
  overlap assertion or tap executed.
- The shared four-case review helper now checks a nonempty button frame against
  the intersection of the scroll-view and app frames before requesting
  hittability. It still requires the final button to be tappable, performs the
  actual tap, compares the complete Hidden from Frame control against Undo,
  and opens Hidden from Frame while Undo is visible. Production layout and
  Undo duration are unchanged.
- A local iPhone SE (3rd generation) Simulator was created on the available
  iOS 27.0 runtime. The baseline single landscape test passed there, so this
  local run does not claim to reproduce Apple's iOS 26.5 activation-point
  failure. Final coverage includes all four portrait/landscape/source cases on
  iPhone SE, iPhone 17 Pro Max, and iPad (A16): all 12 executions pass with
  zero failures or skips and no result-summary runtime warnings. The existing
  debugger-version lookup notes are non-failing.
- Validation was enabled before merge using a temporary manual start condition
  scoped only to `codex/fix-album-count-cancellation`. The automatic main
  condition, required actions, destinations, and TestFlight workflow remain
  unchanged. The temporary condition will be removed after the final run;
  the completed hosted result is recorded in PR #11.

```sh
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
# Isolated compact destination, using the installed runtime.
xcrun simctl create 'FrameWink CI iPhone SE' \
  com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation \
  com.apple.CoreSimulator.SimRuntime.iOS-27-0
# Baseline before changing the review test helper.
xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink \
  -destination 'platform=iOS Simulator,id=8782C2D6-1D6A-4195-A5C1-8A948D1B7AC6' \
  -derivedDataPath /private/tmp/FrameWink-AlbumCount-Tests \
  -resultBundlePath /private/tmp/FrameWink-SE-Review-Baseline.xcresult \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testAutomaticReviewHiddenPhotosRemainAboveUndoInLandscape test
# Corrected helper on all three device sizes.
xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink \
  -destination 'platform=iOS Simulator,id=8782C2D6-1D6A-4195-A5C1-8A948D1B7AC6' \
  -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' \
  -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' \
  -derivedDataPath /private/tmp/FrameWink-AlbumCount-Tests \
  -resultBundlePath /private/tmp/FrameWink-Review-Visibility-Fixed.xcresult \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewHiddenPhotosRemainAboveUndo \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testReviewHiddenPhotosRemainAboveUndoInLandscape \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testAutomaticReviewHiddenPhotosRemainAboveUndo \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testAutomaticReviewHiddenPhotosRemainAboveUndoInLandscape test
```

## Restore feedback and duration retention (#2, #3) — 2026-09-09

- Baseline: `5a1e56d` plus new reopen tests. Selecting `10s` once, closing
  Frame Controls, and reopening fails in the paid saved-frame fixture on
  both iPad (A16) and iPhone 17 Pro Max, iOS 27.0. The matching free-frame
  cases pass. A temporary trace in the paid case records `select new=10,
  playback=30, preferred=60` followed by `apply playback=10, preferred=60`.
  The change callback discarded its new-value argument and read the previous
  view's captured preference. All temporary trace logging was removed.
- The fix consumes the callback's new interval, keeps layout updates separate
  from timing, avoids resetting an unchanged interval, and removes the picker
  selection cache. The visible selection now reflects actual playback state.
- Restore now returns an explicit outcome and presents an alert from the
  stable paywall container, even when a successful restore swaps out purchase
  controls for the unlocked content. It distinguishes verified success, no
  purchase, revoked purchase, and verification/store failures. In-flight
  restore has its own progress label and disables both purchase actions.
- All 44 selected checks pass on each device family (88 executions), with
  zero failures, skips, or result-summary runtime warnings. This includes
  35 controller tests and nine UI cases per device. Unit coverage includes
  failure/retry and entitlement lookup failure; UI coverage includes all five
  restore outcomes, repeat restore, free/paid reopen, rapid duration selection,
  and source preservation. The separate actual-advancement check also passes on both families,
  proving the first 10-second selection changes actual playback, with no
  immediate advancement (90 passing executions in total).
  Its first compile found a missing test wait helper; the helper was added
  before rerunning. No application change was needed for that compile error.
- Diagnostics: Apple's existing StoreKitTest header deprecation appears in
  the initial baseline build. Xcode emits its debugger-version lookup notes;
  these are not app runtime failures. App and test builds pass on both
  families. StoreKit UI fixtures use the existing DEBUG-only purchase client;
  no real transaction is made and no signing/product configuration is changed.
- Remaining physical checks: repeat the owner's single-select/dismiss/reopen
  sequence on the iPad, including outside-tap dismissal and resized windows;
  use sandbox/TestFlight to confirm Apple's real restore/account flow. These
  simulator checks do not establish production restore or iOS 15 acceptance.

Commands run from the isolated `codex/fix-restore-and-duration` checkout
(`/private/tmp/framewink-issues-2-3`):

```sh
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcrun simctl list devices booted
common=(-quiet -project FrameWink.xcodeproj -scheme FrameWink
  -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F'
  -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE'
  -derivedDataPath /private/tmp/FrameWink-Issues23)
reopen=(-only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testFreeFrameDurationSurvivesClosingAndReopeningControls
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPaidFrameDurationSurvivesClosingAndReopeningControls)
xcodebuild "${common[@]}" "${reopen[@]}" \
  -resultBundlePath /private/tmp/FrameWink-Issues23-Baseline.xcresult test
# Temporary duration logging only; one iPad destination for diagnosis.
xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink \
  -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' \
  -derivedDataPath /private/tmp/FrameWink-Issues23 \
  -resultBundlePath /private/tmp/FrameWink-Issues23-Trace.xcresult \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPaidFrameDurationSurvivesClosingAndReopeningControls test
xcrun simctl spawn B3A8D8D4-D576-4245-A0EC-ED914C0C744F \
  log show --last 2m --style compact --predicate 'eventMessage CONTAINS "FW_DURATION"'
xcodebuild "${common[@]}" "${reopen[@]}" \
  -resultBundlePath /private/tmp/FrameWink-Issues23-Fixed.xcresult \
  -only-testing:FrameWinkTests/PurchaseControllerTests \
  -only-testing:FrameWinkTests/FrameSessionControllerTests \
  -only-testing:FrameWinkTests/FrameConfigurationControllerTests \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testFrameDurationRespondsToEverySingleTap \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testChangingPlaybackSettingsKeepsTheSelectedPhotoSource \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testRestorePurchasesShowsSuccessAfterUnlocking \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testRestorePurchasesShowsNoPurchaseAndCanBeRepeated \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testRestorePurchasesShowsVerificationFailure \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testRestorePurchasesShowsRevokedPurchase \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testRestorePurchasesShowsStoreFailure test
xcodebuild "${common[@]}" \
  -resultBundlePath /private/tmp/FrameWink-Issues23-Advancement2.xcresult \
  -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPaidFrameAdvancesUsingTheFirstSelectedDuration test
xcrun xcresulttool get test-results summary \
  --path /private/tmp/FrameWink-Issues23-Fixed.xcresult --format json
xcrun xcresulttool get test-results summary \
  --path /private/tmp/FrameWink-Issues23-Advancement2.xcresult --format json
git diff --check
```

## Photo storage and responsive deletion — 2026-09-17

- Source review found that automatic albums persisted a display-sized JPEG for
  every eligible candidate without a byte budget. Picker imports were limited
  to 500, but both complete deletion actions removed directories synchronously
  from the main actor. No measurement of the owner's 8 GB iPhone container was
  available in this pass.
- The new storage view measures app-controlled imported copies and analysis,
  automatic-album downloads and analysis, and picker working files off the main
  thread. A 512 MiB automatic-album image working-set target triggers
  checkpoint curation and prunes images outside the active reel while retaining
  candidate metadata and reusable signals. An evicted image can be restored
  from PhotoKit. The budget is a target, since a batch or active reel can exceed
  it temporarily. New album downloads stop below 512 MiB of free device space.
  Abandoned picker staging and partial imports older than one day are removed
  on launch. Both full-data deletion actions await active work, delete files
  away from the main thread, and show progress.
- The final affected set passed 58 tests with zero failures, skips, or result
  runtime warnings on each of iPhone 17 Pro Max and iPad (A16), iOS 27.0
  Simulators. The set includes storage measurement and old-file cleanup,
  selected-image preservation and candidate-metadata retention, low-storage
  album interruption, the album controller's 150-candidate/100-selection quota
  checkpoint, saved-reel recovery when an image is missing, off-main imported
  and album deletion, existing import recovery,
  and the existing imported-photo deletion UI flow. The generic iOS Simulator
  app build also passed. The initial test-target build emitted Apple's existing
  StoreKitTest deprecation; final incremental test runs logged only Xcode's
  debugger-version lookup notice.
- Still required on physical devices: measure the owner's pre/post-cleanup
  storage by category, verify app responsiveness while deleting a large real
  import, test a several-thousand-photo album and iCloud refetch after pruning,
  and check offline behavior when an evicted image is selected. Simulator
  results do not establish those PhotoKit, storage, or device-timing outcomes.

Commands run from `/Users/yihong/work/FrameWink` with
`/private/tmp/FrameWink-Storage-DerivedData`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/FrameWink-Storage-DerivedData CODE_SIGNING_ALLOWED=NO build
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' -derivedDataPath /private/tmp/FrameWink-Storage-DerivedData -resultBundlePath /private/tmp/FrameWink-Storage-iPhone-FinalCurrent.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/LocalStorageUsageTests -only-testing:FrameWinkTests/LocalAlbumSourceStoreTests -only-testing:FrameWinkTests/AlbumSyncServiceTests -only-testing:FrameWinkTests/AppModelRecoveryTests -only-testing:FrameWinkTests/AutomaticAlbumControllerTests -only-testing:FrameWinkTests/PhotoImportServiceTests -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPersonalReelPlaysFromLocalCopiesAndDeleteAllReturnsToSamples test-without-building
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-Storage-DerivedData -resultBundlePath /private/tmp/FrameWink-Storage-iPad-Final.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/LocalStorageUsageTests -only-testing:FrameWinkTests/LocalAlbumSourceStoreTests -only-testing:FrameWinkTests/AlbumSyncServiceTests -only-testing:FrameWinkTests/AppModelRecoveryTests -only-testing:FrameWinkTests/AutomaticAlbumControllerTests -only-testing:FrameWinkTests/PhotoImportServiceTests -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPersonalReelPlaysFromLocalCopiesAndDeleteAllReturnsToSamples test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-Storage-iPhone-FinalCurrent.xcresult
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-Storage-iPad-Final.xcresult
git diff --check
```

## Unified photo storage controls — 2026-09-17

- `Privacy & Data` now has one destructive `Delete All FrameWink Photos…`
  action. Its confirmation names the lost current selections and reels, chosen
  album, saved frames that use those photo sources, analysis, and Never Show
  Again choices, and states that Apple Photos is unchanged. Sample-only saved
  frames remain. A separate `Free Up Unused Space` action removes abandoned
  picker working files and unused automatic-album copies while retaining the
  current selections and album; automatic pruning also continues.
- The final affected set passed **64 of 64 tests on each** iPhone 17 Pro Max and
  iPad (A16), iOS 27.0 Simulators, with zero failures, skips, or result runtime
  warnings. The set includes the deletion warning and return to samples,
  off-main deletion, full picker-working-file removal, the album cache budget,
  and persistence of saved-frame cleanup. The generic iOS Simulator app build
  passed. Xcode logged only debugger-version lookup notices during final runs.
- An earlier iPad run failed because an XCUI exact-string lookup exceeded its
  128-character query limit. The test now queries a short warning phrase and
  separately checks the Apple Photos sentence; both final device-family runs
  pass. The failure was in the test query, not app behavior.
- Still required on physical devices: inspect the warning with touch and
  VoiceOver, confirm immediate safe cleanup and full reset with real imported
  and automatic-album data, and measure actual space recovered. No signed
  physical-device install or App Store distribution happened in this pass.

Final commands from `/Users/yihong/work/FrameWink`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project FrameWink.xcodeproj -scheme FrameWink -showdestinations
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/FrameWink-Storage-DerivedData CODE_SIGNING_ALLOWED=NO build
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-Storage-DerivedData -resultBundlePath /private/tmp/FrameWink-Storage-UX-iPad-Complete.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/LocalStorageUsageTests -only-testing:FrameWinkTests/LocalAlbumSourceStoreTests -only-testing:FrameWinkTests/AlbumSyncServiceTests -only-testing:FrameWinkTests/AppModelRecoveryTests -only-testing:FrameWinkTests/AutomaticAlbumControllerTests -only-testing:FrameWinkTests/PhotoImportServiceTests -only-testing:FrameWinkTests/FrameConfigurationControllerTests -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPersonalReelPlaysFromLocalCopiesAndDeleteAllReturnsToSamples test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' -derivedDataPath /private/tmp/FrameWink-Storage-DerivedData -resultBundlePath /private/tmp/FrameWink-Storage-UX-iPhone-Complete.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/LocalStorageUsageTests -only-testing:FrameWinkTests/LocalAlbumSourceStoreTests -only-testing:FrameWinkTests/AlbumSyncServiceTests -only-testing:FrameWinkTests/AppModelRecoveryTests -only-testing:FrameWinkTests/AutomaticAlbumControllerTests -only-testing:FrameWinkTests/PhotoImportServiceTests -only-testing:FrameWinkTests/FrameConfigurationControllerTests -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPersonalReelPlaysFromLocalCopiesAndDeleteAllReturnsToSamples test-without-building
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-Storage-UX-iPad-Complete.xcresult
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-Storage-UX-iPhone-Complete.xcresult
git diff --check
```

## Paired iPhone installation — 2026-09-17

- `devicectl` found the paired physical iPhone 17 Pro Max at
  `00008150-00080C3C3C07801C`. Before installation, its development copy of
  `media.jenny.FrameWink` was version 1.0.1 (26).
- A Debug build for that device succeeded using existing automatic signing and
  the command-line-only `CURRENT_PROJECT_VERSION=28` override. The built app
  reports `media.jenny.FrameWink` 1.0.1 (28). The signature verified outside
  the sandbox and its provisioning profile expires 2027-08-13.
- `devicectl` installed the app over the existing bundle without uninstalling
  it, then launched it. An independent installed-app query reported 1.0.1 (28)
  and a process query found FrameWink running on the device. No photo-data
  cleanup action was performed. Existing photo selections, real storage sizes,
  touch/VoiceOver behavior, and saved-space outcomes remain manual checks.
- This is a development-signed install. It does not validate the production
  Lifetime in-app purchase or constitute a TestFlight/App Store release.

Commands run from `/Users/yihong/work/FrameWink`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl list devices
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008150-00080C3C3C07801C --bundle-id media.jenny.FrameWink --columns '*'
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS,id=00008150-00080C3C3C07801C' -derivedDataPath /private/tmp/FrameWink-Storage-Physical-iPhone-28 CURRENT_PROJECT_VERSION=28 build
codesign --verify --deep --strict --verbose=2 /private/tmp/FrameWink-Storage-Physical-iPhone-28/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device install app --device 00008150-00080C3C3C07801C /private/tmp/FrameWink-Storage-Physical-iPhone-28/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008150-00080C3C3C07801C --bundle-id media.jenny.FrameWink --columns '*' --include-container-paths
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device process launch --device 00008150-00080C3C3C07801C --terminate-existing media.jenny.FrameWink
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info processes --device 00008150-00080C3C3C07801C --search FrameWink
git diff --check
```

## Paired iPad installation — 2026-09-17

- `devicectl` found the paired physical iPad Pro at
  `00008027-000C25D036EB002E`. Before installation, its development copy of
  `media.jenny.FrameWink` was version 1.0.1 (1).
- A Debug build for that device succeeded using existing automatic signing and
  the command-line-only `CURRENT_PROJECT_VERSION=28` override. The built app
  reports `media.jenny.FrameWink` 1.0.1 (28), passed signature verification,
  and has a provisioning profile expiring 2027-08-13.
- `devicectl` installed the update over the existing app without uninstalling
  it. A separate installed-app query reported 1.0.1 (28); launch succeeded and
  a process query found FrameWink running. No photo-data cleanup action was
  performed. Stored photo selections and real storage savings have not yet
  been checked on the device. This development install does not validate the
  production Lifetime purchase path or a TestFlight/App Store release.

Commands run from `/Users/yihong/work/FrameWink`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl list devices
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008027-000C25D036EB002E --bundle-id media.jenny.FrameWink --columns '*'
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS,id=00008027-000C25D036EB002E' -derivedDataPath /private/tmp/FrameWink-Storage-Physical-iPad-28 CURRENT_PROJECT_VERSION=28 build
codesign --verify --deep --strict --verbose=2 /private/tmp/FrameWink-Storage-Physical-iPad-28/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device install app --device 00008027-000C25D036EB002E /private/tmp/FrameWink-Storage-Physical-iPad-28/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008027-000C25D036EB002E --bundle-id media.jenny.FrameWink --columns '*'
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device process launch --device 00008027-000C25D036EB002E --terminate-existing media.jenny.FrameWink
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info processes --device 00008027-000C25D036EB002E --search FrameWink
git diff --check
```

## Storage action progress — 2026-09-17

- Code review confirms automatic maintenance removes only abandoned picker
  staging and partial imported files older than 24 hours on launch, plus
  downloaded automatic-album JPEGs outside the active reel after the image
  cache exceeds its soft 512 MiB target. Switching albums removes old JPEGs for
  assets absent from the new album during sync commits. Safe manual cleanup
  forces the unused-album-JPEG pruning even below the target. Picker imports,
  the active reel, and Apple Photos originals are not automatically deleted.
- `Privacy & Data` now shows a distinct labeled indeterminate linear progress
  bar for safe cleanup and full deletion. Each remains for at least two seconds
  and until the underlying work and storage refresh finish. The screen reports
  the new storage size at completion; no unsupported percentage is shown.
- Final focused UI results: 2 passed, 0 failed/skipped, and no result runtime
  warnings on each iPhone 17 Pro Max and iPad (A16), iOS 27.0 Simulators. The
  deletion test confirms its bar and return to samples; the safe cleanup test
  confirms its bar, result, and retained personal selection. An initial iPad
  run failed to observe a one-second transient indicator; the two-second
  version passed on both families. Xcode logged non-failing debugger-version
  lookup notices. Physical visual timing remains to be checked.

Commands run from `/Users/yihong/work/FrameWink`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project FrameWink.xcodeproj -scheme FrameWink -showdestinations
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-Storage-DerivedData -resultBundlePath /private/tmp/FrameWink-Storage-Progress-iPad-2.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPersonalReelPlaysFromLocalCopiesAndDeleteAllReturnsToSamples -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testSafeCleanupShowsProgressAndKeepsPersonalSelection test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' -derivedDataPath /private/tmp/FrameWink-Storage-DerivedData -resultBundlePath /private/tmp/FrameWink-Storage-Progress-iPhone-2.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPersonalReelPlaysFromLocalCopiesAndDeleteAllReturnsToSamples -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testSafeCleanupShowsProgressAndKeepsPersonalSelection test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-Storage-Progress-iPad-2.xcresult
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-Storage-Progress-iPhone-2.xcresult
git diff --check
```

## Storage progress builds on paired devices — 2026-09-17

- Existing automatically signed Debug builds for iPhone 17 Pro Max and iPad Pro
  succeeded with the command-line-only `CURRENT_PROJECT_VERSION=29` override.
  Both artifacts report bundle ID `media.jenny.FrameWink`, build 29, and passed
  signature verification. Project signing and version files were unchanged.
- The iPhone install over build 28 succeeded; an independent installed-app
  query showed 1.0.1 (29). Launch succeeded and a process query found the new
  app running.
- The first iPad install attempt ended with CoreDevice 3002 / IXRemote 6 when
  the device connection closed. A read-only installed-app query showed build 28
  still present. A retry installed build 29 successfully, and a later query
  independently confirmed 1.0.1 (29). Launch was denied by SpringBoard because
  the iPad was locked. A follow-up process query lost the device connection;
  iPad launch and progress-bar appearance remain physical checks.
- Neither device was uninstalled, and no manual cleanup or full deletion was
  triggered. These development installs do not validate production purchases,
  actual storage savings, or TestFlight/App Store readiness.

Commands run from `/Users/yihong/work/FrameWink`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS,id=00008150-00080C3C3C07801C' -derivedDataPath /private/tmp/FrameWink-Storage-Physical-iPhone-29 CURRENT_PROJECT_VERSION=29 build
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS,id=00008027-000C25D036EB002E' -derivedDataPath /private/tmp/FrameWink-Storage-Physical-iPad-29 CURRENT_PROJECT_VERSION=29 build
codesign --verify --deep --strict --verbose=2 /private/tmp/FrameWink-Storage-Physical-iPhone-29/Build/Products/Debug-iphoneos/FrameWink.app
codesign --verify --deep --strict --verbose=2 /private/tmp/FrameWink-Storage-Physical-iPad-29/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device install app --device 00008150-00080C3C3C07801C /private/tmp/FrameWink-Storage-Physical-iPhone-29/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device install app --device 00008027-000C25D036EB002E /private/tmp/FrameWink-Storage-Physical-iPad-29/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device install app --device 00008027-000C25D036EB002E --timeout 180 /private/tmp/FrameWink-Storage-Physical-iPad-29/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008150-00080C3C3C07801C --bundle-id media.jenny.FrameWink --columns '*'
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008027-000C25D036EB002E --bundle-id media.jenny.FrameWink --columns '*'
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device process launch --device 00008150-00080C3C3C07801C --terminate-existing media.jenny.FrameWink
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device process launch --device 00008027-000C25D036EB002E --terminate-existing media.jenny.FrameWink
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info processes --device 00008150-00080C3C3C07801C --search FrameWink
git diff --check
```

## Recent automatic-album cache — 2026-09-17

- The new store tests cover retention of three selected albums, reuse of a
  shared image, eviction on a fourth album, oldest-first budget pruning,
  explicit cleanup, single-album cache migration, and saved-reel album identity.
  The synchronizer test verifies switching back reuses downloads rather than
  exporting them again. Final controller tests verify a canceled sync finishes
  before the next album sync starts and that the old album review list clears.
- The affected set passed **47/47** on iPhone 17 Pro Max and **47/47** on iPad
  (A16), iOS 27.0 Simulators. After the last controller changes,
  controller tests passed **27/27** on each family. Final result bundles show
  no failures, skips, or runtime warnings. The generic Simulator app build and
  both signed physical-device builds passed. One earlier iPhone controller
  wait timed out once; it passed on immediate rerun and in the final set.
  Initial test-target compilation emitted an Apple StoreKitTest deprecation;
  Xcode also logged non-failing debugger-version lookup notices.
- Signed development build 1.0.1 (31) installed over the earlier development
  builds on the paired iPhone and iPad without uninstalling or triggering
  cleanup. Signature checks passed; separate app queries confirmed build 31
  on both. The first final iPad query returned no app row; the retry succeeded.
  Launch on both devices was denied because they were locked. Real PhotoKit
  switching, iCloud refetch, measured storage
  recovery, and visual confirmation remain unverified. This is not a
  TestFlight or App Store release.

Commands run from `/Users/yihong/work/FrameWink`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project FrameWink.xcodeproj -scheme FrameWink -showdestinations
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun simctl list devices available
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/FrameWink-MultiAlbum-DerivedData CODE_SIGNING_ALLOWED=NO build
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-MultiAlbum-DerivedData -resultBundlePath /private/tmp/FrameWink-MultiAlbum-iPad-Final.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/LocalAlbumSourceStoreTests -only-testing:FrameWinkTests/AlbumSyncServiceTests -only-testing:FrameWinkTests/AutomaticAlbumControllerTests -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testSafeCleanupShowsProgressAndKeepsPersonalSelection test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' -derivedDataPath /private/tmp/FrameWink-MultiAlbum-DerivedData -resultBundlePath /private/tmp/FrameWink-MultiAlbum-iPhone-Final.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/LocalAlbumSourceStoreTests -only-testing:FrameWinkTests/AlbumSyncServiceTests -only-testing:FrameWinkTests/AutomaticAlbumControllerTests -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testSafeCleanupShowsProgressAndKeepsPersonalSelection test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' -derivedDataPath /private/tmp/FrameWink-MultiAlbum-DerivedData -resultBundlePath /private/tmp/FrameWink-MultiAlbum-iPhone-Serialization.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/AutomaticAlbumControllerTests test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-MultiAlbum-DerivedData -resultBundlePath /private/tmp/FrameWink-MultiAlbum-iPad-Serialization.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/AutomaticAlbumControllerTests test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS,id=00008150-00080C3C3C07801C' -derivedDataPath /private/tmp/FrameWink-MultiAlbum-Physical-iPhone-30 CURRENT_PROJECT_VERSION=30 build
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS,id=00008027-000C25D036EB002E' -derivedDataPath /private/tmp/FrameWink-MultiAlbum-Physical-iPad-30 CURRENT_PROJECT_VERSION=30 build
codesign --verify --deep --strict --verbose=2 /private/tmp/FrameWink-MultiAlbum-Physical-iPhone-30/Build/Products/Debug-iphoneos/FrameWink.app
codesign --verify --deep --strict --verbose=2 /private/tmp/FrameWink-MultiAlbum-Physical-iPad-30/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device install app --device 00008150-00080C3C3C07801C /private/tmp/FrameWink-MultiAlbum-Physical-iPhone-30/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device install app --device 00008027-000C25D036EB002E --timeout 180 /private/tmp/FrameWink-MultiAlbum-Physical-iPad-30/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008150-00080C3C3C07801C --bundle-id media.jenny.FrameWink --columns '*'
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008027-000C25D036EB002E --bundle-id media.jenny.FrameWink --columns '*'
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device process launch --device 00008150-00080C3C3C07801C --terminate-existing media.jenny.FrameWink
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device process launch --device 00008027-000C25D036EB002E --terminate-existing media.jenny.FrameWink
git diff --check
```

Final review-list fix, rebuild, and data-preserving install:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' -derivedDataPath /private/tmp/FrameWink-MultiAlbum-DerivedData -resultBundlePath /private/tmp/FrameWink-MultiAlbum-iPhone-Review.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/AutomaticAlbumControllerTests test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-MultiAlbum-DerivedData -resultBundlePath /private/tmp/FrameWink-MultiAlbum-iPad-Review.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/AutomaticAlbumControllerTests test-without-building
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS,id=00008150-00080C3C3C07801C' -derivedDataPath /private/tmp/FrameWink-MultiAlbum-Physical-iPhone-31 CURRENT_PROJECT_VERSION=31 build
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS,id=00008027-000C25D036EB002E' -derivedDataPath /private/tmp/FrameWink-MultiAlbum-Physical-iPad-31 CURRENT_PROJECT_VERSION=31 build
codesign --verify --deep --strict --verbose=2 /private/tmp/FrameWink-MultiAlbum-Physical-iPhone-31/Build/Products/Debug-iphoneos/FrameWink.app
codesign --verify --deep --strict --verbose=2 /private/tmp/FrameWink-MultiAlbum-Physical-iPad-31/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device install app --device 00008150-00080C3C3C07801C /private/tmp/FrameWink-MultiAlbum-Physical-iPhone-31/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device install app --device 00008027-000C25D036EB002E --timeout 180 /private/tmp/FrameWink-MultiAlbum-Physical-iPad-31/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008150-00080C3C3C07801C --bundle-id media.jenny.FrameWink --columns '*'
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008027-000C25D036EB002E --bundle-id media.jenny.FrameWink --columns '*'
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device process launch --device 00008150-00080C3C3C07801C --terminate-existing media.jenny.FrameWink
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device process launch --device 00008027-000C25D036EB002E --terminate-existing media.jenny.FrameWink
git diff --check
```

## Adaptive album download target — 2026-09-18

- Shared album images use a 1 GiB soft target when free space plus cached
  album images is at least 3 GiB, and a 512 MiB target below that headroom.
  The current reel remains protected, downloads still stop below 512 MiB of
  free device space, and manual cleanup still forces unused downloads out.
- The affected set passed **54/54 tests on each** iPhone 17 Pro Max and iPad
  (A16), iOS 27.0 Simulators, with no failures, skips, or result runtime
  warnings. New tests cover the exact tier boundary, stable tier selection
  as cache bytes change, pruning a 600 MiB cache in constrained headroom, and
  retaining it with ample headroom. The generic Simulator app build passed.
  The initial test-target compilation emitted Apple's StoreKitTest
  `SKPaymentTransactionState` deprecation; Xcode also logged non-failing
  debugger-version lookup notices.
- Signed development build 1.0.1 (32) passed signature verification and was
  installed over build 31 on the paired iPhone and iPad without uninstalling
  or running cleanup. The first iPad install lost its CoreDevice connection;
  a query showed build 31 remained, and the retry succeeded. Independent
  queries then confirmed build 32 on both devices. Both launch commands
  succeeded, and process queries found FrameWink running on both. These
  checks do not measure real album cache hits, storage savings, iCloud refetch,
  or iOS 15 behavior, and do not establish TestFlight/App Store readiness.

Commands run from `/Users/yihong/work/FrameWink`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project FrameWink.xcodeproj -scheme FrameWink -showdestinations
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun simctl list devices available
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/FrameWink-AdaptiveCache-DerivedData CODE_SIGNING_ALLOWED=NO build
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' -derivedDataPath /private/tmp/FrameWink-AdaptiveCache-DerivedData -resultBundlePath /private/tmp/FrameWink-AdaptiveCache-iPhone.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/LocalStorageUsageTests -only-testing:FrameWinkTests/LocalAlbumSourceStoreTests -only-testing:FrameWinkTests/AlbumSyncServiceTests -only-testing:FrameWinkTests/AutomaticAlbumControllerTests -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testSafeCleanupShowsProgressAndKeepsPersonalSelection test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-AdaptiveCache-DerivedData -resultBundlePath /private/tmp/FrameWink-AdaptiveCache-iPad.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/LocalStorageUsageTests -only-testing:FrameWinkTests/LocalAlbumSourceStoreTests -only-testing:FrameWinkTests/AlbumSyncServiceTests -only-testing:FrameWinkTests/AutomaticAlbumControllerTests -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testSafeCleanupShowsProgressAndKeepsPersonalSelection test-without-building
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-AdaptiveCache-iPhone.xcresult
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-AdaptiveCache-iPad.xcresult
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS,id=00008150-00080C3C3C07801C' -derivedDataPath /private/tmp/FrameWink-AdaptiveCache-Physical-iPhone-32 CURRENT_PROJECT_VERSION=32 build
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS,id=00008027-000C25D036EB002E' -derivedDataPath /private/tmp/FrameWink-AdaptiveCache-Physical-iPad-32 CURRENT_PROJECT_VERSION=32 build
codesign --verify --deep --strict --verbose=2 /private/tmp/FrameWink-AdaptiveCache-Physical-iPhone-32/Build/Products/Debug-iphoneos/FrameWink.app
codesign --verify --deep --strict --verbose=2 /private/tmp/FrameWink-AdaptiveCache-Physical-iPad-32/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device install app --device 00008150-00080C3C3C07801C /private/tmp/FrameWink-AdaptiveCache-Physical-iPhone-32/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device install app --device 00008027-000C25D036EB002E --timeout 180 /private/tmp/FrameWink-AdaptiveCache-Physical-iPad-32/Build/Products/Debug-iphoneos/FrameWink.app
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008150-00080C3C3C07801C --bundle-id media.jenny.FrameWink --columns '*'
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info apps --device 00008027-000C25D036EB002E --bundle-id media.jenny.FrameWink --columns '*'
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device process launch --device 00008150-00080C3C3C07801C --terminate-existing media.jenny.FrameWink
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device process launch --device 00008027-000C25D036EB002E --terminate-existing media.jenny.FrameWink
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info processes --device 00008150-00080C3C3C07801C --search FrameWink
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl device info processes --device 00008027-000C25D036EB002E --search FrameWink
git diff --check
```

## Version 1.1 release preparation — 2026-09-18

- The app's Release build reports `CFBundleShortVersionString` 1.1. The unsigned
  generic iOS Release build, Release Analyze action, and archive release guard
  passed. The guard retained the production bundle ID, team, iPhone/iPad-only
  platform scope, iOS 15 minimum, privacy files, and lifetime product ID.
- The website's nine source tests, ESLint, TypeScript, and production Next.js
  build passed after its privacy and support pages were aligned with the 1.1
  cleanup actions. An initial local Next build failed because a temporary
  dependency symlink pointed outside Turbopack's project root; copying the
  existing dependencies into this disposable worktree made the production
  build pass. No dependency versions changed.
- The complete shared scheme on iPhone 17 Pro Max, iOS 27.0 Simulator, passed
  **229 tests, 5 expected skips, 0 failures**. Four skips require a physical
  PhotoKit library; the fifth is an iPad-only website screenshot. The result
  bundle records one UIKit hosting warning and three purchase-update warnings
  from `StoreKitConfigurationTests`. Xcode's extra Simulator diagnostic
  collection timed out after 600 seconds, but `xcodebuild` exited zero and the
  final test summary reports `Passed`.
- The complete shared scheme on iPad (A16), iOS 27.0 Simulator, passed
  **230 tests, 4 expected skips, 0 failures**. All four skips require a
  physical PhotoKit library. The same UIKit hosting and StoreKit test-harness
  runtime warnings appear. Xcode again timed out after 600 seconds while
  collecting extra Simulator diagnostics after testing; `xcodebuild` exited
  zero and the final test summary reports `Passed`.
- App Store Connect, inspected through Chrome, has a saved editable iOS 1.1
  draft with a four-item What's New bullet list, updated App Review notes,
  accurate cleanup description, manual release, and no build attached. The
  privacy answer remains `Data Not Collected`, the production privacy URL is
  `https://frame.jenny.media/privacy`, and FrameWink Lifetime remains an
  approved non-consumable. Xcode Cloud shows 0 available minutes until its
  September 18, 8:51 PM Eastern reset. No 1.1 archive, TestFlight install,
  or review submission has occurred.

Commands run from `/private/tmp/framewink-storage-pr`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project FrameWink.xcodeproj -scheme FrameWink -showdestinations
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer CI_XCODEBUILD_ACTION=archive ci_scripts/ci_pre_xcodebuild.sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FrameWink-Release11-DerivedData CODE_SIGNING_ALLOWED=NO build
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FrameWink-Release11-DerivedData CODE_SIGNING_ALLOWED=NO analyze
plutil -extract CFBundleShortVersionString raw -o - /private/tmp/FrameWink-Release11-DerivedData/Build/Products/Release-iphoneos/FrameWink.app/Info.plist
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' -derivedDataPath /private/tmp/FrameWink-Release11-Tests -resultBundlePath /private/tmp/FrameWink-Release11-iPhone.xcresult CODE_SIGNING_ALLOWED=NO test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-Release11-Tests -resultBundlePath /private/tmp/FrameWink-Release11-iPad.xcresult CODE_SIGNING_ALLOWED=NO test-without-building
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-Release11-iPhone.xcresult
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-Release11-iPad.xcresult
node --test website/tests/site.test.mjs
npm --prefix website run lint
npm --prefix website run build
git diff --check
```

### Album temporary-file protection before merge — 2026-09-18

- Metadata orphan cleanup previously treated an in-progress `.partial-` album
  download as an unreferenced image. It now preserves partials while a sync or
  image restore may be writing them. Startup and manual maintenance remove
  album partials older than 24 hours. The tests confirm both preservation of
  recent partials and removal of old partials while keeping cached photos.
- `LocalAlbumSourceStoreTests` and `LocalStorageUsageTests` passed **13/13** on
  iPhone 17 Pro Max and **13/13** on iPad (A16), iOS 27.0 Simulators. Both result
  bundles report zero failures, skips, and runtime warnings. The iPad
  `build-for-testing`, Release Analyze, and `git diff --check` also pass after
  this change. The earlier full-scheme runs precede this focused fix.

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' -derivedDataPath /private/tmp/FrameWink-Release11-Tests -resultBundlePath /private/tmp/FrameWink-Release11-PartialRace-iPhone.xcresult -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/LocalAlbumSourceStoreTests -only-testing:FrameWinkTests/LocalStorageUsageTests test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-Release11-Tests -resultBundlePath /private/tmp/FrameWink-Release11-PartialRace-iPad.xcresult -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/LocalAlbumSourceStoreTests -only-testing:FrameWinkTests/LocalStorageUsageTests test-without-building
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-Release11-Tests CODE_SIGNING_ALLOWED=NO build-for-testing
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FrameWink-Release11-DerivedData CODE_SIGNING_ALLOWED=NO analyze
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-Release11-PartialRace-iPhone.xcresult
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-Release11-PartialRace-iPad.xcresult
git diff --check
```

## Album status stability and iPad PPO screenshots — 2026-09-21

- The full `AutomaticAlbumControllerTests` suite passed **29/29** on iPhone 17
  Pro Max and **29/29** on iPad (A16) Simulators, with no failures, skips, or
  runtime warnings. The new checks assert that 10- and 30-photo reels are
  playable while the synchronizer remains active, and that the published phase
  stays `syncing` instead of flashing `ready`.
- `scripts/capture_app_store_landscape_screenshots.sh` passed for the 13-inch
  iPad and iPhone landscape Simulators. The iPad run captured ten scenes and
  the iPhone run captured three. The replacement storage scene uses bundled
  project photos and shows both cleanup actions.
- The dedicated normalized storage capture passed on the 13-inch iPad Pro (M5)
  Simulator. Its XCUITest scrolls the Privacy & Data sheet and requires both
  `Free Up Unused Space` and `Delete All FrameWink Photos` to be hittable before
  saving the screenshot.
- Image generation completed locally. All ten final PPO images are JPEGs at
  2752 x 2064 with no alpha, and the generator rejected any other dimensions or
  count. Visual inspection covered the contact sheet, both lifestyle scenes,
  and the storage card. Xcode emitted the existing StoreKitTest deprecation and
  non-failing debugger-version lookup notices.

Commands run from `/private/tmp/framewink-app-store-screenshots`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun simctl list devices available
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' -derivedDataPath /private/tmp/FrameWink-AlbumStatus-iPhone -resultBundlePath /private/tmp/FrameWink-AlbumStatus-iPhone.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/AutomaticAlbumControllerTests/testInitialCheckpointAllowsPlaybackBeforeFullSyncFinishes -only-testing:FrameWinkTests/AutomaticAlbumControllerTests/testThirtyPhotoCheckpointRefinesPlayableReelBeforeFullSyncFinishes test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-AlbumStatus-iPad -resultBundlePath /private/tmp/FrameWink-AlbumStatus-iPad.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/AutomaticAlbumControllerTests/testInitialCheckpointAllowsPlaybackBeforeFullSyncFinishes -only-testing:FrameWinkTests/AutomaticAlbumControllerTests/testThirtyPhotoCheckpointRefinesPlayableReelBeforeFullSyncFinishes test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE' -derivedDataPath /private/tmp/FrameWink-AlbumStatus-Final-iPhone -resultBundlePath /private/tmp/FrameWink-AlbumStatus-Final-iPhone.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/AutomaticAlbumControllerTests test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=B3A8D8D4-D576-4245-A0EC-ED914C0C744F' -derivedDataPath /private/tmp/FrameWink-AlbumStatus-Final-iPad -resultBundlePath /private/tmp/FrameWink-AlbumStatus-Final-iPad.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:FrameWinkTests/AutomaticAlbumControllerTests test
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-AlbumStatus-Final-iPhone.xcresult
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /private/tmp/FrameWink-AlbumStatus-Final-iPad.xcresult
FRAMEWINK_IPAD_LANDSCAPE_SIMULATOR_ID=1BDA7ABF-4236-406E-8ACD-7E3B10569753 FRAMEWINK_IPHONE_LANDSCAPE_SIMULATOR_ID=B41C6094-A3CA-48E6-AA25-1E08D0B98BCE scripts/capture_app_store_landscape_screenshots.sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -quiet -project FrameWink.xcodeproj -scheme FrameWink -configuration Debug -destination 'platform=iOS Simulator,id=1BDA7ABF-4236-406E-8ACD-7E3B10569753' -derivedDataPath /private/tmp/FrameWink-PPO-Capture -resultBundlePath /private/tmp/FrameWink-PPO-Storage.xcresult -only-testing:FrameWinkUITests/MarketingLandscapeScreenshotTests/testCaptureStorageMarketingScreen test
scripts/generate_landscape_marketing_assets.sh
scripts/generate_app_store_ipad_ppo_screenshots.sh
git diff --check
```

## Paused-frame stability — 2026-09-21

- `FrameSessionControllerTests` and `AutomaticAlbumControllerTests` passed
  **47/47** on iPad (A16) and **47/47** on iPhone 17 Pro Max, iOS 27.0
  Simulators. Both result bundles report zero failures, skips, and runtime
  warnings.
- The new pause regression applies successive provisional and final slide
  updates while playback is paused. The visible slide snapshot remains fixed
  until Resume applies the newest update.
- The new storage regression keeps the cache over budget across 10, 30, 60,
  and 90-photo checkpoints. Cache pruning continues at each checkpoint, while
  provisional curation runs only at 10 and 30 before the final 90-photo reel.
- A first iPad run caught a regression where a large first checkpoint protected
  only 30 images. The corrected implementation curates the complete checkpoint
  when that planned refinement is already over budget. The final runs below
  include that correction.

Commands run from `/private/tmp/framewink-app-store-screenshots`:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild test -quiet -project FrameWink.xcodeproj -scheme FrameWink -destination 'platform=iOS Simulator,name=iPad (A16),OS=27.0' -derivedDataPath /private/tmp/FrameWink-Pause-Fix -only-testing:FrameWinkTests/FrameSessionControllerTests -only-testing:FrameWinkTests/AutomaticAlbumControllerTests
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild test -quiet -project FrameWink.xcodeproj -scheme FrameWink -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=27.0' -derivedDataPath /private/tmp/FrameWink-Pause-Fix-iPhone -only-testing:FrameWinkTests/FrameSessionControllerTests -only-testing:FrameWinkTests/AutomaticAlbumControllerTests
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/FrameWink-Pause-Fix/Logs/Test/Test-FrameWink-2026.09.21_16-39-42--0400.xcresult
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/FrameWink-Pause-Fix-iPhone/Logs/Test/Test-FrameWink-2026.09.21_16-40-19--0400.xcresult
git diff --check
```

## Realistic-scale iPad screenshot treatment — 2026-09-21

- The deterministic generator produced six JPEG screenshots at exactly
  2752 x 2064 with no alpha and rejected any other count or dimensions.
- Multiple wall and tabletop integrations were generated from an empty room
  and the licensed official iPad bezel derivative. The selected wall result
  keeps the iPad visibly smaller than the nearby lamp shade; the selected table
  result has coherent perspective, contact shadows, and a supported stand.
- The generator replaces the model-interpreted display in both lifestyle
  scenes with the exact bundled Yellowstone Falls source before resizing and
  adding typography.
- Screenshots 3–6 reuse one close tabletop source and a fixed screen
  perspective transform. The album and review images retain their exact native
  modal while softening the surrounding setup screen; the smart-layout and
  privacy images use clean native full-screen displays. No storage, scheduling,
  purchase, or readable setup-detail screen appears in the treatment.
- Visual inspection covered all six images through the regenerated contact
  sheet. `git diff --check` passes.

Commands run from `/private/tmp/framewink-app-store-screenshots`:

```sh
/bin/bash -n scripts/generate_app_store_ipad_ppo_screenshots.sh
scripts/generate_app_store_ipad_ppo_screenshots.sh
git diff --check
```
