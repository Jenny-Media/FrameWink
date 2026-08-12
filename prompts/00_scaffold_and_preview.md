# Codex task — Milestones 0 and 1

Read `AGENTS.md` and every file in `docs/` before editing.

Implement Milestone 0 and Milestone 1 only.

The result must:

1. Build for an available iPad Simulator with an iPadOS 15 deployment target.
2. Establish the documented source folders and small protocol boundaries.
3. Show a polished sample slideshow immediately on first launch without
   requesting Photos access.
4. Clearly label bundled content as sample photos.
5. Let the user select up to 100 personal photos through PHPicker.
6. Downsample imported images during decode and persist only display-sized app
   copies.
7. Provide import progress, cancellation, understandable failure/retry, and a
   visible `Delete Imported Photos` action.
8. Ensure deletion removes files and all records derived from those imports.
9. Add unit tests for importing, partial failure, cancellation, and deletion.
10. Contain no networking, analytics, account, StoreKit, custom ML, or later
    Wall Mode implementation.

Before editing, inspect the Xcode project and present a concise implementation
plan. After editing:

- Run the appropriate build and tests.
- Report exact commands and results.
- List simulator-only assumptions and real-device checks.
- Update `docs/PLAN.md` with status, actual active-time estimate, build command,
  tests, and risks.

Do not implement later milestones or add dependencies.
