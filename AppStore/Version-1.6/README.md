# Version 1.6 native iPhone Duo release candidate

Prepared with owner authorization on October 6, 2026, after Apple opened Duo
App Store submissions and Xcode 27.1 RC became available. Release toolchain:
Xcode 27.1 RC (27A9275), iOS SDK 27.1. Existing native fold handling is enabled;
minimum iOS/iPadOS 15, device families 1/2, privacy, and Lifetime scope remain.
The archive guard rejects a standard-viewport build or a different SDK line.

Status: preparation in progress. Local RC tests, pose/screenshot verification,
exact-source Cloud Analyze/archive, processed TestFlight build, listing audit,
and App Review remain to be verified. Retain manual release after approval.
Physical Duo acceptance remains separate and is not inferred from Simulator.

Keep checksum-locked approved iPhone/iPad galleries. Refresh Duo native captures
with project-owned sample photos and preserve the licensed official artwork.
Both websites keep upcoming-preview wording until the native version is public.
See docs/PLAN.md and docs/TESTING.md for actual verification evidence.

October 6 checkpoint: draft PR #23 at `13c077e`; exact-source Cloud Analyze
Build 65 passed with the pinned RC. ASC 1.6 has saved/reloaded text fields,
inherited phone/iPad galleries, manual release, existing rating, and no sign-in.
One native outer-display Duo image is processed; original PNG/JPEG hashes
are retained here. Two iPhone timeout failures passed unchanged in isolation;
full iPad/Duo regression and manual poses/inner captures remain pending.
Disk exhaustion and Device Hub UI timeouts require external-state resolution.
Signed archive, final IAP/platform audit, merge, and review are still pending.
