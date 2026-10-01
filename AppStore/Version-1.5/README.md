# Version 1.5 stable release

The owner authorized merging PR #20 and submitting a stable-toolchain version
1.5 on October 1, 2026. These files describe the ordinary iPhone/iPad navigation,
layout, safe-area, and accessibility refinements included in that release.

Use stable Xcode 27 (27A266a), iOS SDK 27.0, for this App Review candidate.
`FRAMEWINK_NATIVE_DUO` is absent from its compilation conditions. The source
retains native fold handling for explicitly configured 27.1/27.2 SDK builds;
Apple acceptance and physical Duo checks remain required for a later release.
Internal beta build 1.5 (57) is historical evidence, not the public candidate.

Keep the checksum-locked iPhone/iPad screenshot galleries and existing listing
fields. Both websites continue to label Duo captures as an upcoming preview.
Save and read back all version fields, select the new stable archive, submit
to App Review, and retain manual release after approval. Submission and public
publication must be recorded separately in docs/PLAN.md and docs/APP_STORE.md.
