# Durable project goal

Move the LocalPhotoFrame Codex starter into `/Users/yihong/work/FrameWink` and
carry FrameWink through its documented MVP milestones to a verified,
privacy-preserving iPadOS app.

Use product name `FrameWink`, bundle identifiers `media.jenny.FrameWink` and
`media.jenny.FrameWinkTests`, and the Jenny Media LLC development team. Keep the
free Smart Reel and paid Wall Mode boundary intact. Add proportionate tests,
record verification evidence, and create local milestone checkpoint commits.

Prepare Xcode Cloud as the authoritative build pipeline and connect successful
release archives to TestFlight instead of relying on local archive uploads.

## Operating rule

Record each blocker immediately in `docs/DISTRIBUTION.md` or `docs/PLAN.md`.
Continue every safe, independent task that does not depend on that blocker. Do
not stop at the first obstacle. Stop only at verified completion or a true
impasse that requires owner action, new authority, credentials, or external
state.

## Validation and stop condition

- Each milestone's acceptance criteria in `docs/PLAN.md` pass.
- Automated tests and relevant Simulator/device checks are recorded in
  `docs/TESTING.md`.
- App behavior and release claims remain consistent with `docs/PRODUCT.md` and
  `AGENTS.md`.
- Xcode Cloud produces a clean archive and a TestFlight build for Jenny Media
  LLC, or the exact external prerequisite preventing that boundary is recorded
  after all independent project work is complete.
