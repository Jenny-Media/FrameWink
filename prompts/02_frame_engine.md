# Codex task — Milestone 2

Read `AGENTS.md` and every file in `docs/`. Inspect the completed prior
milestones and preserve their behavior.

Implement Milestone 2, the Frame engine, only.

Required behavior:

1. Single-photo Fit and Fill.
2. Pair two compatible portrait photos on a landscape display.
3. Use image dimensions and available face/saliency rectangles to avoid unsafe
   crops.
4. Tap/swipe previous and next, pause/resume, and adjustable interval.
5. Stable end-of-reel and replay behavior.
6. Full-screen controls that recede but remain discoverable.
7. Respect Reduce Motion.
8. Respond correctly to screen rotation and size changes.
9. Keep layout choice as a pure, deterministic, unit-testable component.

Add fixture-driven tests for landscape, portrait, panorama, multiple faces,
edge-positioned faces, and paired portraits.

Do not implement smart ranking, purchases, schedules, or later integrations.

Run build/tests, report exact results and unverified real-device behavior, then
update `docs/PLAN.md` with actual time and remaining risks.
