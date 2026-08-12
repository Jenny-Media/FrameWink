# Codex task — Milestone 3

Read `AGENTS.md` and every file in `docs/`. Inspect existing source and tests.

Implement Milestone 3, Smart Reel curation, only. Use Apple frameworks and no
custom Core ML model.

Build a deterministic, cancellable pipeline that:

1. Applies high-confidence filters when metadata is available.
2. Calculates bounded thumbnail sharpness, exposure, and contrast signals.
3. Groups bursts/time-near captures.
4. Uses Vision feature prints for near-duplicate comparison within bounded
   buckets rather than all-pairs library comparison.
5. Uses public Vision face-capture quality and attention saliency where useful.
6. Promotes date/event diversity and a mix of recent and older photos.
7. Includes layout fitness in final ranking.
8. Selects a 30-photo reel from up to 100 free candidates.
9. Presents Review Suggestions before unattended display.
10. Applies a persistent `Never Show Again` hard veto.
11. Versions persisted signals so algorithm changes invalidate safely.

Add fixture-driven tests for duplicate suppression, deterministic ranking,
exclusions, date diversity, cancellation, and corrupted/disposable caches.

Measure time and peak memory on Simulator, while clearly identifying what must
be repeated on the oldest physical iPad. Do not add a custom model or access
private Photos intelligence.

Run build/tests and update `docs/PLAN.md` with actual time, results, and risks.
