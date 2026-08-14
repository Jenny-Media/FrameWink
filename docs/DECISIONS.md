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

## D-018 — Collages earn their space; photo actions use system sharing

- **Decision:** Every multi-photo placement must either use a subject-safe
  full-bleed crop or occupy at least 78% of its tile when fitted. If a Mosaic
  group cannot meet that standard, FrameWink retries with fewer photos and then
  falls back to a single-photo page. Long-pressing an individual displayed
  photo offers Apple's system share sheet for that image. FrameWink does not
  claim a `Show in Photos` action because PhotoKit has no supported public API
  for opening one arbitrary `PHAsset` in the Photos app.
- **Reason:** A collage should feel intentionally composed rather than expose
  large black bands, but subject preservation is more important than forcing a
  layout. System sharing is familiar, available on iPadOS 15, and avoids a
  brittle private Photos deep link.

## D-019 — Frame controls use one direct, anchored panel

- **Decision:** The playback `More` button opens a native Frame Controls
  popover with directly visible display-style and slideshow-speed choices.
  The panel stays open after either choice so a user can make several related
  adjustments, and keeps Share and Exit Frame nearby.
- **Reason:** A cascading menu makes common adjustments require repeated taps
  and hides the current selections. One small anchored panel preserves the
  quiet frame surface while making the useful advanced controls scannable and
  adjustable in a single tap.

## D-020 — The MVP and first release remain iPad-only

- **Decision:** Keep device family 2 and the iPad-focused product contract for
  the MVP and first App Store release. Evaluate an iPhone adaptation after the
  iPad experience and release path are validated; do not silently widen the
  current target.
- **Reason:** FrameWink is positioned around reusing an idle iPad as a mounted
  or tabletop frame. iPhone support would add narrow-screen interaction,
  collage, permission, purchase, screenshot, and device-test work while doing
  little to reduce the remaining iPad release risks. It may still be valuable
  later as a portable frame or companion experience, but that requires its own
  product decision and acceptance matrix.

## D-021 — Automatic albums use progressive PhotoKit browsing

- **Decision:** Publish album names and estimated counts as soon as PhotoKit
  returns collection metadata. Discover cover candidates only for visible or
  nearby tiles, then request bounded local thumbnails before allowing an iCloud
  fallback. Keep PHPicker as the system UI for user-selected individual photos;
  do not substitute it for automatic-album selection.
- **Reason:** PHPicker provides a private, familiar photo-selection interface,
  but it returns the assets a person selected rather than a persistent album
  source that FrameWink can refresh. Eagerly scanning cover candidates for every
  PhotoKit collection delayed the entire custom browser. Separating metadata
  from covers makes the catalog useful first and lets imagery fill in
  progressively without widening access or inventing a private Photos link.

## D-022 — Frame playback has a receding one-tap exit

- **Decision:** When playback controls are visible, include a compact top-right
  close button that exits Frame Mode directly. It follows the existing control
  visibility timer and disappears while the Frame Controls panel is open. Keep
  the labelled Exit Frame action in that panel as the explicit alternative.
- **Reason:** Requiring a user to discover More and then Exit Frame makes the
  most important escape path unnecessarily obscure. A transient top-right
  control is familiar on compact devices, remains quiet during playback, and
  avoids the iPad's top-leading window-control region.

## D-023 — Scene sharing is one action

- **Decision:** Frame Controls exposes exactly one share action. It is labelled
  `Share Photo` for a single-photo scene and `Share Photos` for a multi-photo
  scene, and sends every currently displayed scene photo to Apple's system
  share sheet together. Long-press remains the precise way to share only one
  touched photo from a multi-photo scene.
- **Reason:** Splitting a collage into `Share Featured` and `Other Photos`
  required users to understand an internal hierarchy that is irrelevant to
  sharing. One scene-level action follows the visible composition, while the
  existing photo-level gesture preserves control without adding another
  button.

## D-024 — Presentation is automatic and timing uses literal durations

- **Decision:** FrameWink no longer exposes Fit, Fill, Auto, or Mosaic as user
  choices. The responsive layout engine selects the safe composition for the
  current photos and window. Frame Controls contains only the literal timing
  choices `10s`, `30s`, `1m`, and `5m`, with `30s` selected by default, plus
  one scene-level Share action. The direct top-right close control is the sole
  Frame Mode exit; Exit Frame is removed from the panel. Frame Settings no
  longer duplicates album selection, review, layout, timing, or manual refresh.
  It keeps the optional night schedule behind progressive disclosure, concise
  mounted-iPad guidance, and local data-removal controls. Existing saved source
  and album data are preserved while legacy layout and timing values migrate to
  the supported automatic presentation. This supersedes D-019 and the panel-
  exit portion of D-022.
- **Reason:** Physical use showed that layout names, duplicated settings, and
  subjective timing labels made a simple photo frame feel configurable rather
  than effortless. Literal durations remain easy to compare, while automatic
  responsive composition already has enough context to make the layout choice
  better than a persistent manual override.

## D-025 — Hand-picked collections hold 500 candidates and prepare progressively

- **Decision:** Free individual-photo selection supports a total of 500
  app-controlled display copies across picker sessions. A first Smart Reel is
  generated from ten imported candidates while the remaining import continues;
  later checkpoints refine the result, and the active reel contains up to 100
  recommendations drawn from the full collection. Import remains sequential,
  cancellable, storage-guarded, and bounded for older iPads. Paid automatic
  albums continue to consider their full eligible album. This supersedes only
  the 100-candidate/30-selection limits in D-005.
- **Reason:** One hundred photos is unnecessarily restrictive for a long-lived
  frame and made repeated discovery shallow. A bounded 500-photo collection
  feels substantially broader without pretending PHPicker copies are free in
  storage or memory. Progressive preparation preserves a quick first result,
  while a 100-photo recommendation set provides variety without loading every
  stored photo into playback at once.

## D-026 — Sample Photos use ten sanitized publisher-supplied photographs

- **Decision:** Replace the three generated landscape examples with ten
  publisher-supplied photos: seven landscape and three portrait. Bundle only
  auto-oriented, display-sized JPEG derivatives with embedded metadata removed;
  keep originals outside the repository and unmodified. Test every catalog
  entry for decoding, exact dimensions, uniqueness, and absence of private
  metadata.
- **Reason:** Three photos repeated too quickly and did not demonstrate
  portrait pairing or the breadth of the responsive frame. Ten provides useful
  variety while remaining modest for older 2 GB iPads. JPEG derivatives make
  the complete set smaller than the former three PNGs, and stripping metadata
  prevents GPS, device, creator, and capture details from entering the public
  repository or app bundle.

## D-027 — Duration controls acknowledge the first tap optimistically

- **Decision:** Frame Controls binds duration changes directly to the playback
  coordinator and persistence callback, while keeping only a panel-lifetime
  interaction override so the selected appearance updates in the same tap. Do
  not synchronize a second durable selection state from the parent. Give every
  duration a 48-point touch target, reserve stable checkmark space, and use
  restrained press feedback that respects Reduce Motion. Compact sample
  captions use viewport-aware type and bottom clearance so the setup card does
  not cover them.
- **Reason:** Synchronizing two independent duration values allowed a parent
  redraw to restore the previous appearance between taps, and the old 38-point
  controls were easier to miss. An optimistic visual override acknowledges the
  gesture immediately while the binding remains the source of truth. Stable
  geometry and larger targets make the literal duration choices feel like
  native controls without adding another menu or setting.

## D-028 — Playback and modal controls use native Photos-familiar roles

- **Decision:** The visible playback bar contains direct scene Share,
  pause/play, and More actions. Horizontal swipes remain the primary previous
  and next interaction, with equivalent named VoiceOver actions on every photo.
  Frame Controls contains only a native four-option segmented Photo Duration
  picker in a system Form and a cancellation-position Close action. Dismiss-only
  Photos, Privacy, and review sheets also use leading Close actions; the import
  status is a native modal Form instead of an app-owned blocking card. Home menu
  commands use labels and grouped symbols, local album-cover loading uses quiet
  placeholders while real iCloud work retains progress, and `Never Show Again`
  uses a native destructive control with a five-second durable Undo. This
  supersedes D-023 and D-024 only for Share placement, and D-027 only for the
  custom duration-button presentation; their state and timing behavior remain.
- **Reason:** A direct scene share is more discoverable than hiding it behind
  More, while visible previous/next arrows duplicate the finger-following swipe
  and make the playback surface busier. Native segmented controls, toolbar
  roles, Forms, and loading semantics match familiar Apple interaction and
  accessibility behavior. Undo makes curation mistakes immediately reversible
  without weakening the persisted hard veto after the affordance expires.

## D-029 — FrameWink ships as one universal iPhone and iPad app

- **Decision:** The first release supports device families 1 and 2 with a
  minimum iOS/iPadOS version of 15, superseding D-020. iPad remains the primary
  large-display and mounted-frame experience. Compact iPhone windows prioritize
  one readable photo and use the same private photo sources, curation,
  entitlement, and automatic layout engine. Direct Debug and Release app builds
  query the production lifetime-product identifier through Apple's sandbox or
  production environment; the checked-in `.storekit` fixture retains its
  separate local identifier for the scheme's Test action and isolated StoreKit
  tests; normal Run does not attach it. A missing product can be retried from
  the paywall without relaunching.
- **Reason:** Physical compact-layout testing showed the adaptive interface is
  useful as a portable iPhone frame, and the owner explicitly chose universal
  support. The prior iPhone purchase failure was not a compact-UI limitation:
  the temporary installed Debug build queried a fixture-only identifier without
  an attached StoreKit Test session. Separating isolated tests from direct
  device builds preserves deterministic automation while enabling real sandbox
  product loading on both device families.

## D-030 — Compact portrait crops require comfortable important-content placement

- **Decision:** On a portrait cell with aspect ratio 0.62 or narrower, a Fill
  crop is acceptable only when every combined face/saliency bound retains at
  least a 7% visible edge inset and its center lies within 18% of the cell
  center along each cropped axis. If the source boundary makes that placement
  impossible, use the whole-photo Fit presentation. Keep the decision
  automatic and do not add a crop-position or display-style control. Wider
  layouts retain the established face-safe visibility rule.
- **Reason:** A crop can technically preserve every detected face pixel while
  still leaving a head pinned to, or visually cut by, a narrow iPhone edge.
  Centering sometimes requires pixels that do not exist outside the original
  photo. Whole-photo Fit is the honest fallback: it preserves the photographer's
  composition and avoids asking the user to repair individual scenes.

## D-031 — Compact single photos retain most of their source

- **Decision:** A compact single-photo page may use Fill only when its
  normalized crop retains at least 70% of the original source area. Otherwise
  use whole-photo Fit. Apply this geometry-only gate before relying on Vision,
  so photos without a detected face or saliency rectangle receive the same
  protection. D-030 remains an additional subject-placement requirement for
  narrow portrait crops that pass this source-retention gate. Multi-photo
  composition keeps D-018's separate crop/occupancy policy.
- **Reason:** An ultra-wide moon photo displayed on a portrait iPhone retained
  roughly one quarter of its source, and wide iPhone playback could also cut
  architectural tops from ordinary landscape photos. Visibility tests cannot
  help when Vision returns no useful region. A bounded crop-loss rule is
  deterministic, orientation-independent, and preserves the native Photos-like
  choice to letterbox an incompatible image rather than over-zoom it.

## D-032 — The production icon uses a clean gallery-frame mark

- **Decision:** Replace the ornate scalloped FrameWink icon with the selected
  clean-gallery iteration: a thick ivory frame, coral half-sun, sage and teal
  hills, and one restrained gold wink glint on a midnight-indigo field. Keep
  the generated alternatives and exact prompt under `Design/AppIconIterations/`
  as design history, while shipping only the normalized opaque 1,024-pixel
  master from the asset catalog.
- **Reason:** Side-by-side full-size and 32-pixel review showed the clean frame
  has the clearest silhouette and product hierarchy. It remains recognizable
  at Home Screen size without camera imagery, typography, or fine decoration,
  and it preserves the warm private-frame identity of the previous mark.

## D-033 — The first release supports iPhone and iPad only

- **Decision:** Ship and support FrameWink only on iPhone and iPad. Keep Mac
  Catalyst and Designed for iPhone/iPad on Mac disabled in the Xcode target.
  Keep public Apple-silicon Mac and Apple Vision Pro availability disabled in
  App Store Connect, and keep both corresponding platform-testing options
  disabled for `Jenny Media Internal`. Apple reporting the iOS build as
  technically compatible does not expand the supported platform contract.
- **Reason:** FrameWink's interaction, Photos behavior, window adaptation,
  mounted-display guidance, screenshots, automation, and physical acceptance
  are designed and verified for touch-first iPhone and iPad use. Enabling Mac
  or Vision Pro would create a larger review, QA, accessibility, commerce, and
  support surface without a deliberately designed experience.
