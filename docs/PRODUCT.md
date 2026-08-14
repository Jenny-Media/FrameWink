# Product specification

## Working concept

A premium, local-first iPad application that turns compatible older iPads into
easy-to-use digital photo frames. The product should feel native and familiar,
while retaining its own identity rather than copying Apple Photos.

## Positioning

> Turn a compatible older iPad into a private, beautifully curated photo frame.

Supporting message:

> Your best digital frame may already be in your drawer.

## Primary customer

An Apple household that already owns a working, compatible, unused iPad and
wants to display its own local or Apple Photos library. The customer values
simple setup, privacy, no recurring charge, good use of portrait photos, and
predictable wall-display behavior.

## Anti-persona

The product is not primarily for someone buying a gift for a remote relative.
Aura, Skylight, and similar hardware products better serve remote uploads,
preloaded gifts, family contributions, and remote administration.

## Customer jobs

1. See a convincing result before granting broad Photos access.
2. Select a bounded set or album without learning photo-frame terminology.
3. Avoid duplicates, screenshots, blurred captures, and awkward crops.
4. Rediscover attractive photos across different dates and events.
5. Use portrait photos gracefully on a landscape iPad.
6. Install the iPad as a mostly unattended display.
7. Understand exactly what happens to private photos.

## Product principles

- Demonstrate value before asking for permission or payment.
- Smart curation wins the first five minutes; dependable automatic albums and
  display behavior earn the purchase.
- Start from photos the user chose, not an unrestricted whole library.
- Make algorithmic mistakes easy to review and reverse.
- Prefer a small number of excellent defaults over a settings dashboard.
- State platform limitations honestly.
- Keep picker-selected frames useful without network access, while allowing
  Apple Photos to fetch iCloud-backed album items when needed.

## First-run journey

1. Bundled sample photos appear immediately without a Photos prompt.
2. One prominent `Choose Photos` action opens PHPicker for up to 500 candidates;
   `Start Sample Frame` remains available as the secondary action.
3. The app imports display-sized local copies, curates them, and changes the
   primary action to `Start Frame`.
4. Frame playback begins directly. Share, pause/play, and `More` provide the
   visible controls, while a horizontal swipe follows the finger to move to the
   previous or next scene. VoiceOver exposes equivalent named previous and next
   actions on each displayed photo. `More` opens one compact native Frame
   Controls panel with one selected photo duration. FrameWink chooses the layout
   automatically, while a receding top-right close button exits Frame Mode
   directly. A short tap/swipe hint recedes with the controls; tapping the photo
   brings controls back.
5. Review, deletion, privacy, source switching, and frame settings remain
   available through progressive disclosure rather than a button dashboard.
6. FrameWink Lifetime is offered when a user chooses an automatic album or
   another paid frame feature.
7. Full PhotoKit authorization is requested only after the user explicitly
   chooses an automatic album.

## Free Smart Reel

- Bundled sample mode.
- Up to 500 picker-selected candidate photos, enforced across import sessions.
- One locally persisted Smart Reel with up to 100 recommendations.
- Progressive preparation that makes an initial result available from ten
  imported candidates while the rest continue in the foreground.
- Full-quality curation rather than a deliberately degraded algorithm.
- Near-duplicate suppression.
- Face- and saliency-aware layout.
- Two compatible portraits paired on a landscape display.
- Responsive compact single-photo playback, occasional wide pairs, and
  geometry-driven two-to-four-photo tall stacks where each photo remains large.
- Automatic face-safe Fit/Fill decisions without a display-style setting.
- A selected 30-second default with direct 10-second, 30-second, 1-minute, and
  5-minute choices, plus swipe navigation, pause, direct scene sharing, and
  unlimited replay.
- Restrained dissolve/directional transitions and subtle face-safe zoom/pan
  motion with Reduce Motion support.
- Review Suggestions and Never Show Again.
- Delete Imported Photos.

## FrameWink Lifetime

- Unlimited supported candidates and albums.
- Automatic refresh as a selected PhotoKit album changes.
- One clear active source/timing state that updates in place.
- Continuous regeneration and long-term repeat avoidance.
- Additional automatic layouts, including occasional event-bound Mosaic
  composition on a sufficiently large window.
- Dimming and blackout schedules while the app remains active.
- Concise mounted-iPad and Guided Access guidance.
- Purchase restoration and Family Sharing where supported.

## Privacy wording

Preferred claim:

> The app has no server and never uploads your photos. Selection, analysis, and
> display happen on this iPad.

Do not claim that Apple Photos itself is always offline. If iCloud Photos and
Optimize Storage are enabled, Apple Photos may need to download an asset for an
automatic album. This normal Apple Photos behavior is explained contextually,
not exposed as a persistent technical mode.

## Truthful platform boundaries

- A consumer App Store app cannot read ambient-light lux through an ordinary
  public API. Use system Auto-Brightness, user brightness, and schedules.
- Consumer Guided Access is started manually. The app provides instructions and
  can adapt when Guided Access is active.
- A normal app cannot guarantee automatic relaunch after reboot or power loss.
- Scheduled blackout can visually darken the foreground app. If the device is
  locked or the process is suspended, the app cannot guarantee an exact wake.
- Apple Photos' private Featured Photos, Memories, People identities, and
  personal-significance scores are not available through public PhotoKit.

## MVP non-goals

- Remote family uploads or administration.
- Accounts, servers, or developer-controlled cloud sync.
- NAS, SMB, WebDAV, Nextcloud, Immich, or external-drive sources.
- Weather, music, calendars, widgets, Apple TV, or Home Assistant.
- Video and Live Photos.
- Face identity or named-person clustering.
- Custom-trained aesthetic model.
- Camera-based light sensing.
- Managed-device/MDM automation.
- Mount sales or hardware bundles.
- Support for iOS/iPadOS versions below 15.

## Commercial model

- One App Store listing.
- Free Smart Reel preview.
- One $9.99 non-consumable FrameWink Lifetime unlock.
- No subscription, advertising, account, or tip jar in MVP.
- Evaluate pricing using D35 proceeds per download, not conversion alone.

## Product validation gates

- At least 14 of 20 target testers complete setup in under five minutes.
- At least 14 of 20 prefer the output/setup to Apple Photos or a named direct
  competitor.
- At least 12 of 20 dedicate the device for seven days.
- At least 95% of tested devices complete a seven-day run without recovery.
- After 1,000 activated downloads, target at least 4% D35 paid conversion.
- Below 2% after one onboarding/paywall iteration is a stop or maintenance-mode
  signal.
