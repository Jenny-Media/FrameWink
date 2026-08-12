# App Store screenshot drafts

Run `scripts/capture_app_store_screenshots.sh` with a booted iPad Simulator to
rebuild and capture the raw screenshots in `iPad/`.

The capture path is intentionally Debug-only. It uses project-owned bundled
sample photos, a deterministic local `$9.99` product presentation, and a fake
authorized `Family Favorites` album backed by the same bundled images. It never
opens the system picker, changes Photos permissions, edits Apple Photos, or
grants a production entitlement. Release builds ignore the screenshot launch
environment entirely.

The current raw set covers:

1. Free first-launch Sample Photos with no permission prompt.
2. Free full-screen Frame Mode controls.
3. Paid Wall Mode capabilities.
4. The one-time `$9.99` purchase and Restore Purchases.
5. Paid automatic-album refresh and Strict Offline privacy wording.
6. Paid saved frame configurations, including Mosaic.
7. Paid foreground-only dimming and blackout schedule.
8. Paid wall commissioning and honest platform-limit guidance.
9. Paid automatic-album suggestion review with Never Show Again.
10. Paid four-photo Mosaic Frame Mode.
11. Free Smart Reel suggestion review with Never Show Again.

These are source captures for App Store composition. Final submission assets
still need approved caption composition.
