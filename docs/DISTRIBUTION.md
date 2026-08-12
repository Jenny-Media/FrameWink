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
  was installed and launched; the current shared scheme passes all 100 unit and
  UI tests.

### B-004 — Physical curation-validation hardware and labelled set are missing

- Status: Open
- First recorded: 2026-08-11
- Evidence: `devicectl` and `xctrace` list only simulated iPads. The paired
  physical devices are an Apple Vision Pro and an iPhone 17 Pro Max; neither is
  a valid destination for the iPad-only FrameWink target. No physical iPad or
  licensed human-labelled evaluation set is available in this workspace. On
  2026-08-12 the unlocked `iPad Pro 13-inch (M5)` named by the owner was
  confirmed to be Simulator UDID
  `1BDA7ABF-4236-406E-8ACD-7E3B10569753`, not physical hardware. FrameWink was
  built, installed, launched, and visually verified there, but macOS USB,
  `devicectl`, and `xctrace` still found no physical iPad.
- Impact: public Vision enrichment, the 100-photo and 1,000/5,000-album
  time/memory gates, real PhotoKit authorization/Limited/iCloud/change behavior,
  thermal behavior, and the human-labelled 80% displayability gate cannot yet
  receive physical acceptance evidence.
- Does not block: deterministic curator implementation, Simulator analysis,
  fixture-driven duplicate/date/layout tests, review UI, persistence, Wall Mode,
  purchases, cloud-readiness work, or local checkpoint commits.
- Needed from owner: identify the oldest available supported iPad and provide
  or approve a small licensed, human-labelled evaluation-photo set.

### B-005 — Physical Wall Mode soak device is not assigned

- Status: Open
- First recorded: 2026-08-11
- Evidence: the connected-device inventory contains no physical iPad, and no
  mounted test location, charger/cable, or unattended-run record is assigned.
- Impact: actual Auto-Lock prevention/restoration, brightness appearance,
  Guided Access status changes, thermal/charging behavior, mount safety, and the
  seven-day unattended run cannot yet receive physical evidence.
- Does not block: schedule logic, visual overlays, state restoration, persisted
  configuration, safety guidance, purchases, Xcode Cloud readiness, or local
  commits.
- Needed from owner: assign a compatible iPad, safe charger/cable and mounting
  location, then record device/OS and authorize the seven-day physical run.

### B-006 — Production Wall Mode product decisions were unconfirmed

- Status: Resolved on 2026-08-12
- First recorded: 2026-08-11
- Resolution: the owner confirmed the immutable identifier
  `media.jenny.FrameWink.wallmode` and enabled Family Sharing. Release now uses
  that production identifier, and the Debug StoreKit product mirrors the
  Family Sharing policy.
- App Store Connect completion: the `Wall Mode Lifetime` non-consumable was
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
  copies with Strict Offline behavior, reduces repeats from local display
  history, adds Mosaic, and persists multiple album-aware frame configurations.
  The paywall and release copy now describe the included scope. The 100-test
  Simulator suite covers local synchronization, corrupt-cache cleanup, change
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

### B-010 — Xcode Cloud repository access awaits confirmation

- Status: Open
- First recorded: 2026-08-12
- Evidence: Xcode's first-workflow assistant matched FrameWink and Jenny Media
  LLC, then selected `Jenny-Media/FrameWink`. It is paused at `Connect…`, which
  will grant Apple ongoing access to the repository source and associated build
  metadata; Apple states that access can be revoked.
- Impact: the first Xcode Cloud workflow cannot be saved or run, and no cloud
  archive can reach TestFlight, until repository access is granted.
- Does not block: all App Store Connect/IAP metadata, local verification,
  physical-device discovery, or commits.
- Needed from owner: explicitly confirm the Xcode Cloud repository-access grant.

## Committed Xcode Cloud guardrail

Apple automatically runs `ci_scripts/ci_pre_xcodebuild.sh` before each Xcode
Cloud action. FrameWink's script validates its two privacy property lists and
Release identity for every action. For an archive, it additionally requires the
Jenny Media LLC team, `media.jenny.FrameWink`, and a nonempty non-local Wall Mode
product identifier. This makes B-006 fail closed at the cloud archive boundary
without preventing Build, Analyze, or Test workflows.

## Remaining release decisions

- Select the initial internal TestFlight tester group after the first cloud
  build exists.
- Complete the owner-only App Privacy attestation under B-009.
- Confirm the Xcode Cloud repository-access grant under B-010.

## Local debugger tooling note

XcodeBuildMCP is configured for the correct project, scheme, bundle identifier,
and booted iPad, but its process currently inherits `/Library/Developer/CommandLineTools`
from global `xcode-select`; therefore its `simctl` and accessibility commands
cannot resolve the full Xcode installation. Direct commands scoped with
`DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer` continue to
build, test, install, launch, and capture FrameWink successfully. Changing the
machine-wide `xcode-select` setting is intentionally deferred to the owner.
