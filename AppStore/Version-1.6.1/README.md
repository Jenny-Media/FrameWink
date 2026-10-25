# Version 1.6.1 release preparation — 2026-10-24

Candidate: **1.6.1 (80)**. This is a local, unuploaded release-preparation candidate. Marketing version 1.6.1 is retained because the public version is 1.6 and 1.6.1 remains an unreleased TestFlight train. Application Debug and Release build numbers are 80. Xcode Cloud controls its own exported build number; recheck live numbers before any later upload. No number is reserved remotely by this change.

Baseline: latest fetched origin/main `73b85f6d7d008303d5c534c9eff0d04a433c75a9`, the merge of PR #31. It includes companion browsing/position, native division-margin handling, caption readability, More preservation through unfold and blackout onset, and blackout darkness through geometry changes. Existing iOS/iPadOS 15, iPhone/iPad-only scope, signing, product ID and privacy rules are retained.

Live read-only audit on October 24 through the owner's signed-in App Store Connect session:
- Distribution: iOS 1.6, Ready for Distribution, attached build 66; no newer App Store version is listed.
- TestFlight: 1.6.1 (78), Complete / Ready to Submit, assigned to Jenny Media Internal; 1.6.1 (76), Testing, also assigned to External Testers; (72), Ready to Submit.
- Xcode Cloud: latest Validation 79 and Internal TestFlight 78 both list PR #31's merge as their source. Build 80 exceeds observed Cloud and upload numbers. Both saved build summaries were read back: Archive 78 and its internal TestFlight post-action succeeded; Analyze 79 succeeded, each from `73b85f6`. Recheck before future distribution.

Release inputs: `WhatsNew.en-US.txt`, `AppReviewNotes.en-US.txt`, `What-to-Test.txt` (identical to the canonical TestFlight file), and `Hardware-Test-Checklist.md`. Keep existing approved galleries; this task does not publish metadata or change availability.

## Release-history reconciliation

Only open PR at audit time: [#14, Document FrameWink 1.1 release](https://github.com/Jenny-Media/FrameWink/pull/14), head `ee684e27897dba7191830cfc828e27a1eafa47da`. It conflicts with current main and changes four release documents. Its 1.1 (30) delivery history is missing from portions of main, while other text already acknowledges 1.1 shipped. Carry its dated evidence into current historical records; do not merge obsolete current-availability, budget-complete or pending-state replacements wholesale. This preparation reconciles the unique 1.1 record; #14 itself remains untouched for owner disposition.

## Prior 1.6.1 checkpoints

Apple closed the public 1.6 train; rejected build 70 used 1.6. Version 1.6.1 (72) was processed after Cloud Archive 72 and Analyze 73 from `c243d2e8332ea8450ea99b23d2493226c8dd3d54`. Build 76 from `6198ea3` later reached external testing. Those binaries predate the PR #31 companion-control improvements and are not build 80 acceptance evidence.

## Stop boundary

Prepare PR, run local Simulator checks, and retain a signed local archive only. No upload, Xcode Cloud start, tester assignment, App Review submission, merge, production website deployment or publication. Xcode Cloud remains the authoritative distribution builder under D-013/D-049; a later merge to main can automatically upload/distribute and requires separate authorization. Physical follow-up is TestFlight-only. Simulator failures remain blockers; hardware acceptance is not inferred.

## Verification outcome

See the [initial verification record](Verification-2026-10-24.md) and
[orientation/menu-driver follow-up](Duo-Orientation-Fix-2026-10-24.md) for exact
commands, source identities, counts, warnings and retained failures. The signed
application archive source remains `8bfb9bd2c525ec0fcacb733e805144b9dca69813`.
All 85 application/project inputs match it after test/tooling commit
`4ec5f61034749ab59a205c68e54c287968057d76`. The signed archive and local
Apple Distribution-signed IPA remain under ignored `TestArtifacts/ReleasePrep-20261024/`.

All four original landscape-precondition cases pass after the Simulator-only
input repair, with original predicates and product assertions retained. The
formerly excluded Duo rotation round trip is restored. The additional Larger
Text privacy driver now scrolls within the menu's clipped viewport and passes
on iPhone/iPad/Duo. Final complete iPhone, iPad and native Duo suites each pass
**254 passed / 0 failed / 4 physical-only skips**, at committed native source
`4ec5f61` with 134 unchanged input hashes. The original failures and
intermediate diagnostics are preserved; no new skip or timeout increase is used.

The [artwork-validator follow-up](Artwork-Verification-2026-10-24.md) corrects
both stale inventories: eleven iPad landscape source captures and seven approved
iPad cards. It adds the six iPhone and six current Duo cards to raster validation
and includes the six current Duo approval hashes in the standard lock check.
All 86 screenshots, IAP review image, icon and 23 approval hashes pass. All 162
tracked artwork files are unchanged. The [complete screenshot gallery](Screenshot-Gallery.md)
shows all 19 retained release cards in order; none was recaptured from build 80.

Keep PR #32 draft and stop before upload. Hardware acceptance remains the separate
TestFlight-only checklist, unrun for candidate 80. Nothing was uploaded or submitted.
