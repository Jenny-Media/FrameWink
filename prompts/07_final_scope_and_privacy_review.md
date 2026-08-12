# Codex review task — final scope, privacy, and claims

Perform a read-only review unless a clearly mechanical documentation correction
is necessary and authorized.

Read `AGENTS.md`, all files in `docs/`, the final source, entitlements, package
dependencies, Info.plist values, StoreKit configuration, and App Store draft
copy.

Report findings in priority order for:

1. Any developer-controlled network path, account behavior, analytics,
   tracking, or undeclared third-party dependency.
2. Any photo mutation, unexpected full-library request, or retained user copy
   without a deletion path.
3. Claims about ambient sensing, Guided Access, automatic reboot recovery,
   Apple Photos intelligence, strict offline behavior, or device compatibility
   that exceed the implementation/platform.
4. Free/paid behavior that differs from product-page or paywall copy.
5. StoreKit entitlement, restore, refund, revocation, pending, and offline
   correctness.
6. Memory, thermal, battery, background-execution, or old-device reliability
   risks.
7. Missing privacy policy, App Privacy, permission-purpose, accessibility, or
   App Review information.
8. Scope that entered the product without a decision in `docs/DECISIONS.md`.

For every finding, cite the exact file and line and propose the smallest safe
correction. State explicitly if no actionable findings remain.
