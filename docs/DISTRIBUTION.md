# Distribution and continuous delivery

## Confirmed identity

- Product: `FrameWink`
- App bundle identifier: `media.jenny.FrameWink`
- Unit-test bundle identifier: `media.jenny.FrameWinkTests`
- UI-test bundle identifier: `media.jenny.FrameWinkUITests`
- Apple Developer team: Jenny Media LLC (`5736QK4NZX`)
- Signing style: automatic

## Intended delivery path

Xcode Cloud is the authoritative release builder. Local builds are for fast
development feedback; the project does not depend on a local archive-and-upload
procedure.

The first cloud workflow should:

1. Start on updates to the release branch and allow manual runs.
2. Build and run the shared unit- and UI-test targets on iPhone and iPad
   Simulators.
3. Analyze the app target.
4. Perform a clean archive for distribution.
5. Use a TestFlight post-action to distribute successful builds to Jenny Media
   LLC internal testers.

A faster validation workflow may later run build and test actions on pull
requests without archiving.

Apple requires the first Xcode Cloud workflow to be configured from Xcode. The
project must be in an accessible Git repository, Xcode Cloud must be granted
access to it, and FrameWink needs an App Store Connect app record. The account
configuring the record needs the appropriate App Manager, Admin, Account
Holder, or delegated Create Apps permission.

## Blocker log

Record blockers when discovered, but continue independent work whenever the
blocker affects only a later boundary.

### B-001 — Hosted Git remote is missing

- Status: Resolved on 2026-08-12
- First recorded: 2026-08-11
- Resolution: the audited repository was created as the public
  `Jenny-Media/FrameWink` GitHub repository. `main` is the default branch,
  `origin` tracks `https://github.com/Jenny-Media/FrameWink.git`, Issues are
  enabled, and the complete local history was pushed successfully.

### B-002 — App Store Connect readiness is unverified

- Status: Resolved on 2026-08-12
- First recorded: 2026-08-11
- Resolution: App Store Connect was verified under Jenny Media LLC. The explicit
  App ID `media.jenny.FrameWink` was registered with In-App Purchase support,
  and the FrameWink iOS 1.0 record was created with full team access. Its App
  Store Connect Apple ID is `6800849400` and internal SKU is
  `media.jenny.FrameWink`.

### B-003 — No iPad Simulator was booted

- Status: Resolved on 2026-08-11
- First recorded: 2026-08-11
- Impact: the compiled unit tests and launch/UI flow have not yet executed.
- Does not block: generic Simulator builds, build-for-testing, implementation,
  or documentation.
- Resolution: the installed iOS 27 `iPad (A16)` Simulator was booted. FrameWink
  was installed and launched. Later verification counts are recorded in
  `docs/TESTING.md`; the real-PhotoKit UI test remains physical-only and skips
  on Simulator.

### B-004 — Physical curation validation is incomplete

- Status: Open
- First recorded: 2026-08-11
- Evidence: on 2026-08-12 a wired, paired physical iPad Pro 12.9-inch (3rd
  generation), iPadOS 26.6, became available with Developer Mode enabled.
  FrameWink built and signed for Jenny Media LLC, installed as
  `media.jenny.FrameWink`, launched, remained live, and rendered bundled sample
  photos. On-device tests passed all 98 unit tests and all 3 UI tests. The
  100-image Vision analysis completed in 12.140 seconds with no reported peak
  growth, and the 5,000-candidate curator benchmark completed in 1.363 seconds.
  The local StoreKit configuration also passed on-device purchase, restore, pending,
  failure, and refund-state tests after the Family Sharing expectation was
  aligned with the production product and entitlement checks were made tolerant
  of StoreKit's asynchronous propagation. No licensed human-labelled evaluation
  set is available yet.
- Impact: real PhotoKit authorization/Limited/iCloud/change behavior,
  oldest-supported-device coverage, TestFlight sandbox transactions, and the
  human-labelled 80% displayability gate do not yet have physical acceptance
  evidence.
- Does not block: deterministic curator implementation, Simulator analysis,
  fixture-driven duplicate/date/layout tests, review UI, persistence, Wall Mode,
  purchases, cloud-readiness work, or local checkpoint commits.
- Automation ready: `scripts/physical_acceptance.sh prepare` launches an
  explicitly test-only FrameWink Lifetime entitlement with the real PhotoKit client;
  `sample` records device/app evidence. Owner actions and acceptance criteria
  are in `docs/PHYSICAL_ACCEPTANCE.md`.
- Harness execution: the first automated `prepare` run on 2026-08-12 built and
  installed successfully, but iPadOS rejected foreground launch while locked.
  After the owner unlocked the device, `prepare` launched successfully and the
  monitor verified a live process plus the real setup experience with no Photos
  prompt before the explicit album action. The baseline heartbeat reported the
  app active, nominal thermal state, 95% battery while charging, idle-timer
  ownership off outside Frame Mode, and Guided Access off. The remaining
  permission scope and album choice are intentionally tester-owned.
- Latest local-unlock run: on 2026-08-13, the Debug physical-acceptance harness
  built, installed, and launched on both the paired iPad Pro and iPad mini 6.
  Xcode 27's paired Wi-Fi devices require a reachability probe instead of a
  literal `connection.state == connected` check; both probes and post-launch
  health samples passed with live processes and nominal thermal state.
- Latest refinement install: the automatic-presentation/literal-timing build
  signed and installed over existing data on both iPads. Both devices were
  locked, so iPadOS refused the foreground launch after the successful install.
  Unlocking and opening the already-installed app remains the only incomplete
  step from that run and does not block Simulator, Release, or cloud preflight.
- Native-control refinement install: on 2026-08-14 the exact 172-test source
  signed and installed over existing data on the paired iPad Pro. Its locked
  screen refused only the foreground launch. The paired iPad mini 6 was listed
  but not reachable, so discovery stopped before its build/install stage. Wake
  and unlock each device, then rerun its scoped `prepare` command; these device-
  state boundaries do not affect the green Simulator, Release, analysis, or
  archive-guard evidence.
- Needed from owner: provide or approve a small licensed, human-labelled
  evaluation-photo set and exercise real Photos authorization, iCloud/Limited
  behavior, and sandbox purchase/restore on the connected iPad.

### B-005 — Physical Wall Mode soak is not assigned

- Status: Open
- First recorded: 2026-08-11
- Evidence: the physical iPad Pro is now available and passes installation,
  launch, rotation, local-frame persistence, and UI smoke tests. No mounted test
  location, charger/cable, or unattended-run record is assigned.
- Impact: actual Auto-Lock prevention/restoration, brightness appearance,
  Guided Access status changes, thermal/charging behavior, mount safety, and the
  seven-day unattended run cannot yet receive physical evidence.
- Does not block: schedule logic, visual overlays, state restoration, persisted
  configuration, safety guidance, purchases, Xcode Cloud readiness, or local
  commits.
- Automation ready: `scripts/physical_acceptance.sh soak 168 300` records
  reachability, process presence, lock state, screenshots, and the app's
  photo-free idle-timer/Guided Access/thermal/battery heartbeat. It cannot
  certify the charger, mount, battery condition, or perceived display behavior.
- Needed from owner: assign a safe charger/cable and mounting location, then
  authorize the seven-day physical run on the connected iPad.

### B-006 — Production Wall Mode product decisions were unconfirmed

- Status: Resolved on 2026-08-12
- First recorded: 2026-08-11
- Resolution: the owner confirmed the immutable identifier
  `media.jenny.FrameWink.wallmode` and enabled Family Sharing. Release now uses
  that production identifier, and the Debug StoreKit product mirrors the
  Family Sharing policy.
- App Store Connect completion: the lifetime non-consumable was
  created as Apple ID `6800849862`, Family Sharing was permanently enabled,
  the U.S. base price is $9.99 with Apple's comparable storefront prices, all
  175 current storefronts plus future storefronts are selected, and English
  (U.S.) localization is configured.

### B-007 — Public support and privacy-policy endpoints are missing

- Status: Resolved on 2026-08-12
- First recorded: 2026-08-12
- Resolution: the public policy is available at
  `https://github.com/Jenny-Media/FrameWink/blob/main/PRIVACY.md`; support uses
  `https://github.com/Jenny-Media/FrameWink/issues` and
  `framewink@jenny.media`. The policy and support URLs are saved in App Store
  Connect version/privacy metadata.

### B-008 — TestFlight paid scope did not match the product contract

- Status: Resolved on 2026-08-12
- First recorded: 2026-08-12
- Evidence: `AGENTS.md`, `docs/PRODUCT.md`, and decision D-005 define paid Wall
  Mode as including automatic album freshness, scale, and multiple saved
  configurations. The earlier build labelled those capabilities as planned.
- Resolution: the paid implementation now requests PhotoKit authorization only
  from the explicit album action, reads and observes a selected album without
  mutation, curates its full eligible candidate pool, caches display-sized
  copies with normal iCloud-capable behavior, reduces repeats from local display
  history, adds Mosaic, and persists multiple album-aware frame configurations.
  The paywall and release copy now describe the included scope. The Simulator
  suite covers local synchronization, corrupt-cache cleanup, change
  refresh, entitlement/revocation, unbounded input, repeat ranking, layouts, and
  saved configurations.
- Remaining boundary: real PhotoKit permission, iCloud, large-album, and change-
  notification behavior still require physical-device evidence under B-004.

### B-009 — App Privacy publication needs owner legal attestation

- Status: Resolved on 2026-08-14
- First recorded: 2026-08-12
- Resolution: after the owner confirmed the prepared release actions, App Store
  Connect published the audited `Data Not Collected` response with the public
  privacy-policy URL. The live page identifies Yihong Chen as the publisher.

### B-010 — Xcode Cloud archive and TestFlight distribution

- Status: Resolved on 2026-08-14
- First recorded: 2026-08-12
- Evidence: the owner explicitly confirmed on 2026-08-12 that Apple/Xcode Cloud
  may access `Jenny-Media/FrameWink`. Xcode's first-workflow assistant matched
  FrameWink and Jenny Media LLC and selected that repository. GitHub owner
  authentication completed successfully, and App Store Connect now confirms
  `Xcode Cloud has been successfully connected` and `Xcode Cloud can now access
  your source code`. The GitHub App installation is restricted to `Only select
  repositories: Jenny-Media/FrameWink`. On 2026-08-14 Xcode was signed back in,
  the first workflow was created, and Build 1 succeeded against commit
  `b8691b9` using Xcode 26.6 and macOS 26.6.2. A transient App Store Connect
  `no shared schemes` message appeared while that first build was still being
  indexed; the completed build discovered the committed shared `FrameWink`
  scheme and made additional workflow creation available. `Validation` now
  analyzes and tests `main` on recommended iPhone and iPad destinations.
  `Internal TestFlight` is manual-only and performs a clean archive with App
  Store Connect preparation and a post-action assigned
  specifically to `Jenny Media Internal`. Build 3 then failed closed before
  compilation because Xcode Cloud 26.6 supplied `CI_TEAM_ID` as Jenny Media
  LLC's App Store Connect team UUID rather than the 10-character Apple
  Developer team ID documented for that variable. The project's resolved
  `DEVELOPMENT_TEAM` remained the expected `5736QK4NZX`; the guard now accepts
  either verified Jenny Media representation and still rejects every unrelated
  value. Validation Build 2 also showed that Xcode Cloud reruns the pre-build
  script inside each distributed `test-without-building` simulator worker after
  restoring test artifacts, without cloning the repository into those workers.
  The full guard had already passed during `build-for-testing`; the script now
  exits successfully only for that exact artifact-only phase when the project
  is absent. Source, analyze, build-for-testing, and archive phases retain the
  complete fail-closed checks.
- Resolution: `Internal TestFlight` Build 6 at commit `6f59253` completed its
  clean archive and internal-distribution post-action. App Store Connect shows
  FrameWink 1.0 (6) as `Ready to Test` in `Jenny Media Internal`.
- Impact: none on archive-to-TestFlight delivery. Validation Build 5 separately
  exposed hosted StoreKit resource/startup ordering and compact-height UI-test
  issues; both are fixed and pass artifact-only local reproduction.
- Does not block: all App Store Connect/IAP metadata, local verification,
  physical-device discovery, or commits.
- Validation Build 7 confirmed the compact-height UI repair and all
  non-StoreKit suites, but Apple's iOS 26.5 artifact workers still returned no
  StoreKit products. The test bundle now validates the catalog contract on
  every runner and explicitly skips only the four runtime transaction checks
  when an identified Xcode Cloud worker lacks that product. The same runtime
  checks remain mandatory and pass locally on both device families.
- Validation Build 9 then hit an unrelated Apple simulator failure: the iPad
  (10th generation) worker's busy SpringBoard denied all 17 UI test launches
  before test code ran. The identical clean retry, Build 10 at `d6d7026`,
  succeeded in Analyze and Test across all eight destinations with 174 passed,
  eight explicit skips, and zero failures out of 182. This closes the Xcode
  Cloud validation action without weakening local StoreKit runtime coverage.

### B-011 — App Store declarations and review package

- Status: Resolved on 2026-08-14
- First recorded: 2026-08-12
- Evidence: after owner confirmation on 2026-08-14, the universal subtitle,
  current promotional text, description, keywords, content-rights answer,
  all-No/None age-rating questionnaire, and App Review contact were saved.
  App Store Connect calculated a 4+ global rating. Both storefront galleries
  now contain the current ordered ten-shot sets: 6.9-inch iPhone and 13-inch
  iPad. The public repository intentionally does not reproduce the private
  review phone number.
- Resolution: Build 8 at commit `037c4ab` succeeded with App Store Connect
  preparation and its TestFlight post-action. App Store Connect accepted Build
  8 for version 1.0. The two-item package containing iOS 1.0 (8) and FrameWink
  Lifetime was subsequently submitted, and version 1.0 reports `Waiting for
  Review` with manual release enabled.
- Impact: none on submission readiness. Build 6 remains internal-only by
  design and is not the customer release candidate.
- Does not block: Xcode Cloud setup, internal TestFlight builds, local
  validation, or repository work.
- Next action: monitor App Review, finish the EU trader verification, and keep
  the manual release gate closed until the remaining owner checks pass.

### B-012 — Physical PhotoKit album picker stalled after authorization

- Status: Resolved on 2026-08-12
- First recorded: 2026-08-12
- Evidence: after the owner chose **Choose Album** and granted Full Photos
  access on the connected iPad, the **Choose Automatic Album** sheet remained
  on **Loading albums…** for more than ten seconds. An automated sample
  confirmed that FrameWink was still running with an active heartbeat, nominal
  thermal state, and no crash.
- Cause found in code: album discovery synchronously performed a full filtered
  asset fetch for every supported album on the main UI actor. The selected
  album's full asset index used the same actor. The picker also displayed its
  loading state for empty and failed results, making a recoverable failure look
  like a permanent hang.
- Resolution: album and asset discovery now run outside the UI
  actor; album rows use PhotoKit's inexpensive estimated item count instead of
  pre-scanning every album; and the sheet has explicit error, retry, and empty
  states. The replacement build was installed on the same authorized physical
  iPad, and the physical-only UI regression launched the real PhotoKit harness,
  tapped **Choose Album**, and verified that the album list replaced the
  loading state within its ten-second gate. The check is repeatable with
  `scripts/physical_acceptance.sh verify-albums` and intentionally skips on
  Simulator.
- Remaining boundary: choosing a licensed test album and validating its full
  synchronization, curation, iCloud, and change-notification behavior remain
  tracked under B-004.

### B-013 — Physical UI verification left the iPad in automation state

- Status: Resolved on 2026-08-12
- First recorded: 2026-08-12
- Evidence: after the physical-only album regression completed, iPadOS still
  showed its automation indicator and then returned to App Library, leaving the
  owner without FrameWink controls. No FrameWink or XCTest runner process
  remained; a host screenshot confirmed App Library rather than an app crash.
- Resolution: `scripts/physical_acceptance.sh verify-albums` now preserves the
  XCTest result, always relaunches the interactive Debug physical-acceptance
  harness, and only then reports pass or failure. An end-to-end rerun passed
  album discovery and finished with one live FrameWink process on the visible
  simplified FrameWink home screen.

### B-014 — Cloud-only album items were reported as generic failures

- Status: Superseded by the simplified iCloud behavior; full device retest is
  tracked by B-015
- First recorded: 2026-08-12
- Evidence: repeated physical album trials appeared to produce only one
  selected photo. Count-only private metadata and the visible setup status
  confirmed that the current 326-image album prepared one local item while 325
  exports failed with Strict Offline enabled.
- Cause found in code: PhotoKit's `networkAccessRequired` error was propagated
  before FrameWink classified the request as an iCloud-only skip. The UI
  therefore gave a generic failure count, and changing Strict Offline did not
  automatically refresh the album.
- Resolution implemented: PhotoKit network-required responses are classified
  correctly. The subsequent UX refinement removed the user-facing Strict
  Offline mode and lets Apple Photos fetch needed iCloud originals by default.
- Physical retest: the replacement build reran the same 326-image album with
  Strict Offline and now reports that 325 photos need an iCloud download,
  retains the one local selection, and presents the recovery button. It no
  longer labels these items as unexplained preparation failures.
- Owner authorization: the owner approved the refinement and iCloud-backed
  preparation. The remaining refresh-loop observation is separated below.

### B-015 — iCloud downloads restarted active album preparation

- Status: Resolved on 2026-08-12
- First recorded: 2026-08-12
- Evidence: after the approved iCloud preparation reached 13 of 326 photos, a
  later physical sample showed 0 of 0. The existing cached photo remained
  visible, but the new preparation had restarted.
- Cause: each Apple Photos iCloud download can emit a PhotoKit library-change
  notification. The automatic-refresh debounce called `refresh()` even while
  the same album synchronization was active, cancelling useful progress.
- Resolution implemented: the controller now tracks active preparation and
  ignores change-driven refresh requests until it is idle. A regression test
  proves a change event cannot restart active synchronization and that a later
  genuine library change still refreshes normally.
- Physical resolution evidence: the corrected build prepared the same album
  monotonically through 84, 138, 167, 198, and 230 of 326 without resetting,
  then completed. The app stayed active with nominal thermal state while the
  iPad charged. All 326 private display copies and records were present at the
  commit point.

### B-017 — Vision duplicate scaling collapsed a real album to two photos

- Status: Resolved on 2026-08-12
- First recorded: 2026-08-12
- Evidence: the completed 326-photo physical run initially showed only two
  ready photos. Inspection of FrameWink's private metadata found 326 durable
  records, 326 distinct creation timestamps, no hidden items or screenshots,
  and every analyzed photo above the hard displayability thresholds.
- Cause: `VNFeaturePrintObservation.computeDistance` was divided by an assumed
  maximum of 40. That pushed ordinary distances around 0.3–1.3 below the
  curator's 0.12 near-duplicate cutoff and discarded almost the whole album.
- Resolution: Vision distances are now clamped to the shared 0...1 contract
  without rescaling, and curation revision 3 invalidates the bad cached result.
  A unit regression covers the normalization boundary. The corrected build was
  installed over the existing app data and reprocessed the same album to 86
  ready photos with **Start Frame** enabled. The physical process remained live,
  charging, and nominal-thermal.

### B-018 — First album preparation is slow and the ready preview appears stuck

- Status: Resolved on 2026-08-13
- First recorded: 2026-08-13
- Evidence: on the connected iPad Pro, a newly selected 160-item album was
  still preparing at 116 items and took several minutes to become usable. It
  ultimately produced 69 recommendations, but horizontal swipes on the ready
  home preview did nothing until **Start Frame** was tapped. The connected iPad
  mini 6 remained on the preparation screen longer still. Both processes stayed
  live at nominal thermal state, so this is latency and interaction feedback,
  not a crash or one-photo curation result.
- Cause found in code: the real PhotoKit path requests each full current image
  sequentially and only then downsamples it to the 2,560-pixel display cache.
  The home slideshow also installs its swipe gesture only after Frame Mode
  starts, even though a ready photo is already visible behind the setup card.
- Does not block: cached-album playback, deterministic curation, Simulator
  verification, or release-document work.
- Resolution: PhotoKit now returns a high-quality 2,560-pixel representation
  instead of transferring the largest current image before downsampling. Album
  synchronization now processes a date-spanning 10-item batch first, refines
  at 30, commits resumable metadata checkpoints, and publishes the initial reel
  while the remaining album continues in the foreground. The preparation
  backdrop shows live transfer/analysis counts, the ready card keeps **Start
  Frame** enabled during refinement, and its visible preview accepts horizontal
  navigation before Frame Mode.
- Verification: the optimized physical build sustained roughly 5–7 prepared
  photos per second while the iPad Pro processed a 1,925-item album and the iPad
  mini 6 processed a 653-item album; both remained live at nominal thermal
  state. After relaunch, the Pro exposed a 30-photo playable reel within seconds
  while the complete 1,925-item analysis continued. Simulator coverage proves
  representative checkpoint ordering, durable resume records, early playback
  before final synchronization, and swipe navigation on the ready home preview.

### B-019 — Immediate provisional-reel playback can start with one-page state

- Status: Resolved on 2026-08-13
- First recorded: 2026-08-13
- Evidence: on the connected iPad Pro, the owner entered Frame Mode as soon as
  the progressive status reported 30 photos ready. The first photo displayed,
  but swipes and the previous/next controls initially did not change it.
  Count-only inspection found 30 unique reel selections, all 30 mapped to
  durable records, and three sampled selected cache files contained three
  distinct images. The process stayed live, charging, and nominal-thermal.
  A later host sample showed that the timer had advanced to another real photo.
- Cause: the responsive view had built 27 pages from the 30-photo provisional
  reel, but the playback session still held a zero-page count. Its stored layout
  signature already matched the view, so synchronization returned early without
  repairing the inconsistent count. Immediate Next/Previous/swipe actions were
  therefore no-ops until a later update recovered the session. A second narrow
  race left the old stable-photo anchor live until a later SwiftUI callback,
  allowing a simultaneous geometry reflow to restore the prior page.
- Resolution: synchronization now validates both the page-layout signature and
  session page count. Swipe, arrow, and timer paths reconcile the current pages
  before advancing, and manual advance plus stable-anchor/history update occur
  in one playback mutation. Arrow controls also expose the accessible position
  `Photo n of m`.
- Verification: a deterministic 30-page regression begins with a matching
  signature and zero-page session, then proves immediate Next/Previous/timer
  recovery and anchor preservation through reflow. The complete Simulator
  scheme passes 132 tests with two intentional physical-only skips, zero
  failures, and zero runtime warnings. On the connected iPad Pro, the existing
  fixture test passed Next, Previous, swipe, pause/resume, and rotation. A new
  physical-only test then launched the currently configured 30-photo real
  album: Next displayed its distinct second cached photo, and a following swipe
  displayed a page containing none of the preceding page's photos. The final
  unsigned Release build also succeeds.

### B-020 — Physical album-cover UI automation could not enter automation mode

- Status: Resolved by owner-observed physical testing on 2026-08-13
- First recorded: 2026-08-13
- Evidence: the new real-PhotoKit album-cover UI regression built and installed
  on the connected iPad Pro, but XCTest timed out while enabling iPadOS
  automation mode before the test body ran. Xcode then emitted the already
  documented host tool-path diagnostic while collecting failure artifacts.
- Resolution: the owner opened **Choose Album** on a physical iPad and confirmed
  that real covers appear progressively. They remain qualitatively slower than
  Apple's Photos app, so the implementation now also returns bounded cover
  candidates with album metadata, preheats the first visible/nearby set,
  requests measured screen-sized tiles, tries every eligible local candidate
  before cloud fallback, and exposes an explicit cloud-loading state.
- Remaining non-blocking check: preserve and retry the physical XCTest when
  iPadOS automation mode is stable; compare qualitative time-to-first-visible
  and scrolling behavior after installing this newer cover pipeline.

### B-021 — Physical album-cache timing automation could not enter automation mode

- Status: Open, non-blocking tooling issue
- First recorded: 2026-08-13
- Evidence: the album catalog/cache refinement built and installed on the
  connected iPad Pro. The three-test real-PhotoKit run included a new regression
  requiring the catalog and a visible cover to return within two seconds after
  closing and reopening the picker. iPadOS timed out while enabling XCTest
  automation before any test body ran, and the harness restored the interactive
  FrameWink app successfully.
- Latest retry: after separating fast collection metadata from lazy cover scans,
  the replacement build installed and launched on the same iPad Pro. The first
  album-grid assertion was tightened from ten seconds to three seconds; cover
  and reopen-cache checks remain separate. iPadOS again timed out enabling
  automation before the test body, so this run neither passed nor failed the
  app-level timing thresholds. A second retry after the final background
  preheat hardening failed at the same iPadOS automation-mode boundary after 65
  seconds; the interactive harness was restored again.
- Impact: the cache path is covered by controller and Simulator UI tests, but
  its two-second real-library target has not been measured automatically.
- Does not block: the implementation, Simulator verification, Release build,
  archive guard, or manual album-picker use.
- Needed from owner: in the installed build, open **Choose Album** and confirm
  the named album grid replaces **Loading albums…** within roughly three
  seconds even if covers are still filling in. Then close and reopen it once and
  confirm the existing grid and visible covers return immediately. Retry
  `scripts/physical_acceptance.sh verify-albums` when iPadOS automation mode is
  stable.

### B-022 — Lifetime purchase availability was not saved

- Status: Resolved in App Store Connect on 2026-08-13
- First recorded: 2026-08-13
- Evidence: App Store Connect contains the `FrameWink Lifetime` non-consumable
  with product identifier `media.jenny.FrameWink.wallmode`, Family Sharing
  enabled, and status **Prepare for Submission**. All current and future
  storefronts are selected in the availability editor, but that pending change
  has not been saved to App Store Connect.
- Device diagnosis: the first temporary iPhone compatibility install was a
  Debug build using the local StoreKit fixture identifier and therefore could
  not load a product when launched outside an Xcode StoreKit session.
- Resolution: with owner confirmation, the prepared availability change was
  saved in Jenny Media LLC's App Store Connect account. The product page now
  reports **Saved**, all 175 current countries or regions selected, Family
  Sharing enabled, and **Add for Review** available. Both physical iPads were
  relaunched so StoreKit can refresh the production product identifier.
- Code resolution on 2026-08-14: the universal target's directly launched
  Debug and Release builds now use the production identifier, while the
  isolated StoreKit Test fixture retains its `.local` identifier. Product
  loading is retryable from the paywall without an app restart. The first
  non-consumable must still be submitted with the first app version; use a
  sandbox tester or TestFlight for the actual transaction rather than a normal
  production Apple ID in a development build.
- Remaining device check: confirm Apple's sandbox returns the localized price,
  authorize a transaction, and cover restore/Family Sharing with sandbox
  accounts. This Apple account boundary cannot be bypassed by app code.
- Device-install evidence on 2026-08-14: the exact universal signed Debug build
  installed and launched on the paired iPhone 17 Pro Max, iOS 27, through
  `scripts/physical_acceptance.sh prepare-storekit`. The built binary contains
  the production product identifier and no test-entitlement environment. Price,
  purchase confirmation, restore, and Family Sharing remain human sandbox
  checks; installation and product configuration are no longer blockers.

### B-023 — Physical iPhone timer UI automation cannot enter automation mode

- Status: Open, non-blocking tooling issue
- First recorded: 2026-08-14
- Evidence: the signed temporary compatibility build installed and launched on
  the paired iPhone 17 Pro Max. Two narrow attempts to run the new one-tap
  duration regression both timed out while iOS was enabling XCTest Automation
  Mode, before the test method executed. Xcode then emitted its known internal
  `devicectl` path diagnostic while collecting failure artifacts.
- Independent evidence: the same rapid `10s` → `5m` → `1m` → `30s` → `10s`
  regression passes on both iPad and iPhone 17 Pro Max Simulators. A physical
  screenshot confirms the exact signed source launches and the compact caption
  no longer intersects the setup card. The full iPad suite, Release build,
  static analysis, and archive guard pass.
- Does not block: the universal release target, implementation, Simulator
  acceptance, signed physical installation, or manual owner testing.
- Needed from owner: in the installed iPhone build, start a frame, open More,
  and tap each duration once. Confirm the checkmark and blue selection move on
  every first tap. Retry the physical XCTest only when iOS Automation Mode is
  stable.

### B-024 — EU Digital Services Act trader verification

- Status: Open, Apple verification in progress
- First recorded: 2026-08-14
- Evidence: live App Information identifies Jenny Media LLC as a non-trader for
  FrameWink, while availability covers all 175 regions and the app offers a
  $9.99 lifetime IAP. Apple's current trader self-assessment guidance says that
  app revenue, business activity, and a legal status associated with business
  activity are factors that may indicate trader status. Apple explicitly says
  it cannot make the legal determination for the developer. See
  `https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements`.
- Impact: an inaccurate declaration would affect required EU consumer-facing
  disclosures. If Jenny Media LLC is a trader, Apple must verify and publish
  the required business address, phone, and email on EU App Store pages.
- Does not block: local release verification, GitHub, screenshots, Xcode Cloud,
  TestFlight, or distribution outside the EU.
- Owner decision: Jenny Media LLC should be identified as a trader. The live
  setup has advanced through trader selection and business-contact entry to
  Apple's email-code verification step. Email verification, any subsequent
  phone/document checks, and the final legally binding certification remain.
  The review package is already submitted with manual release enabled; do not
  release it while EU availability remains enabled until Apple accepts the
  verification and App Information reflects the trader disclosure.

### B-025 — Automatic website deployment needs GitHub App authorization

- Status: Open, non-blocking deployment automation
- First recorded: 2026-08-14
- Evidence: the Vercel project `framewink` exists with `website` as its root,
  but Vercel could not connect `Jenny-Media/FrameWink` through the GitHub App.
  The organization/repository grant is outside the repository and cannot be
  supplied by source code.
- Impact: pushes do not yet create automatic website deployments.
- Does not block: local validation, committing the website, direct production
  deployment with the authenticated Vercel CLI, assigning
  `frame.jenny.media`, or the iOS App Review package.
- Needed from owner: authorize the Vercel GitHub App for the
  `Jenny-Media/FrameWink` repository, reconnect it to the `framewink` project,
  and configure the project to ignore changes outside `website/`. Separately,
  add an Xcode Cloud Files and Folders condition that ignores website-only
  commits.

### B-016 — Simulator debugger integration cannot locate Xcode

- Status: Open, non-blocking tooling issue
- First recorded: 2026-08-12
- Evidence: the dedicated Simulator debugger integration reports that
  `xcodebuild` is missing from its PATH even though Xcode beta is installed.
- Workaround: builds, tests, Simulator launches, screenshots, and physical
  installs continue through repository scripts and explicit
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer` commands.
- Impact: none on the app binary or release path; only the debugger-specific
  convenience integration is unavailable.

## App Store Connect readiness snapshot

- The `Jenny Media Internal` TestFlight group has one invited Account Holder.
  Build 6
  (version 1.0) is `Ready to Test` after the manual `Internal TestFlight` cloud
  workflow completed its archive and post-action.
- TestFlight has `framewink@jenny.media` as its feedback address, the public
  GitHub repository as its marketing URL, and `PRIVACY.md` as its privacy URL.
  A final live-field audit found the App Review phone and email inputs empty;
  re-enter the owner-approved values before submission. The private phone
  number is not duplicated in this public repository.
- Jenny Media LLC's Paid Apps Agreement and Free Apps Agreement are active for
  all regions. Its configured bank account and U.S. W-9 are active. The trader
  selection is awaiting Apple's DSA contact verification; B-024 records the
  remaining verification and certification before EU submission.
- The app is free in all 175 current regions and configured for all future
  regions; FrameWink Lifetime is a separate $4.99 lifetime IAP whose all-region
  storefront availability is saved. Public Apple-silicon Mac and Apple Vision
  Pro availability are disabled because FrameWink supports iPhone and iPad
  only. Both corresponding platform-testing options are also `Not Available`
  in `Jenny Media Internal`.
- The English (U.S.) product page now uses `Private smart photo frame`, the
  current universal copy and keywords, Photo & Video primary category,
  marketing/support URLs, and the current ordered ten-shot iPhone and iPad
  galleries. App Privacy is published as `Data Not Collected`, content rights
  are confirmed, and App Store Connect calculated a 4+ rating. App
  Accessibility setup is optional and has not been started.
- The `FrameWink Lifetime` IAP has its required private review screenshot. The
  accepted 1242 × 2688 JPEG is retained in the repository; public promotional
  imagery remains unset by design. Version 1.0 has submission-capable Build 8
  selected in the same two-item review package. App Store Connect reports
  version 1.0 `Waiting for Review`, with manual release enabled.

## Committed Xcode Cloud guardrail

Apple automatically runs `ci_scripts/ci_pre_xcodebuild.sh` before each Xcode
Cloud action. FrameWink's script validates its two privacy property lists and
Release identity for every action. For an archive, it additionally requires the
Jenny Media LLC team, `media.jenny.FrameWink`, and a nonempty non-local Wall Mode
product identifier. This makes B-006 fail closed at the cloud archive boundary
without preventing Build, Analyze, or Test workflows.

## Remaining release decisions

- The Account Holder is now a tester in `Jenny Media Internal`; install and
  smoke-test Build 8 from TestFlight on a physical iPhone or iPad.
- Confirm the distributed-test repair in the automatic Validation workflow.
- Release mode is set to manual. The two-item iOS 1.0 (8) and FrameWink
  Lifetime package is submitted and `Waiting for Review`; do not withdraw or
  replace it without an explicit owner decision or an Apple-requested change.
- Finish Apple's EU trader contact verification and certification under B-024.
- After StoreKit metadata propagation, repeat product loading through a sandbox
  or TestFlight device build and submit the first lifetime IAP with the first
  app version.

## Local debugger tooling note

XcodeBuildMCP is configured for the correct project, scheme, bundle identifier,
and booted iPad, but its process currently inherits `/Library/Developer/CommandLineTools`
from global `xcode-select`; therefore its `simctl` and accessibility commands
cannot resolve the full Xcode installation. Direct commands scoped with
`DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer` continue to
build, test, install, launch, and capture FrameWink successfully. Changing the
machine-wide `xcode-select` setting is intentionally deferred to the owner.
