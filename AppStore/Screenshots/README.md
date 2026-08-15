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
