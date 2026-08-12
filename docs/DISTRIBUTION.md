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

- Status: Open
- First recorded: 2026-08-11
- Evidence: `git remote -v` returns no remotes. GitHub CLI is authenticated as
  `xcv58` with `repo` and `workflow` access, but no `xcv58/FrameWink`
  repository exists and the account's visible organizations are unrelated to
  Jenny Media LLC.
- Impact: Xcode Cloud cannot clone or connect to the project.
- Does not block: local implementation, builds, tests, signing configuration,
  documentation, or commits.
- Needed from owner: choose the Git provider, repository owner/organization,
  visibility, name, and release branch, then authorize repository creation or
  provide its URL and authorize the initial push/Xcode Cloud access.

### B-002 — App Store Connect readiness is unverified

- Status: Open
- First recorded: 2026-08-11
- Evidence: both available browser profiles reach App Store Connect's
  `authResult=FAILED` login page, so the Jenny Media LLC team, app record, role,
  agreements, and internal tester groups cannot yet be inspected. The installed
  Apple Development certificate is a valid Jenny Media LLC certificate
  (`OU=5736QK4NZX`, expires August 5, 2027); no local iOS provisioning profile
  is installed. This supports local team identity but does not prove App Store
  Connect or TestFlight readiness.
- Impact: the first cloud workflow and TestFlight post-action cannot be
  completed until the app record and sufficient Jenny Media LLC role are
  available.
- Does not block: all local milestones and cloud-ready project configuration.
- Needed from owner: sign in to App Store Connect in Chrome or the in-app
  browser, then confirm the Apple ID may create/manage the FrameWink app record
  for `media.jenny.FrameWink` under Jenny Media LLC.

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
  licensed human-labelled evaluation set is available in this workspace.
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

### B-006 — Production Wall Mode product decisions are unconfirmed

- Status: Open
- First recorded: 2026-08-11
- Evidence: the proposed immutable identifier
  `media.jenny.FrameWink.wallmode` and Family Sharing policy have been asked of
  the owner but not confirmed.
- Impact: the production non-consumable cannot safely be created in App Store
  Connect, and a Release/TestFlight build intentionally has no product ID.
- Does not block: the isolated local product, StoreKit 2 implementation,
  injected-client tests, StoreKit Test purchase/restore/refund/pending/failure
  scenarios, paywall UI, hardening, cloud scripts, or local commits.
- Needed from owner: confirm the exact production ID and whether Family Sharing
  should be enabled before the immutable App Store Connect product is created.

### B-007 — Public support and privacy-policy endpoints are missing

- Status: Open
- First recorded: 2026-08-12
- Evidence: the privacy policy is drafted in `docs/APP_STORE.md`, but no stable
  Jenny Media LLC HTTPS policy URL or support contact has been supplied.
- Impact: required App Store metadata cannot be completed or submitted.
- Does not block: source/privacy auditing, the bundled privacy manifest, local
  builds/tests, screenshots, App Review-note drafting, or cloud workflow setup.
- Needed from owner: provide or authorize a stable public privacy-policy URL,
  a support URL, and a monitored Jenny Media LLC support email.

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

## Committed Xcode Cloud guardrail

Apple automatically runs `ci_scripts/ci_pre_xcodebuild.sh` before each Xcode
Cloud action. FrameWink's script validates its two privacy property lists and
Release identity for every action. For an archive, it additionally requires the
Jenny Media LLC team, `media.jenny.FrameWink`, and a nonempty non-local Wall Mode
product identifier. This makes B-006 fail closed at the cloud archive boundary
without preventing Build, Analyze, or Test workflows.

## Remaining release decisions

- Confirm the non-consumable Wall Mode StoreKit product identifier. Proposed:
  `media.jenny.FrameWink.wallmode`.
- Choose the hosted Git provider, organization, repository name, and release
  branch.
- Confirm or create the App Store Connect app record and SKU.
- Select the initial internal TestFlight tester group.
- Provide the public privacy-policy/support URLs and support email (B-007).

## Local debugger tooling note

XcodeBuildMCP is configured for the correct project, scheme, bundle identifier,
and booted iPad, but its process currently inherits `/Library/Developer/CommandLineTools`
from global `xcode-select`; therefore its `simctl` and accessibility commands
cannot resolve the full Xcode installation. Direct commands scoped with
`DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer` continue to
build, test, install, launch, and capture FrameWink successfully. Changing the
machine-wide `xcode-select` setting is intentionally deferred to the owner.
