# Codex task — Milestone 4

Read `AGENTS.md` and every file in `docs/`. Preserve the free reel and curator.

Implement Milestone 4, Wall Mode behavior, without StoreKit gating yet.

Required behavior:

1. Disable the idle timer only while active Frame Mode requires continuous
   display.
2. Restore app-owned display state whenever Frame Mode deactivates.
3. Implement scheduled visual dimming and blackout while foregrounded.
4. Do not promise or fake exact wake after lock/suspension.
5. Add truthful Guided Access-assisted setup and status messaging using only
   public consumer APIs.
6. Add a commissioning checklist covering compatible OS, charging, damaged or
   swollen battery warning, ventilation, heat/sunlight, cable security,
   orientation, Auto-Brightness, Guided Access, and reboot recovery.
7. Persist sufficient session configuration for understandable relaunch.
8. Handle repeated activation, deactivation, foregrounding, and backgrounding
   without duplicate timers or leaked global state.

Add tests with injected clock/schedule behavior. Identify brightness, thermal,
Guided Access, and long-duration behavior requiring real hardware.

Start the seven-day soak-test record in `docs/TESTING.md`. Run build/tests and
update `docs/PLAN.md` with actual time and risks.
