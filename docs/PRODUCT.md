# Product specification

## Working concept

A premium, local-first iPad application that turns compatible older iPads into
easy-to-use digital photo frames. The product should feel native and familiar,
while retaining its own identity rather than copying Apple Photos.

## Positioning

> Automatically turn a compatible older iPad into a safe, curated wall display.

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
- Smart curation wins the first five minutes; reliable Wall Mode earns the
  purchase.
- Start from photos the user chose, not an unrestricted whole library.
- Make algorithmic mistakes easy to review and reverse.
- Prefer a small number of excellent defaults over a settings dashboard.
- State platform limitations honestly.
- Keep the app useful without network access.

## First-run journey

1. `See a Sample` displays bundled photos without requesting permission.
2. `Make My Smart Reel` opens PHPicker for up to 100 candidates.
3. The app imports display-sized local copies and shows progress.
4. The curator generates 30 suggestions.
5. A review grid lets the user remove unwanted selections.
6. Frame playback begins with tap/swipe, pause, interval, and layout controls.
7. The Wall Mode upgrade is offered after the user has seen personal value.
8. Full PhotoKit authorization is requested only if the user chooses an
   automatically updating album after purchase.

## Free Smart Reel

- Bundled sample mode.
- Up to 100 picker-selected candidate photos.
- One 30-photo locally persisted reel.
- Full-quality curation rather than a deliberately degraded algorithm.
- Near-duplicate suppression.
- Face- and saliency-aware layout.
- Two compatible portraits paired on a landscape display.
- Fit and Fill.
- Adjustable interval, tap/swipe previous and next, pause, and replay.
- Review Suggestions and Never Show Again.
- Delete Imported Photos.

## Paid Wall Mode

- Unlimited supported candidates and albums.
- Automatic refresh as a selected PhotoKit album changes.
- Multiple reels/configurations.
- Continuous regeneration and long-term repeat avoidance.
- Additional layouts.
- Dimming and blackout schedules while the app remains active.
- Guided Access-assisted setup and wall commissioning checklist.
- Purchase restoration and Family Sharing where supported.

## Privacy wording

Preferred claim:

> The app has no server and never uploads your photos. Selection, analysis, and
> display happen on this iPad.

Do not claim that Apple Photos itself is always offline. If iCloud Photos and
Optimize Storage are enabled, Apple Photos may need to download an asset. A
strict-offline mode may skip unavailable cloud-only assets.

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
- One $9.99 non-consumable Wall Mode unlock.
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
