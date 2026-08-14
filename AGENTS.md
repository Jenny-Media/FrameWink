# Product contract

This repository contains a universal iPhone and iPad application that turns a
compatible Apple device into a private, local digital photo frame. It remains
iPad-first for mounted and tabletop use while supporting a compact portable
iPhone experience.

The central promise is:

> Effortless smart highlights from photos you choose.

Before editing, read all files in `docs/`. Treat `docs/PRODUCT.md`,
`docs/DECISIONS.md`, and this file as authoritative. Track execution in
`docs/PLAN.md`.

## Non-negotiable product rules

- Minimum deployment target is iOS/iPadOS 15.
- The first release supports iPhone and iPad only. Keep Mac Catalyst,
  Apple-silicon Mac distribution/testing, and Apple Vision Pro
  distribution/testing disabled unless a later milestone explicitly adds and
  verifies one of those platforms.
- Photos and analysis remain on-device.
- The app has no developer server, account, ads, analytics SDK, or tracking.
- Do not request Photos permission during first launch.
- First launch demonstrates the product using clearly labelled bundled sample
  photos.
- Personal Preview uses PHPicker and does not require full-library access.
- Request full PhotoKit access only when a user explicitly enables automatic
  album updates.
- Never claim access to Apple Photos Memories, Featured Photos, People
  identities, or Apple's private ranking.
- Never claim direct ambient-light sensing.
- Describe Guided Access as assisted manual setup.
- Never promise automatic relaunch or recovery after a device restart.
- Never delete, edit, favorite, hide, or otherwise mutate the user's Photos
  library.
- Hidden photos and screenshots must not be selected automatically.
- Provide review-before-display and `Never Show Again` controls.
- Avoid autonomous whole-library display by default. Begin with photos or an
  album the user chose.

## Free and paid boundary

### Free Smart Reel

- Clearly labelled bundled sample experience with no permission prompt.
- Import up to 500 candidates through PHPicker, enforced across sessions.
- Generate one local Smart Reel with up to 100 recommendations.
- Include real curation, near-duplicate suppression, face-safe cropping,
  portrait pairing, fit/fill, tap/swipe navigation, adjustable timing, pause,
  `Never Show Again`, and unlimited replay.
- No watermark, advertisements, account, or forced trial countdown.

### Paid Wall Mode

- One non-consumable lifetime unlock. Planned US launch price: $9.99.
- Unlimited candidate pool and supported albums.
- Automatic album refresh after explicit PhotoKit authorization.
- Continuously regenerated recommendations and long-term repeat avoidance.
- Additional automatic layouts when the current geometry can use them well.
- Dimming and blackout schedules.
- Mounted-display guidance and Guided Access assistant.
- Family Sharing where StoreKit configuration supports it.

## MVP engineering constraints

- Use SwiftUI, UIKit, PhotoKit, PhotosUI, Vision, StoreKit 2, and Foundation.
- Do not add third-party production dependencies without explicit approval.
- Do not add a custom Core ML model during the MVP.
- Prefer APIs available on iOS/iPadOS 15. Guard newer Vision improvements behind
  availability checks.
- Prefer `ObservableObject` and `@StateObject` for iOS/iPadOS 15 compatibility.
- Do not introduce SwiftData for MVP persistence.
- Analyze bounded thumbnails rather than full-resolution originals.
- Keep caches bounded and memory-safe for 2 GB iPads.
- Use simple Codable/file persistence for settings, scores, exclusions, and
  display history.
- Imported picker photos must have an obvious `Delete Imported Photos` action.
- Do not use background audio, location, camera capture, or other execution
  workarounds to keep the app alive.
- Do not add background modes unless the platform-documented use exactly
  matches the feature.
- Do not manipulate project signing, bundle identifiers, production StoreKit
  identifiers, or App Store credentials without explicit direction.
- Put unexpected feature requests in `docs/BACKLOG.md` instead of expanding
  the active milestone.

## Architecture expectations

- Separate photo sources, curation, layout, display behavior, persistence, and
  purchase state behind small protocols.
- The curator must accept a common `PhotoCandidate` abstraction so PHPicker
  imports and PhotoKit assets share the same ranking pipeline.
- Keep ranking deterministic for a fixed input, algorithm version, and seed so
  unit tests are reproducible.
- Keep view bodies declarative. Put PhotoKit, Vision, disk I/O, StoreKit, and
  scheduling behavior outside SwiftUI views.
- Keep all user-visible strings ready for localization.
- Use accessibility labels and respect Reduce Motion.

## Verification

After each milestone:

- Discover available iPhone and iPad Simulator destinations and build the
  application and affected tests with `xcodebuild` on both device families.
- Run all affected unit tests.
- Report the exact commands, result, warnings, untested behavior, and real-device
  checks still required.
- Update `docs/PLAN.md` with status, completed work, active-time estimate, and
  known risks.
- Do not mark a milestone complete while acceptance criteria are failing.
- Preserve unrelated user changes.

For behavior that cannot be proven in Simulator, state the required real-device
test explicitly. Do not silently substitute simulator results for PhotoKit,
brightness, thermal, Guided Access, purchase, or long-running device behavior.
