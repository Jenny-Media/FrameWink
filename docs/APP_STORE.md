# App Store and TestFlight draft

This file is release input, not proof of App Store Connect configuration. Keep
it aligned with the shipping build and update it before every submitted version.

## Current availability

FrameWink 1.0 is approved and available on the App Store at
`https://apps.apple.com/us/app/framewink/id6800849400`. The public website uses
Apple's official unmodified Download on the App Store badge for this listing.

## Version 1.0.1 release candidate

Version 1.0.1 is a focused first-update candidate. It expands the clearly
labelled, permission-free sample reel from ten to twenty publisher-supplied
photos, improves the protected framing of portrait samples, and avoids
multi-photo arrangements that would discard too much of an image. It does not
change the free/paid boundary, privacy behavior, supported platforms, purchase
identifier, or lifetime price.

Release notes draft:

> A richer built-in sample reel with ten new photos, improved framing, and
> smarter multi-photo layouts that keep more of every image in view.

Keep the released, approved screenshot galleries unless a final review finds
that they no longer represent the app accurately. The existing FrameWink
Lifetime non-consumable is already approved and remains live; do not add it as
a new review item for this update unless App Store Connect explicitly requires
it.

## App privacy

Recommended App Store Connect answer for the current build:

- Data collection: **No, we do not collect data from this app.**
- Tracking: none.
- Third-party SDK data practices: none; the app has no third-party production
  SDKs.

App Store Connect Apple ID `6800849400` has the policy URL and `Data Not
Collected` answer published. Any future privacy-answer change remains an owner
action because Apple's final dialog includes a legal accuracy/compliance
attestation; see B-009 in `docs/DISTRIBUTION.md`.

Picker-selected photos and photos from a paid, explicitly selected album are
copied at display size into the app's private container and do not leave the
device through FrameWink. StoreKit purchase processing is provided by Apple.
FrameWink has no account, developer server, analytics, advertising, telemetry,
or developer-controlled network request.

The target includes `PrivacyInfo.xcprivacy` with no collected-data,
required-reason API, tracking, or tracking-domain declarations. Re-run the Xcode
privacy report before submission and change both the manifest and App Store
answers if implementation changes.

`Info.plist` declares `ITSAppUsesNonExemptEncryption = false`. FrameWink uses no
custom or non-exempt encryption; Apple system services such as StoreKit and
PhotoKit are the only relevant transport surfaces.

## Published privacy policy

- Privacy policy URL:
  `https://github.com/Jenny-Media/FrameWink/blob/main/PRIVACY.md`
- Support URL: `https://github.com/Jenny-Media/FrameWink/issues`
- Support email: `framewink@jenny.media`

The canonical policy is the root-level `PRIVACY.md`. The copy below is retained
as release-review input and must remain aligned with it.

Effective: August 12, 2026

FrameWink is provided by Jenny Media LLC. FrameWink is designed to process
photos locally on the device. The app has no developer-operated account or server
and does not upload photos, app activity, identifiers, diagnostics, purchases,
or other personal data to Jenny Media LLC. It does not use advertising,
tracking, or third-party analytics SDKs.

The system photo picker gives FrameWink only the free-mode photos the user
chooses. After a FrameWink Lifetime purchase, a user may explicitly authorize Photos and
select an album for automatic refresh. FrameWink lists album names and photo
counts for that chooser, reads photo content only from the selected album,
filters hidden photos and screenshots, and never edits the Photos library.

FrameWink stores display-sized copies, local curation records, and local display
history in its private app container. Photo copies, automatic-album cache data,
and derived curation data are excluded from device backup. `Delete Imported
Photos` and `Remove Downloaded Album Photos` remove the corresponding
app-controlled copies and derived records without deleting or changing the
originals in Apple Photos.
Apple Photos may download an iCloud item when an automatic album needs it; that
is Apple Photos behavior, not a FrameWink upload or a connection to Jenny Media
LLC.

Wall Mode purchases use Apple's StoreKit and App Store services. Jenny Media LLC
does not receive payment-card details through FrameWink. Apple's own processing
is governed by Apple's privacy policy.

The public repository hosts this policy and the Issues tracker provides the
support endpoint. Privacy questions and support mail go to
`framewink@jenny.media`.

## Version 1.0 product-page copy

Subtitle:

> Private smart photo frame

Promotional text:

> A private, local-first photo frame for iPhone and iPad. Choose photos, press Start Frame, and keep memories fresh with one FrameWink Lifetime upgrade.

Description:

> Turn an iPhone or iPad into a calm, private photo frame in a few taps.
>
> FrameWink starts with clearly labelled sample photos, so you can see the experience before granting access to anything. When you are ready, choose your own photos with Apple's system photo picker. FrameWink prepares a Smart Reel entirely on your device and keeps display-sized copies inside the app.
>
> FREE SMART REEL
>
> • Import up to 500 photo candidates across sessions
> • Get up to 100 locally curated recommendations
> • Review the reel before it plays
> • Remove an unwanted photo with Never Show Again and undo mistakes
> • Let automatic layouts protect faces, pair compatible portraits, and fit each screen
> • Swipe, pause, share, and choose 10-second, 30-second, 1-minute, or 5-minute timing
> • Replay without a watermark, ads, an account, or a trial countdown
>
> FRAMEWINK LIFETIME
>
> A single $4.99 purchase unlocks automatic refresh from one Photos album you explicitly choose, an unlimited supported-album candidate pool, fresher recommendations with longer-term repeat avoidance, additional automatic multi-photo layouts, optional night schedules, foreground Auto-Lock prevention while the frame plays, and practical mounted-display guidance. Family Sharing is supported where available from Apple.
>
> PRIVATE BY DESIGN
>
> FrameWink has no developer server, account, advertising, analytics SDK, or tracking. Photos and analysis stay on your device. FrameWink never edits, hides, favorites, or deletes originals in your Photos library. You can remove imported copies and downloaded album copies from the app at any time.
>
> Automatic album updates request full Photos access only after you choose that paid feature. FrameWink excludes hidden photos and screenshots from automatic selection. Guided Access setup remains a manual Apple system feature, and scheduled display behavior works only while FrameWink remains open.
>
> Requires iOS or iPadOS 15 or later.

Keywords (89 characters):

> photo frame,slideshow,photos,album,smart display,digital frame,private,mosaic,iPhone,iPad

## App Review notes draft

FrameWink is a universal iPhone and iPad app and requires iOS/iPadOS 15 or
later. Compact iPhone playback prioritizes one large photo; iPad and larger
windows can use responsive multi-photo compositions when appropriate.

On first launch, version 1.0.1 immediately shows twenty bundled example photos
and does not request Photos authorization. `Choose Photos` opens Apple's
PHPicker for a total collection of up to 500 items. The target includes
`NSPhotoLibraryUsageDescription`, but the
full PhotoKit prompt appears only after a verified FrameWink Lifetime entitlement
and the user taps `Choose an Album`. Display-sized copies and all analysis remain
in the app container. The app suppresses iOS's automatic Limited-access alert so
later prompts remain tied to explicit album-management actions.

The free experience includes local Smart Reel curation, review, Never Show
Again, automatic face-safe Fit/Fill decisions and portrait pairing, selectable
timing, pause/navigation, unlimited replay, and Delete Imported Photos.

To review the non-consumable purchase, open `More Frame Features` from the main
screen. The FrameWink Lifetime paywall includes `Restore Purchases`. A verified entitlement
unlocks automatic refresh for an explicitly selected Photos album, curation of
all eligible album candidates without the free 500-candidate input limit,
long-term repeat reduction, automatic Mosaic composition when appropriate, a
persisted active source/timing state, foreground-only Auto-Lock prevention,
visual dim/blackout schedules, and mounted-display guidance.

For automatic albums, include an iCloud-backed item and confirm preparation
continues while Apple Photos downloads it. Change the selected album in Photos,
return to FrameWink, review the regenerated suggestions, and use `Remove
Downloaded Album Photos`. FrameWink never creates a PhotoKit change
request and does not edit or delete originals.

Consumer Guided Access must be started manually. FrameWink does not
change system brightness, sense ambient light, promise an exact scheduled wake,
or guarantee relaunch after a reboot.

The production non-consumable identifier is
`media.jenny.FrameWink.wallmode`, with Family Sharing enabled. No reviewer test
account is required; App Review should use its StoreKit sandbox environment.

The App Store Connect product is Apple ID `6800849862`. Its saved reference and
English (U.S.) display name are `FrameWink Lifetime`; its saved description is
`Automatic albums, Mosaic, night schedules, and more.` It is priced at a $4.99
U.S. base across all available storefronts and has Family Sharing permanently
enabled. The version 1.0 product-page copy above is the release source of truth.
The submitted App Store Connect description was corrected to `$4.99` and saved
on 2026-08-14.

## Screenshot plan

Use only project-owned sample media or a separately approved licensed fixture
set. Do not use private tester photos.

1. **Private from first launch — Free:** bundled Sample Mode with the sample
   badge and no permission dialog.
2. **Your best 30 — Free:** Smart Reel review grid showing local suggestions and
   `Never Show Again`.
3. **Made for an iPad — Free:** clean landscape Frame Mode featuring the
   project-owned aerial coast photo with no transient playback chrome.
4. **A one-time wall upgrade — Paid:** the $4.99 non-consumable paywall with the
   full Free Smart Reel comparison and Restore Purchases.
5. **Fresh from your album — Paid:** the Photos-familiar progressive album grid
   with a clearly selected source.
6. **Simple at a glance — Paid:** the native Frame Controls segmented picker
   with the selected 30-second default and direct 10-second, 30-second,
   1-minute, and 5-minute choices.
7. **Made for every photo — Paid:** An automatic multi-photo frame that shows
   the aerial coast, spring flowers, open road, and sunset in a balanced Mosaic
   without exposing another layout setting.
8. **Quiet at night — Paid:** Frame Settings with the optional schedule and
   foreground-only language visible.
9. **Mount it honestly — Paid:** concise power, ventilation, Guided Access, and
   restart-recovery guidance.
10. **One lifetime upgrade — Paid:** the concise FrameWink Lifetime feature
    overview without a configuration-heavy promise.

The filename and visible product UI must say `Free` or `Paid Wall Mode` where
the boundary could be ambiguous. Automatic-album screenshots must show an
explicitly selected album; do not imply Apple Memories/People access, ambient
sensing, automated Guided Access, or reboot recovery.

Ten native, upload-ready 13-inch iPad screenshots are committed under
`AppStore/Screenshots/Submission/iPad-13-inch/`. They are 2064 x 2752 JPEGs
without alpha and cover three Free Smart Reel screens followed by seven Paid
Wall Mode screens. The currently submitted paid sequence shows the former
`$9.99` price. The repository's iPad, iPhone, and source screenshot sets were
regenerated with the `$4.99` product presentation on 2026-08-14; replace the
submitted galleries at the next editable screenshot opportunity. The set also covers Restore Purchases,
automatic-album setup, direct Frame Controls, automatic
Mosaic playback, night scheduling, mounted-iPad guidance, and the feature overview.
They use only bundled project-owned media. Run
`scripts/capture_app_store_submission_screenshots.sh` to regenerate and validate
the set. Marketing caption overlays are optional rather than a submission gate.

The broader eleven-image 1640 x 2360 source library remains under
`AppStore/Screenshots/iPad/` and can be regenerated with
`scripts/capture_app_store_screenshots.sh`.

Ten native 1320 x 2868 JPEGs for the 6.9-inch iPhone slot are committed under
`AppStore/Screenshots/Submission/iPhone-6.9-inch/`. They use the same honest
Free/Paid sequence while showing compact single-photo playback instead of
forcing an iPad Mosaic into a narrow viewport. Regenerate and validate them
with `scripts/capture_app_store_iphone_submission_screenshots.sh`.
The current primary Frame image fits the complete white-bird portrait rather
than cropping its head or reflection. The second playback card uses the city
tower, while review and album-selection screens introduce the aerial coast,
flowers, open road, and sunset so the gallery does not repeat one city image.

Ten benefit-led marketing candidates for each device family are committed
under `AppStore/Screenshots/Marketing/`. They keep the exact 6.9-inch iPhone and
13-inch iPad dimensions while adding a short headline, restrained FrameWink
background, and a straight, unmodified native app screen. They do not draw or
simulate Apple hardware.
Run `scripts/generate_app_store_marketing_screenshots.sh` to regenerate them
and `scripts/validate_app_store_assets.sh` to validate both the native and
marketing sets. The visual pattern is intentionally generic—one benefit per
card plus a large app view—and does not reuse competitor artwork, copy,
iconography, typography, or unsupported claims.

An additional iPad-first landscape library is committed under
`AppStore/Screenshots/Landscape/` and
`AppStore/Screenshots/Marketing-Landscape/`. It contains ten native and ten
captioned 2752 x 2064 iPad images, plus three native and three captioned
2868 x 1320 iPhone images. The captioned variants place an unmodified native
screen capture beside the message and intentionally contain no simulated
iPhone/iPad shell. Website derivatives use the same native captures. Run
`scripts/capture_app_store_landscape_screenshots.sh` and then
`scripts/generate_landscape_marketing_assets.sh` to regenerate them.

The proposed replacement gallery is landscape-first on iPad and portrait on
iPhone. Use all ten files from
`AppStore/Screenshots/Marketing-Landscape/iPad-13-inch/` in filename order for
the 13-inch iPad slot, and all ten files from
`AppStore/Screenshots/Marketing/iPhone-6.9-inch/` in filename order for the
6.9-inch iPhone slot. This combination leads with the mounted/tabletop iPad use
case while keeping the portable iPhone presentation native to its geometry.

For any future lifestyle image, use authentic custom photography or an
Apple-provided product bezel under Apple's current marketing terms. Do not use
AI-generated or hand-drawn hardware as though it were an iPhone or iPad.

The owner withdrew version 1.0 from review on 2026-08-14 so the screenshot
gallery can be replaced. The app and lifetime IAP must be put back into a
two-item submission after the replacement galleries are approved and uploaded.
Do not upload or resubmit until the owner approves the contact sheets.

## Xcode Cloud workflow recipe

Xcode Cloud is connected to Jenny Media LLC and the GitHub App remains limited
to `Jenny-Media/FrameWink`. The owner signed back in to Xcode on 2026-08-14 and
the first cloud build succeeded against commit `b8691b9`. Build 6 at commit
`6f59253` subsequently completed its clean archive and TestFlight post-action;
FrameWink 1.0 (6) is `Ready to Test`. The repository has a shared archivable
`FrameWink` scheme, no external package dependency, and Xcode's generated
project-level cloud manifest.

The executable `ci_scripts/ci_pre_xcodebuild.sh` runs automatically before each
cloud action. Validation actions check the Release identity and privacy files.
Archive actions fail closed until the production Wall Mode identifier is
configured, and reject the Debug-only local product identifier.

The configured workflows are:

1. **Validation**
   - Start on pushes to `main` with automatic cancellation of superseded
     builds.
   - Actions: Analyze (FrameWink, iOS) and Test on both an iPhone Simulator and
     an iPad Simulator.
     The shared scheme's Test action includes both `FrameWinkTests` and the
     first-launch/privacy `FrameWinkUITests` bundle.
   - Deployment preparation: none.
2. **Internal TestFlight / release candidate**
   - Start manually from a chosen branch. Automatic branch archives are
     intentionally disabled.
   - Environment: Clean.
   - Action: Archive `FrameWink` for iOS with `App Store Connect` deployment
     preparation so the same build is eligible for TestFlight and App Review.
   - Post-action: distribute to the existing `Jenny Media Internal` group.
     App Store Connect explicitly states that Xcode Cloud builds are not
     included by the group's automatic-distribution switch.
   - Use the current production Xcode version after one successful validation
     workflow; do not pin the local beta toolchain by assumption.

Xcode Cloud automatically increments build numbers. The committed
`TestFlight/WhatToTest.en-US.txt` supplies the tester notes. Download release
artifacts and dSYMs before Xcode Cloud's retention window expires.

## App Store Connect readiness

- Internal testing group: `Jenny Media Internal` (currently 1 tester; Build 6
  is internal-only and Build 8 is the App Store-eligible release candidate)
- TestFlight feedback email: `framewink@jenny.media`
- TestFlight marketing URL: `https://github.com/Jenny-Media/FrameWink`
- TestFlight privacy URL:
  `https://github.com/Jenny-Media/FrameWink/blob/main/PRIVACY.md`
- Production URLs: `https://frame.jenny.media` for marketing,
  `https://frame.jenny.media/support` for support, and
  `https://frame.jenny.media/privacy` for privacy.
- Paid Apps and Free Apps agreements: active for all regions
- Banking, U.S. W-9, and Digital Services Act compliance: active
- Primary category: Photo & Video
- Universal-release subtitle: `Private smart photo frame`
- App base price: free in all 175 current and future regions
- Lifetime IAP availability: saved for all 175 current countries or regions and
  all future regions; Family Sharing is enabled. The first non-consumable must
  be submitted with the first app version; see B-022 in
  `docs/DISTRIBUTION.md`.
- Public Apple-silicon Mac and Apple Vision Pro availability: disabled; the app
  is designed and supported only for iPhone and iPad touch interaction.
- `Jenny Media Internal` TestFlight testing on Apple-silicon Mac and Apple
  Vision Pro: disabled (`Not Available`).
- Product-page copy: current universal promotional text, description, keywords,
  subtitle, support, marketing, and copyright are saved.
- App Store screenshots: the released 1.0 listing uses the approved iPad and
  iPhone galleries without pricing references. Repository screenshot sources
  remain regeneration inputs; never upload price-bearing variants.
- App Review contact: Yihong Chen is saved, but a final live-field audit found
  the phone and email inputs empty. Re-enter the owner-approved review contact
  immediately before submission; the private phone number is not copied into
  this public repository.
- App Privacy is published as `Data Not Collected`; content rights are
  confirmed, and the completed all-No/None questionnaire produced a 4+ age
  rating. B-011 is reopened only for gallery replacement and resubmission.
- The owner chose trader status for Jenny Media LLC. Apple's DSA contact
  verification is in progress under B-024; do not submit for EU distribution
  until Apple accepts the required email, phone, and business verification.
- Release package: iOS 1.0 (8) and `FrameWink Lifetime` were approved and
  released. The public listing is Apple ID `6800849400`.
- Release validation: Xcode Cloud Build 10 at `d6d7026` succeeded in Analyze
  and Test across all eight recommended iPhone/iPad destinations: 174 passed,
  eight explicit environment-limited skips, and zero failures out of 182.
- IAP review asset: App Store Connect accepted
  `AppStore/Screenshots/Review/IAP/FrameWink-Lifetime-review-1242x2688.jpg` as
  the private review screenshot for `FrameWink Lifetime`. It is a metadata-free
  derivative of the current in-app paywall and is not a public product image.
