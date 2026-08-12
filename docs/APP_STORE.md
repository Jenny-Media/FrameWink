# App Store and TestFlight draft

This file is release input, not proof of App Store Connect configuration. Keep
it aligned with the shipping build and update it before every submitted version.

## App privacy

Recommended App Store Connect answer for the current build:

- Data collection: **No, we do not collect data from this app.**
- Tracking: none.
- Third-party SDK data practices: none; the app has no third-party production
  SDKs.

Selected photos are copied at display size into the app's private container and
do not leave the iPad through FrameWink. StoreKit purchase processing is
provided by Apple. FrameWink has no account, developer server, analytics,
advertising, telemetry, or developer-controlled network request.

The target includes `PrivacyInfo.xcprivacy` with no collected-data,
required-reason API, tracking, or tracking-domain declarations. Re-run the Xcode
privacy report before submission and change both the manifest and App Store
answers if implementation changes.

## Privacy policy draft

Effective: August 12, 2026

FrameWink is provided by Jenny Media LLC. FrameWink is designed to process
photos locally on the iPad. The app has no developer-operated account or server
and does not upload photos, app activity, identifiers, diagnostics, purchases,
or other personal data to Jenny Media LLC. It does not use advertising,
tracking, or third-party analytics SDKs.

The system photo picker gives FrameWink only the photos the user chooses.
FrameWink stores display-sized copies and local curation records in its private
app container. `Delete Imported Photos` removes those app-controlled copies and
derived records without deleting or changing the originals in Apple Photos.
Apple Photos may download an item from iCloud when the user selects it; that is
Apple Photos behavior, not a FrameWink upload.

Wall Mode purchases use Apple's StoreKit and App Store services. Jenny Media LLC
does not receive payment-card details through FrameWink. Apple's own processing
is governed by Apple's privacy policy.

This policy must be published at a stable HTTPS URL and supplied with a Jenny
Media LLC support contact before App Store submission; both are open under
blocker B-007.

## App Review notes draft

FrameWink is iPad-only and requires iPadOS 15 or later.

On first launch, the app immediately plays three bundled example photos. It does
not request Photos authorization. `Choose My Photos` opens Apple's PHPicker with
a 100-item limit. The current build does not request full PhotoKit library
authorization and therefore intentionally has no Photos usage-description key.
Imported display-sized copies and all analysis remain in the app container.

The free experience includes local Smart Reel curation, review, Never Show
Again, Fit/Fill and portrait pairing, timing, pause/navigation, unlimited
replay, and Delete Imported Photos.

To review the non-consumable Wall Mode purchase, tap `Unlock Wall Mode` on the
main screen. The paywall includes `Restore Purchases`. A verified entitlement
unlocks foreground-only Auto-Lock prevention, visual dim/blackout schedules,
and the wall commissioning checklist. Automatic albums, unlimited sources, and
multiple saved configurations are explicitly labelled as planned and are not
claimed as part of this build.

Consumer Guided Access must be started manually in iPadOS. FrameWink does not
change system brightness, sense ambient light, promise an exact scheduled wake,
or guarantee relaunch after a reboot.

Before submission, replace this paragraph with the confirmed production product
identifier and any reviewer-specific test account or StoreKit instructions.

## Screenshot plan

Use only project-owned sample media or a separately approved licensed fixture
set. Do not use private tester photos.

1. **Private from first launch — Free:** bundled Sample Mode with the sample
   badge and no permission dialog.
2. **Your best 30 — Free:** Smart Reel review grid showing local suggestions and
   `Never Show Again`.
3. **Made for an iPad — Free:** landscape Frame Mode with a paired-portrait
   layout and visible navigation/timing controls.
4. **A one-time wall upgrade — Paid:** the $9.99 non-consumable paywall with the
   full Free Smart Reel comparison and Restore Purchases.
5. **Quiet at night — Paid:** Wall Mode schedule controls with foreground-only
   language visible.
6. **Mount it honestly — Paid:** the power, ventilation, Guided Access, and
   restart-recovery commissioning checklist.

Each caption must say `Free` or `Paid Wall Mode` where the boundary could be
ambiguous. Do not imply automatic albums, ambient sensing, automated Guided
Access, or reboot recovery.

## Xcode Cloud workflow recipe

The workflow itself must be created in Xcode or App Store Connect after blockers
B-001 and B-002 are resolved. A paid TestFlight candidate additionally requires
B-006 and B-008 to be resolved. The repository is otherwise prepared with a
shared archivable `FrameWink` scheme and no external package dependency.

Create two workflows:

1. **FrameWink Validation**
   - Start on pull-request updates and pushes to the chosen main branch.
   - Actions: Analyze (FrameWink, iOS) and Test (FrameWink, iPad Simulator).
   - Deployment preparation: none.
2. **FrameWink Internal TestFlight**
   - Start manually and on the chosen release branch or tag.
   - Environment: Clean.
   - Action: Archive `FrameWink` for iOS with `TestFlight (Internal Testing
     Only)` deployment preparation.
   - Post-action: distribute to the owner-confirmed Jenny Media LLC internal
     tester group.
   - Use the current production Xcode version after one successful validation
     workflow; do not pin the local beta toolchain by assumption.

Xcode Cloud automatically increments build numbers. The committed
`TestFlight/WhatToTest.en-US.txt` supplies the tester notes. Download release
artifacts and dSYMs before Xcode Cloud's retention window expires.
