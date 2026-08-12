# Codex task — Milestone 5

Read `AGENTS.md`, `docs/MONETIZATION.md`, and all other project documents.
Inspect the current product flow before editing.

Implement Milestone 5, purchases and the free/paid boundary.

Required behavior:

1. Add a local StoreKit configuration with a non-consumable Wall Mode product.
2. Keep the production identifier configurable and do not invent App Store
   credentials.
3. Use verified StoreKit 2 current transactions as entitlement truth.
4. Listen for transaction updates and finish verified transactions.
5. Handle success, cancellation, pending, failure, restore, offline launch,
   refund/revocation, and StoreKit-unavailable states.
6. Keep Sample Mode and Free Smart Reel usable in every StoreKit failure state.
7. Gate only documented Wall Mode capabilities.
8. Present the paywall after personal value, with accurate free/paid copy.
9. Include a visible Restore Purchases action.
10. Never store entitlement only as a Boolean in UserDefaults.

Use an injected purchase client so business logic is unit-testable. Exercise
the required StoreKit Test scenarios that can be automated or run locally.

Do not add subscriptions, ads, external checkout, accounts, or analytics.

Run build/tests, report StoreKit scenarios performed and outstanding App Store
Connect configuration, then update `docs/PLAN.md`.
