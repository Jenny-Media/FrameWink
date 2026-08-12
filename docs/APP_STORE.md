# App Store and TestFlight draft

This file is release input, not proof of App Store Connect configuration. Keep
it aligned with the shipping build and update it before every submitted version.

## App privacy

Recommended App Store Connect answer for the current build:

- Data collection: **No, we do not collect data from this app.**
- Tracking: none.
- Third-party SDK data practices: none; the app has no third-party production
  SDKs.

Picker-selected photos and photos from a paid, explicitly selected album are
copied at display size into the app's private container and do not leave the
iPad through FrameWink. StoreKit purchase processing is provided by Apple.
FrameWink has no account, developer server, analytics, advertising, telemetry,
or developer-controlled network request.

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

The system photo picker gives FrameWink only the free-mode photos the user
chooses. After a Wall Mode purchase, a user may explicitly authorize Photos and
select an album for automatic refresh. FrameWink lists album names and photo
counts for that chooser, reads photo content only from the selected album,
filters hidden photos and screenshots, and never edits the Photos library.

FrameWink stores display-sized copies, local curation records, and local display
history in its private app container. Photo copies, automatic-album cache data,
and derived curation data are excluded from device backup. `Delete Imported
Photos` and `Delete Automatic Album Cache` remove the corresponding
app-controlled copies and derived records without deleting or changing the
originals in Apple Photos.
Apple Photos may download an iCloud item when Strict Offline is disabled; that
is Apple Photos behavior, not a FrameWink upload. Strict Offline keeps network
access disabled for automatic-album image requests.

Wall Mode purchases use Apple's StoreKit and App Store services. Jenny Media LLC
does not receive payment-card details through FrameWink. Apple's own processing
is governed by Apple's privacy policy.

This policy must be published at a stable HTTPS URL and supplied with a Jenny
Media LLC support contact before App Store submission; both are open under
blocker B-007.

## App Review notes draft

FrameWink is iPad-only and requires iPadOS 15 or later.

On first launch, the app immediately plays three bundled example photos and does
not request Photos authorization. `Choose My Photos` opens Apple's PHPicker with
a 100-item limit. The target includes `NSPhotoLibraryUsageDescription`, but the
full PhotoKit prompt appears only after a verified Wall Mode entitlement and the
user taps `Choose Automatic Album`. Display-sized copies and all analysis remain
in the app container. The app suppresses iOS's automatic Limited-access alert so
later prompts remain tied to explicit album-management actions.

The free experience includes local Smart Reel curation, review, Never Show
Again, Fit/Fill and portrait pairing, timing, pause/navigation, unlimited
replay, and Delete Imported Photos.

To review the non-consumable Wall Mode purchase, tap `Unlock Wall Mode` on the
main screen. The paywall includes `Restore Purchases`. A verified entitlement
unlocks automatic refresh for an explicitly selected Photos album, curation of
all eligible album candidates without the free 100-candidate input limit,
long-term repeat reduction, a Mosaic layout, multiple saved frame
configurations, foreground-only Auto-Lock prevention, visual dim/blackout
schedules, and the wall commissioning checklist.

For automatic albums, try both Strict Offline states, change the selected album
in Photos, return to FrameWink, review the regenerated suggestions, and use
`Delete Automatic Album Cache`. FrameWink never creates a PhotoKit change
request and does not edit or delete originals.

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
5. **Fresh from your album — Paid:** the selected-album refresh controls with
   Strict Offline and on-device privacy wording visible.
6. **A frame for each room — Paid:** saved configurations and the four-photo
   Mosaic layout.
7. **Quiet at night — Paid:** Wall Mode schedule controls with foreground-only
   language visible.
8. **Mount it honestly — Paid:** the power, ventilation, Guided Access, and
   restart-recovery commissioning checklist.

The filename and visible product UI must say `Free` or `Paid Wall Mode` where
the boundary could be ambiguous. Automatic-album screenshots must show an
explicitly selected album; do not imply Apple Memories/People access, ambient
sensing, automated Guided Access, or reboot recovery.

Ten native, upload-ready 13-inch iPad screenshots are committed under
`AppStore/Screenshots/Submission/iPad-13-inch/`. They are 2064 x 2752 JPEGs
without alpha and cover three Free Smart Reel screens followed by seven Paid
Wall Mode screens. The paid sequence includes the `$9.99` one-time purchase and
Restore Purchases, automatic-album/Strict Offline setup, saved configurations,
Mosaic Frame Mode, night scheduling, commissioning guidance, and the feature
overview. They use only bundled project-owned media. Run
`scripts/capture_app_store_submission_screenshots.sh` to regenerate and validate
the set. Marketing caption overlays are optional rather than a submission gate.

The broader eleven-image 1640 x 2360 source library remains under
`AppStore/Screenshots/iPad/` and can be regenerated with
`scripts/capture_app_store_screenshots.sh`.

## Xcode Cloud workflow recipe

The workflow itself must be created in Xcode or App Store Connect after blockers
B-001 and B-002 are resolved. A paid TestFlight candidate additionally requires
B-006 to be resolved. The repository is otherwise prepared with a
shared archivable `FrameWink` scheme and no external package dependency.

The executable `ci_scripts/ci_pre_xcodebuild.sh` runs automatically before each
cloud action. Validation actions check the Release identity and privacy files.
Archive actions fail closed until the production Wall Mode identifier is
configured, and reject the Debug-only local product identifier.

Create two workflows:

1. **FrameWink Validation**
   - Start on pull-request updates and pushes to the chosen main branch.
   - Actions: Analyze (FrameWink, iOS) and Test (FrameWink, iPad Simulator).
     The shared scheme's Test action includes both `FrameWinkTests` and the
     first-launch/privacy `FrameWinkUITests` bundle.
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
