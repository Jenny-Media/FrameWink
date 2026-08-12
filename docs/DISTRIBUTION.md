# Distribution and continuous delivery

## Confirmed identity

- Product: `FrameWink`
- App bundle identifier: `media.jenny.FrameWink`
- Unit-test bundle identifier: `media.jenny.FrameWinkTests`
- Apple Developer team: Jenny Media LLC (`5736QK4NZX`)
- Signing style: automatic

## Intended delivery path

Xcode Cloud is the authoritative release builder. Local builds are for fast
development feedback; the project does not depend on a local archive-and-upload
procedure.

The first cloud workflow should:

1. Start on updates to the release branch and allow manual runs.
2. Build and run the unit-test target on an iPad Simulator.
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
- Evidence: `git remote -v` returns no remotes.
- Impact: Xcode Cloud cannot clone or connect to the project.
- Does not block: local implementation, builds, tests, signing configuration,
  documentation, or commits.
- Needed from owner: choose the Git provider and Jenny Media repository URL,
  then authorize the initial push and Xcode Cloud repository access.

### B-002 — App Store Connect readiness is unverified

- Status: Open
- First recorded: 2026-08-11
- Impact: the first cloud workflow and TestFlight post-action cannot be
  completed until the app record and sufficient Jenny Media LLC role are
  available.
- Does not block: all local milestones and cloud-ready project configuration.
- Needed from owner: confirm the signed-in Apple ID has permission to create or
  manage the FrameWink app record for `media.jenny.FrameWink`.

### B-003 — No iPad Simulator is booted

- Status: Resolved on 2026-08-11
- First recorded: 2026-08-11
- Impact: the compiled unit tests and launch/UI flow have not yet executed.
- Does not block: generic Simulator builds, build-for-testing, implementation,
  or documentation.
- Resolution: the installed iOS 27 `iPad (A16)` Simulator was booted. FrameWink
  was installed and launched; the current full suite passes all 33 tests.

### B-004 — Physical curation-validation hardware and labelled set are missing

- Status: Open
- First recorded: 2026-08-11
- Impact: public Vision enrichment, the 100-photo time/memory gate on the
  oldest supported iPad, thermal behavior, and the human-labelled 80%
  displayability gate cannot yet receive physical acceptance evidence.
- Does not block: deterministic curator implementation, Simulator analysis,
  fixture-driven duplicate/date/layout tests, review UI, persistence, Wall Mode,
  purchases, cloud-readiness work, or local checkpoint commits.
- Needed from owner: identify the oldest available supported iPad and provide
  or approve a small licensed, human-labelled evaluation-photo set.

### B-005 — Physical Wall Mode soak device is not assigned

- Status: Open
- First recorded: 2026-08-11
- Impact: actual Auto-Lock prevention/restoration, brightness appearance,
  Guided Access status changes, thermal/charging behavior, mount safety, and the
  seven-day unattended run cannot yet receive physical evidence.
- Does not block: schedule logic, visual overlays, state restoration, persisted
  configuration, safety guidance, purchases, Xcode Cloud readiness, or local
  commits.
- Needed from owner: assign a compatible iPad, safe charger/cable and mounting
  location, then record device/OS and authorize the seven-day physical run.

## Remaining release decisions

- Confirm the non-consumable Wall Mode StoreKit product identifier. Proposed:
  `media.jenny.FrameWink.wallmode`.
- Choose the hosted Git provider, organization, repository name, and release
  branch.
- Confirm or create the App Store Connect app record and SKU.
- Select the initial internal TestFlight tester group.
