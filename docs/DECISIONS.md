# Decision log

Change a decision only with an explicit product reason. Add the replacement and
date; do not silently rewrite historical decisions during implementation.

## D-001 — Compatible older iPads, not every old iPad

- **Decision:** Minimum deployment target is iPadOS 15.
- **Reason:** Supports many useful older iPads while remaining compatible with
  current App Store tooling. iOS/iPadOS 9–14 support would greatly expand test
  and maintenance cost.

## D-002 — One native app, Apple frameworks only for MVP

- **Decision:** SwiftUI plus UIKit, PhotoKit, PhotosUI, Vision, StoreKit 2, and
  Foundation. No production dependency package in the MVP.
- **Reason:** Keeps build, privacy, binary, compatibility, and maintenance risk
  small.

## D-003 — Value before permission

- **Decision:** First launch uses bundled sample photos. PHPicker creates the
  personal preview without broad library authorization.
- **Reason:** Lets users understand the product before a sensitive permission
  request.

## D-004 — Chosen scope before full-library autonomy

- **Decision:** Curation starts from picker-selected photos or an explicitly
  selected album. It does not automatically display an unrestricted library.
- **Reason:** Prevents emotionally unsafe or embarrassing selections and makes
  algorithmic review manageable.

## D-005 — Free Smart Reel, paid Wall Mode

- **Decision:** Free creates one excellent 30-photo reel from up to 100
  candidates. Paid unlocks automatic freshness, scale, schedules, and durable
  wall behavior.
- **Reason:** Free demonstrates the differentiator; paid solves the ongoing
  appliance job.

## D-006 — $9.99 non-consumable unlock

- **Decision:** Plan one $9.99 US lifetime Wall Mode non-consumable rather than a
  subscription or separate paid app.
- **Reason:** Fits a finite local utility, preserves one listing/review history,
  and leaves more support margin than a $3.99–$4.99 unlock.

## D-007 — Heuristics and public Vision before custom ML

- **Decision:** MVP curation uses metadata, conventional image signals, and
  public Vision requests. No custom Core ML model initially.
- **Reason:** The key risk is product selection and UX, not model novelty. A
  custom model is justified only after labelled comparisons demonstrate a gap.

## D-008 — Privacy claim is app-specific

- **Decision:** Say the app never uploads and has no server. Do not state that
  the user's overall Photos library never uses iCloud.
- **Reason:** Apple Photos may download optimized assets from iCloud.

## D-009 — No ambient-light claim

- **Decision:** Use system Auto-Brightness, user controls, and time-based visual
  dimming. Do not access the camera as a light meter.
- **Reason:** Direct ambient lux is unavailable to an ordinary consumer app;
  camera permission and capture would conflict with privacy and reliability.

## D-010 — Guided Access is assisted, not automated

- **Decision:** Provide an OS-aware checklist and status messaging. Do not claim
  one-tap kiosk activation or guaranteed relaunch after reboot.
- **Reason:** Consumer Guided Access is manually started; persistent managed
  Single App Mode requires supervision/MDM.

## D-011 — Open source is a trust choice, not the moat

- **Decision:** Keep the implementation compatible with later public source
  release, but choose a license and trademark policy before publishing.
- **Reason:** Source visibility can substantiate privacy. Demand, UX, curation,
  reliability, support, and App Store convenience—not secret code—drive value.

## D-012 — FrameWink uses the Jenny Media app identity

- **Decision:** Product name `FrameWink`, app identifier
  `media.jenny.FrameWink`, test identifier `media.jenny.FrameWinkTests`, and
  Jenny Media LLC Apple Developer team `5736QK4NZX`.
- **Reason:** These are the owner-confirmed production identity and signing
  values; placeholder identifiers must not reach cloud or release builds.

## D-013 — Xcode Cloud is the release builder

- **Decision:** Xcode Cloud performs the authoritative archive and distributes
  successful builds to TestFlight. Local builds provide development feedback
  but are not the release-upload procedure.
- **Reason:** Keeps signing and distribution reproducible in Jenny Media's
  managed CI/CD path and avoids dependence on one developer Mac.

## D-014 — The app shell is content-first, not mode-first

- **Decision:** The main experience has one prominent next action, at most one
  contextual secondary action, and one `More` menu. `Wall Mode` and `Strict
  Offline` are no longer user-facing modes. The paid product is presented as
  `FrameWink Lifetime`; its automatic album and mounted-iPad capabilities are
  features of the same frame experience. Album choice persists across launch,
  and iCloud-backed album items may download normally through Apple Photos.
- **Reason:** Physical testing showed that mode terminology, eight visible
  controls, a technical offline policy, and a configuration-heavy setup screen
  obscured where to start. A Photos-like choose-then-play path better serves the
  product's simple-frame goal without removing review, privacy, or advanced
  controls.

## D-015 — Frame playback responds to the window without becoming a dashboard

- **Decision:** Keep iPad window resizing supported. FrameWink uses the current
  scene geometry to reflow the current photo into a compact single-photo page,
  an occasional compatible wide pair or adaptive tall stack, or an entitled
  large-window Mosaic.
  Reflow preserves a stable photo anchor, playback state, remaining interval,
  and display history. Frame Mode asks iPadOS to hide system chrome, shows its
  gesture hint only briefly, and uses restrained dissolves plus subtle
  single-photo motion that respects Reduce Motion.
- **Reason:** iPad multitasking is a platform behavior and a useful frame
  capability. A geometry-driven presentation feels native and predictable;
  preserving the current photo avoids treating a resize as navigation or
  forcing the user to prepare photos again.

## D-016 — Automatic albums become playable at ten prepared candidates

- **Decision:** A newly selected automatic album prioritizes a date-spanning
  ten-candidate batch, publishes the curated result immediately, refines it at
  thirty candidates, and replaces it again after the complete album finishes.
  Album selection uses a responsive, Photos-familiar cover grid rather than a
  text-only list. Cover thumbnails load independently and never block album
  metadata from appearing.
- **Reason:** Five candidates can collapse to only a few pages after quality,
  duplicate, and pairing decisions, while thirty makes a user wait longer than
  necessary. Ten provides a credible first frame quickly; the later stages
  preserve curation depth without withholding playback.

## D-017 — Motion and tall stacks stay geometry-driven and restrained

- **Decision:** Single cropped photos use a deterministic Living Photo path
  chosen from face-safe zoom, zoom-out, and subtle pan variants. Motion reaches
  a meaningful endpoint within the slide interval, stops for pause, Reduce
  Motion, multi-photo pages, and interactive resize, and never adds a user
  configuration surface. Automatic page changes dissolve; manual previous and
  next use a small directional transition. Automatic tall layouts retain two
  landscapes in ordinary portrait windows, use three only when the viewport is
  tall enough, and cap exceptionally narrow/tall windows at four with at least
  220 points of height per photo and safe-crop fallback.
- **Reason:** The prior 2.5% centered zoom usually ended after the slide had
  already changed and looked static. Stage Manager can also create much taller
  aspect ratios than a full-screen iPad. Deterministic bounded motion adds life
  without becoming a slideshow-effects panel, while adaptive stacks use those
  unusual windows without producing unreadable postage stamps.
