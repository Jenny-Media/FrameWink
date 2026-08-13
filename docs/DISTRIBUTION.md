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
2. Build and run the shared unit- and UI-test targets on an iPad Simulator.
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

### B-003 — No iPad Simulator is booted

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

- Status: Open
- First recorded: 2026-08-12
- Evidence: App Store Connect has the public policy URL and the audited answer
  `Data Not Collected` saved. Its final Publish dialog requires the publisher to
  attest that the responses are accurate, comply with App Review Guidelines and
  applicable law, and will be promptly updated if practices change.
- Impact: the prepared privacy response is not yet published on the future
  product page.
- Does not block: Xcode Cloud, TestFlight builds, support metadata, IAP setup,
  local validation, or repository work.
- Needed from owner: review the saved response and personally select Publish in
  App Store Connect if Jenny Media LLC accepts the attestation.

### B-010 — Xcode Cloud workflow needs an authenticated Xcode account

- Status: Open
- First recorded: 2026-08-12
- Evidence: the owner explicitly confirmed on 2026-08-12 that Apple/Xcode Cloud
  may access `Jenny-Media/FrameWink`. Xcode's first-workflow assistant matched
  FrameWink and Jenny Media LLC and selected that repository. GitHub owner
  authentication completed successfully, and App Store Connect now confirms
  `Xcode Cloud has been successfully connected` and `Xcode Cloud can now access
  your source code`. The GitHub App installation is restricted to `Only select
  repositories: Jenny-Media/FrameWink`. Xcode is now open at its Apple Account
  email-or-phone sign-in sheet. Apple documents adding an Apple Account to Xcode
  as a prerequisite for Xcode Cloud onboarding.
- Impact: the first Xcode Cloud workflow cannot be saved or run, and no cloud
  archive can reach TestFlight, until an authorized Jenny Media LLC team member
  finishes the open Xcode Apple Account login.
- Does not block: all App Store Connect/IAP metadata, local verification,
  physical-device discovery, or commits.
- Needed from owner: finish the open Apple Account authentication sheet in
  Xcode. Repository-scoped GitHub access is complete and must remain limited to
  `Jenny-Media/FrameWink`.

### B-011 — App Store declarations need owner completion

- Status: Open
- First recorded: 2026-08-12
- Evidence: mutable product-page metadata, screenshots, category, pricing, and
  availability are configured, but App Store Connect still requires the age
  rating questionnaire, content-rights declaration, and a real App Review
  contact record. The owner supplied the real App Review phone number on
  2026-08-12. The complete Yihong Chen contact record, using the monitored
  FrameWink support mailbox, is now saved in App Store Connect. The public
  repository intentionally does not reproduce the private contact number. The
  remaining content-rights and age-rating answers are publisher attestations
  that cannot be inferred safely from the source tree.
- Impact: version 1.0 cannot be submitted to App Review until the declarations
  and contact record are complete.
- Does not block: Xcode Cloud setup, internal TestFlight builds, local
  validation, or repository work.
- Needed from owner: complete the content-rights and age-rating declarations.

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
  synchronization processes a date-spanning 30-item batch first, commits a
  resumable metadata checkpoint every 30 items, and publishes an initial reel
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

- The `Jenny Media Internal` TestFlight group exists with no invited testers
  and no builds yet. App Store Connect notes that its automatic-distribution
  switch applies to uploaded Xcode builds but not Xcode Cloud builds, so the
  cloud archive workflow must explicitly distribute to the group after a
  successful build.
- TestFlight has `framewink@jenny.media` as its feedback address, the public
  GitHub repository as its marketing URL, and `PRIVACY.md` as its privacy URL.
  The complete App Review contact for Yihong Chen is saved with the same
  monitored FrameWink mailbox; its private phone number is not duplicated in
  this public repository.
- Jenny Media LLC's Paid Apps Agreement and Free Apps Agreement are active for
  all regions. Its configured bank account, U.S. W-9, and Digital Services Act
  compliance record are also active.
- The app is free in all 175 current regions and configured for all future
  regions; Wall Mode remains a separate $9.99 lifetime IAP. Apple Silicon Mac
  availability is disabled to preserve the iPad-only product contract.
- The English (U.S.) product page has a private-photo-frame subtitle,
  Photo & Video primary category, promotional text, description, keywords,
  marketing/support URLs, and all ten accepted 13-inch iPad screenshots in the
  documented Free-then-Paid order.

## Committed Xcode Cloud guardrail

Apple automatically runs `ci_scripts/ci_pre_xcodebuild.sh` before each Xcode
Cloud action. FrameWink's script validates its two privacy property lists and
Release identity for every action. For an archive, it additionally requires the
Jenny Media LLC team, `media.jenny.FrameWink`, and a nonempty non-local Wall Mode
product identifier. This makes B-006 fail closed at the cloud archive boundary
without preventing Build, Analyze, or Test workflows.

## Remaining release decisions

- Add real App Store Connect users to `Jenny Media Internal` when the owner is
  ready to send invitations. The first successful Xcode Cloud build must be
  explicitly assigned to this group.
- Complete the owner-only App Privacy attestation under B-009.
- Finish the open Jenny Media LLC Apple Account sign-in sheet in Xcode under
  B-010. Repository-scoped GitHub authorization is complete.
- Complete the publisher declarations and contact data under B-011.

## Local debugger tooling note

XcodeBuildMCP is configured for the correct project, scheme, bundle identifier,
and booted iPad, but its process currently inherits `/Library/Developer/CommandLineTools`
from global `xcode-select`; therefore its `simctl` and accessibility commands
cannot resolve the full Xcode installation. Direct commands scoped with
`DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer` continue to
build, test, install, launch, and capture FrameWink successfully. Changing the
machine-wide `xcode-select` setting is intentionally deferred to the owner.
