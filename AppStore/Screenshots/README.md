# App Store screenshots

The upload-ready set is in `Submission/iPad-13-inch/`. It contains exactly ten
portrait JPEGs at 2064 x 2752 with no alpha channel, matching Apple's 13-inch
iPad screenshot specification and the App Store Connect maximum of ten images.

Run `scripts/capture_app_store_submission_screenshots.sh` with a booted 13-inch
iPad Simulator to rebuild the set. The script builds and installs FrameWink,
normalizes the Simulator status bar and light appearance, captures every
scenario, and rejects the result unless all ten images have the required format,
dimensions, and alpha status. Set `FRAMEWINK_SIMULATOR_ID` to select a specific
booted device.

Submission order:

1. `01-free-sample.jpg` — Free Sample Photos, no Photos access needed.
2. `02-free-review-grid.jpg` — Free private Smart Reel review.
3. `03-free-frame-mode.jpg` — Free full-screen Frame Mode.
4. `04-paid-wall-mode-purchase.jpg` — Paid price, restore, and free-tier promise.
5. `05-paid-automatic-album.jpg` — Paid local automatic-album setup.
6. `06-paid-frame-controls.jpg` — Paid literal timing choices and Share.
7. `07-paid-mosaic-frame.jpg` — Paid four-photo Mosaic Frame Mode.
8. `08-paid-night-schedule.jpg` — Paid foreground dimming/blackout schedule.
9. `09-paid-commissioning-checklist.jpg` — Paid wall commissioning guidance.
10. `10-paid-wall-mode-features.jpg` — Paid Wall Mode feature overview.

The filename and visible product UI distinguish Free from Paid Wall Mode. These
native app screenshots are valid submission assets without marketing overlays;
caption composition remains optional marketing polish, not a release gate.

Run `scripts/generate_app_store_marketing_screenshots.sh` to turn the current
native iPhone and iPad submission captures into a separate, deterministic
candidate set under `Marketing/`. These cards use short benefit-led headlines,
real FrameWink UI, Jenny Media-owned sample photos, and FrameWink's cream,
coral, sage, teal, gold, and indigo palette. They intentionally borrow only the
common App Store storytelling pattern of one benefit per card plus a large
device view; they do not reuse another app's artwork, copy, iconography, or
device compositions. Keep the native `Submission/` files as the source captures.

Apple references:

- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Upload app previews and screenshots](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/)

## iPad Product Page Optimization candidate

The current screenshot-only treatment is in
`ProductPageOptimization/iPad-13-inch/Final/`. It contains exactly seven
landscape JPEGs at 2752 x 2064 with no alpha. Run
`scripts/generate_app_store_ipad_ppo_screenshots.sh` to rebuild it and the
review contact sheet at
`Review/ContactSheets/iPad-PPO-Bezel-Proposed.jpg`.
Run `scripts/verify_locked_app_store_screenshots.sh` to confirm that the final
files still match the approved iPad, iPhone, and iPhone Duo proof checksum
locks.

Treatment order:

1. Realistically scaled wall use created from the licensed official iPad bezel
   reference and the bundled Yellowstone Falls photo.
2. Realistically integrated table use with the same device and photo sources.
3. One exact full-frame app capture inside Apple's 13-inch iPad Pro bezel.
4. The exact four-photo Mosaic app capture in the same bezel and placement.
5. Album choice with six distinct sample covers.
6. Direct timing controls over a full-frame sample photo.
7. Permission-free sample setup before choosing personal photos.

The generated empty rooms and selected integrated scenes are retained under
`Sources/`. The first two lifestyle images keep their accepted room scale and
exact bundled Yellowstone Falls display. Screenshots 3–7 use a single warm
wall, a restrained sunlight accent on the left, one straight-on device size,
and exact native Simulator captures. The generator places each 2752 x 2064
capture at Apple's original +124,+118 screen opening in the 3000 x 2300
13-inch iPad Pro landscape bezel. It does not tilt, redraw, blur, or apply a
perspective transform to the app UI. The standalone Apple Design Resources
file is not stored in this repository.

## iPhone 6.9-inch Product Page Optimization candidate

The six-image iPhone treatment is in
`ProductPageOptimization/iPhone-6.9-inch/Final/`. Run
`scripts/generate_app_store_iphone_ppo_screenshots.sh` to rebuild it and the
review contact sheet at `Review/ContactSheets/iPhone-PPO-Bezel-Proposed.jpg`.

Treatment order:

1. Close tabletop lifestyle use in portrait orientation.
2. A large straight-on frame view using a bundled photo.
3. Album choice with six distinct sample covers.
4. Closer tabletop lifestyle use in landscape orientation.
5. Native timing controls over a full-screen bundled portrait photo.
6. Permission-free sample setup before choosing personal photos.

The iPad and iPhone product cards use the same wall source and a calibrated
neutral warm-beige treatment. Representative clear-wall samples render at
approximately `#CFB8A2` on both canvases, keeping the later detail cards aligned
with the more muted lifestyle rooms while preserving the left-side sunlight.
The iPhone detail cards use Apple's original 1470 x 3000 iPhone 18 Pro Max
portrait bezel. Their exact native 1320 x 2868 app captures are placed at the
bezel's unchanged +75,+66 screen opening without redrawing or perspective
transforms. The standalone Apple Design Resources file remains outside the
repository.

Selected integration prompts were intentionally short:

- Wall: `Place the provided 13-inch iPad naturally mounted on this wall. Make
  it clearly smaller than the lamp shade and look like a real interior
  photograph.`
- Table: `Place the provided iPad naturally on the table in this room using a
  simple stand. Make it look like a real interior photograph.`

## iPhone Duo proof sources

The non-submission proof source captures are under
`ProductPageOptimization/iPhone-Duo/Sources/`. Run
`scripts/capture_app_store_iphone_duo_proof_screenshots.sh` with Xcode 27.1 and
a booted iPhone Duo Simulator. Set `FRAMEWINK_DUO_DISPLAY=outer` for the
1398 x 2034 outer display or `FRAMEWINK_DUO_DISPLAY=inner` for the 2007 x 2853
inner display after opening the device in Device Hub. The script captures four
exact app states and rejects a powered-off or blank display.

These files are design proofs while App Store Connect upload support remains
unavailable. Final device compositions require Apple's official iPhone Duo
bezel package. Keep that standalone licensed resource outside the repository.
Run `scripts/generate_app_store_iphone_duo_proof_screenshots.sh` after capturing
both display families. It creates one outer-display card and three inner-display
cards with exact app pixels inside Apple's Night Sky closed and open portrait
bezels, plus the review contact sheet at
`Review/ContactSheets/iPhone-Duo-Proof.jpg`. During staged capture, set
`FRAMEWINK_DUO_PROOF_FAMILY=outer` or `inner` to generate only the available
family. The inner lead uses FrameWink's native two-photo stacked layout to show
the larger canvas. The controls proof uses an exact full-screen app render and
copy limited to the visible timing interaction. The generator isolates the
uninterrupted front-device silhouettes and extracts the exact internal screen
openings from Apple's bezel alpha channels. This removes the offset left layers
that read as broken edge fragments while avoiding estimated corner radii.

## Source library

Run `scripts/capture_app_store_screenshots.sh` with a booted iPad Simulator to
rebuild the broader eleven-image source library in `iPad/`. The 1640 x 2360 PNGs
remain useful for design iteration, but the 13-inch set above is the upload set.

The capture path is intentionally Debug-only. It uses project-owned bundled
sample photos, a deterministic local `$4.99` product presentation, and a fake
authorized `Family Favorites` album backed by the same bundled images. It never
opens the system picker, changes Photos permissions, edits Apple Photos, or
grants a production entitlement. Release builds ignore the screenshot launch
environment entirely.

The source library covers:

1. Free first-launch Sample Photos with no permission prompt.
2. Free full-screen Frame Mode with transient controls hidden.
3. Paid Wall Mode capabilities.
4. The one-time `$4.99` purchase and Restore Purchases.
5. Paid progressive automatic-album selection.
6. Paid literal timing choices and scene sharing.
7. Paid foreground-only dimming and blackout schedule.
8. Paid wall commissioning and honest platform-limit guidance.
9. Paid automatic-album suggestion review with Never Show Again.
10. Paid four-photo Mosaic Frame Mode.
11. Free Smart Reel suggestion review with Never Show Again.

Do not upload private tester photos. Both capture paths use only the bundled,
project-owned fixture media.
