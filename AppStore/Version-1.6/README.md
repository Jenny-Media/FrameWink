# Version 1.6 native iPhone Duo release candidate

Version 1.6 uses Xcode 27.1 RC (27A9275), SDK 24A94232 and native reserved-region
geometry. It remains an iOS/iPadOS 15 universal iPhone/iPad app with the existing
private, on-device behavior and Lifetime purchase. Preserve manual release
after approval and the website's upcoming-preview wording until public release.

The six Duo screenshots under `Screenshots/iPhone-Duo` are the owner-approved
v5 designs. They were uploaded, processed and reload-verified in order on
October 7. `ContactSheet-iPhone-Duo.jpg` previews the complete gallery.
The six inherited iPhone and seven iPad gallery images are retained.

Authentic RC captures and generated empty-room backgrounds are retained under
`CaptureSources/iPhone-Duo`. The manifest records source hashes and toolchain,
and `APPROVED_SHA256SUMS` locks the six approved output bytes. App UI and original
Apple hardware are composed after room generation; the wood rails deliberately
cover the bottom edge on cards 1/4. Standalone Apple resources remain outside Git.

Regenerate to a separate output directory first, then compare approved hashes:

```sh
FRAMEWINK_DUO_BEZEL_ROOT=/path/to/licensed/PNG \
FRAMEWINK_DUO_OUTPUT_ROOT=/path/to/output \
bash scripts/generate_app_store_iphone_duo_release_screenshots.sh
```

The description, bullet-list What's New and reviewer instructions are saved
in this folder and in ASC. Review-contact values remain private in ASC.
No sign-in is required. Optional routing, App Clip, Game Center and review
attachment fields do not apply to this photo-frame app.

See `docs/TESTING.md` and `docs/PLAN.md` for the remaining native validation,
signed Xcode Cloud build and final readiness audit. Simulator coverage does not
prove physical Duo fold, PhotoKit/iCloud, Mail, purchase, brightness, thermal,
Guided Access or prolonged playback acceptance.
