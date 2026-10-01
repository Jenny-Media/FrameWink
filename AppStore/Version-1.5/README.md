# Version 1.5 stable release

The owner authorized merging PR #20 and submitting a stable-toolchain version
1.5 on October 1, 2026. ASC accepted version **1.5 / Build 60** for review at approximately 7:55 PM EDT;
its verified state is **Waiting for Review**. Manual release after approval is
retained. These files describe the ordinary iPhone/iPad navigation,
layout, safe-area, and accessibility refinements included in that release.

Use stable Xcode 27 (27A266a), iOS SDK 27.0, for this App Review candidate.
`FRAMEWINK_NATIVE_DUO` is absent from its compilation conditions. The source
retains native fold handling for explicitly configured 27.1/27.2 SDK builds;
Apple acceptance and physical Duo checks remain required for a later release.
Internal beta build 1.5 (57) is historical evidence, not the public candidate.

Keep the checksum-locked iPhone/iPad screenshot galleries and existing listing
fields. Both websites continue to label Duo captures as an upcoming preview.
All applicable version fields were saved and read-back verified before submission.
Stable Cloud Validation 59 and signed Archive/TestFlight 60 passed on `13d3dcb`;
merged main `91dfde2` has the identical complete tree. See docs/PLAN.md,
docs/TESTING.md, and docs/APP_STORE.md for exact verification and submission
evidence. Public publication remains pending Apple review and manual release.
