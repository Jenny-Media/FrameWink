# Monetization implementation brief

## Product

- Type: non-consumable In-App Purchase.
- User-facing name: `FrameWink Lifetime`.
- Planned US price: $9.99.
- Confirmed identifier: `media.jenny.FrameWink.wallmode`.
- Family Sharing is enabled for the production non-consumable.
- Local Debug-only identifier: `media.jenny.FrameWink.wallmode.local`.
- The local StoreKit test product also enables Family Sharing so the Debug
  purchase flow matches the production entitlement policy.
- The Release build receives only the confirmed production identifier.

## Paywall timing

Show the upgrade after the user has:

1. Seen bundled Sample Mode, or
2. Generated and watched a personal Smart Reel.

The current paywall may promise the implemented Wall Mode behavior:

- Any explicitly selected supported Photos album, without the free 100-candidate
  input limit.
- Automatic change refresh after a user-initiated PhotoKit authorization flow.
- On-device display history that reduces long-term repeats.
- A four-photo Mosaic layout and a persisted active source/layout/timing
  configuration.
- Dimming/blackout schedules.
- Auto-Lock prevention only during foreground Frame Mode.
- Wall and Guided Access setup assistance.

Automatic sourcing is limited to albums the user explicitly selects. The app
must not imply access to Apple Photos Memories, People identities, private
Featured Photos ranking, or an unrestricted whole-library display feed.

Do not imply that the free curation algorithm is deliberately inferior.

## Entitlement rules

- Entitlement derives from verified StoreKit current transactions.
- Listen continuously for StoreKit transaction updates.
- Finish verified transactions after processing.
- Restore must be visible and idempotent.
- Refund/revocation removes paid-only access without deleting the user's free
  imported reel.
- Offline launch should use the last verified entitlement state while StoreKit
  refreshes, following documented StoreKit behavior.
- StoreKit failure never disables Sample Mode or Free Smart Reel.

## Required StoreKit Test cases

- Successful purchase.
- User cancellation.
- Ask to Buy/pending.
- Interrupted/failed transaction.
- Restore after reinstall.
- Offline launch after verified purchase.
- Refund/revocation.
- Family Sharing entitlement if configured.
- StoreKit unavailable.

## Metrics after launch

Use App Store Connect rather than a third-party analytics SDK. Primary business
metric: D35 proceeds per download.

Review:

- D1, D7, and D35 download-to-paid conversion.
- Proceeds per download.
- Refund rate.
- Support contacts per 100 purchasers.
- Rating/review language about value, compatibility, permission friction, and
  reliability.

Do not lower price based on conversion alone. A lower-price cohort must improve
proceeds per download enough to justify the change.
