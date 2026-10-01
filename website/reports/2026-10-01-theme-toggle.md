# Website theme toggle verification — October 1, 2026

One native 44 × 44 px sun/moon button sits at the right of the shared header.
The first visit follows device appearance; clicking selects light or dark and
stores only that preference in this browser. The single control has a changing
accessible action name and a visible keyboard focus ring. Cards, captions,
pricing, footer, and document pages have complete light/dark palettes.

Initialization runs synchronously in the head before the body. The header stays
server rendered; the toggle needs no new dependency or React client boundary.
A single metadata element owned by the initializer avoids React 19 duplicating
browser theme-color during hydration or client navigation. JavaScript-disabled
visitors keep the readable light page and do not see an inert toggle.

## Automated checks

Run in `website/` with Node 24.19.0 on the isolated feature branch:

- `npm test`: 23 passed, zero failures/skips. Includes eight saved preference /
  device appearance combinations, toggle/reload persistence, device changes,
  cross-tab clearing/sync, invalid values, storage denial, and one color meta.
- `npm run lint`: passed, no warnings.
- `npm run build`: passed; homepage, Privacy, Support, and Terms prerendered.
- `npm run start -- --hostname 127.0.0.1 --port 4194`: local production preview.
- Served HTML confirmed the initialization script precedes the body.
- `git diff --check`: passed.

## Rendered browser checks

Chrome tested both themes at 320, 390, 560, 561, 768, 900, 901, 1024, and 1440 px.
Every header had one 44 × 44 px control, no brand/nav collision, and no horizontal
page overflow. At 900 px and below the redundant Features navigation link is
hidden so the existing Privacy/Support/Download controls and toggle fit.

Sampled rendered text across the full homepage passed contrast checks: 95–98
samples per width, minimum 4.64:1 in light and 5.43:1 in dark. Privacy, Support,
and Terms passed dark checks at 320/768/1440 px and light checks at 1440 px.
Expanded homepage FAQ text was checked in both themes. The sampling accounts
for resolved colors, background alpha, and ancestor opacity; it is not a formal
accessibility certification.

Click, Enter, and Space changed the theme once; keyboard focus stayed visible.
A dark choice survived reload and client navigation through all four routes.
Two actual tabs synchronized after a single click in either tab. The browser
had one correctly colored theme meta after hydration and repeated navigation.
No browser console errors, warnings, or framework overlay appeared.

Device appearance changes and blocked-storage fallback were unit tested rather
than simulated through browser settings. Physical iPhone Safari and VoiceOver
still require a manual acceptance check. Native app sources, app test/release
configuration, and the separate Duo candidate were not changed.
