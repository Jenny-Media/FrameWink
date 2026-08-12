# Monetization implementation brief

## Product

- Type: non-consumable In-App Purchase.
- Working reference name: `Wall Mode Lifetime`.
- Planned US price: $9.99.
- Proposed identifier: `media.jenny.FrameWink.wallmode`.
- Confirm the identifier before creating the immutable product in App Store
  Connect.
- Enable Family Sharing if the final App Store Connect configuration supports
  the intended household behavior.

## Paywall timing

Show the upgrade after the user has:

1. Seen bundled Sample Mode, or
2. Generated and watched a personal Smart Reel.

The paywall should describe the ongoing wall job:

- Unlimited photos and selected albums.
- Automatic refresh.
- Long-term repeat avoidance.
- More layouts.
- Dimming/blackout schedules.
- Wall and Guided Access setup assistance.

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
