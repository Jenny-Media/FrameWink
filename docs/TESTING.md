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

Still required in App Store Connect: confirm/create the immutable production
product identifier, decide Family Sharing, configure pricing/localizations, and
exercise purchase/restore/refund in TestFlight sandbox under blocker B-006.

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
  `PrivacyInfo.xcprivacy`, no local `.storekit` file, and an intentionally empty
  Release Wall Mode product identifier.
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

- Full Simulator suite: 80 tests passed with zero failures, skips, expected
  failures, or runtime warnings on the iOS 27 `iPad (A16)` Simulator.
- The final unsigned generic-device Release build and Xcode static analysis
  both complete without diagnostics after the paid-scope changes.
- Three `AlbumSyncServiceTests` cover hidden/screenshot filtering, Strict
  Offline cloud-only behavior, stable-ID replacement, persisted burst metadata,
  and removal of cache files for deleted assets.
- Three `LocalAlbumSourceStoreTests` cover configuration/record persistence,
  orphan pruning, corrupt metadata recovery, and cache-only deletion.
- Three `AutomaticAlbumControllerTests` cover entitlement gating, explicit
  authorization, sync/curation, PhotoKit-change refresh, and revocation.
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

Recovery status for the current MVP:

| Scenario | Local evidence | Remaining check |
|---|---|---|
| Picker cancellation | Automated cleanup test | Repeat on physical iPad |
| Partial/cloud-provider failure | Successful items persist and failure is retryable | Exercise an iCloud-only selection offline/online |
| Permission denial / revocation | Controller falls back from automatic display and preserves free content | Exercise real prompt/settings transitions |
| Limited Photos | Limited status is treated as readable and album fetch stays scoped by PhotoKit | Verify selected-album visibility on physical iPad |
| Automatic album cloud-only/partial failure | Strict Offline skips cloud-only items; prior usable copies survive refresh failure | Exercise real iCloud residency online/offline |
| Deleted automatic-album asset | Sync prunes its metadata and only its app-controlled cache file | Verify real PhotoKit change notification |
| Imported file deleted outside the manifest | Manifest is pruned and repaired by test | None for app-owned files |
| Full disk / failed persistence | Transactional fakes preserve successful imports and surface retry | Trigger storage exhaustion on a disposable device |
| Corrupt disposable cache/reel | Invalid cache is discarded or rebuilt by test | None |
| Corrupt durable exclusions | Error remains visible rather than silently forgetting `Never Show Again` | Delete Imported Photos remains the destructive recovery |
| Memory pressure / thermal | Bounded thumbnails, eager decode, cancellation, thermal fallback | Physical memory warning, Instruments, and thermal run |

The local release packet now includes the App Privacy answer and policy draft,
App Review notes, a six-shot Free/Paid screenshot plan, localized TestFlight
tester notes, and exact Xcode Cloud workflow recipes. Stable support/privacy
URLs, actual screenshots, product setup, a hosted repository, the Xcode Cloud
workflow, and TestFlight installation remain external release work.

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
- Paid automatic albums prompt only after the explicit `Choose Automatic Album`
  action; denial does not affect Sample Mode or Free Smart Reel.
- `PHPhotoLibraryPreventAutomaticLimitedAccessAlert` prevents iOS from showing
  its own recurring Limited-access alert at launch.
- Strict Offline automatic albums request no network access. With it disabled,
  Apple Photos—not a FrameWink endpoint—may download an iCloud original.
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
- [ ] Privacy policy and support pages are published at stable HTTPS URLs.
- [x] Current raw screenshot drafts do not imply an ambient sensor, automatic
      Guided Access, reboot recovery, or another unavailable kiosk capability.
- [x] Compatibility copy says iPadOS 15+ rather than every old iPad.
- [x] Battery, heat, ventilation, and damaged-device guidance is present.
- [ ] Xcode Cloud clean archive and TestFlight installation succeed.

The executable `ci_scripts/ci_pre_xcodebuild.sh` is recognized automatically by
Xcode Cloud. Its validation path passes locally. Its archive path intentionally
fails while the production Wall Mode product identifier is empty, and also
guards the Jenny Media team, production bundle ID, iPad-only family, iPadOS 15
minimum, and both privacy property lists.
