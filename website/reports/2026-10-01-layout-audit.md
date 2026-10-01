# FrameWink page layout audit — October 1, 2026

Audited the published homepage at `frame.jenny.media`, all ten homepage
sections, shared navigation/footer, and the linked Privacy, Support, and Terms
pages. Baseline: main commit `0c1ffa4`. Fixes are isolated on
`codex/website-layout-audit`; native app and image assets are unchanged.

## Findings and fixes

| Finding | Evidence | Change |
| --- | --- | --- |
| Hero caption crowded the iPad | Its box entered the image box by 8 px at 390 px and 13 px at 320 px. An absolutely positioned caption shared a fixed-ratio container with the screenshot. | Put the image and caption in normal flow with a 24 px gap. Reserve the actual image ratio inside the slideshow and remove the extra fixed-height mobile space. |
| iPad pairing caption had almost no separation | Caption box directly touched the image box; only 4 px internal padding separated text. | Give the caption a separate row and 24 px gap. |
| iPhone description ran under the device | At 901 px, fixed minimum text columns extended into the phone image. | Allow columns to shrink and stack the heading/description below 1180 px, while retaining the phone beside them. |
| Steps overflowed just above the phone breakpoint | At 561 px, three narrow cards extended beyond the viewport. Pricing also became unnecessarily narrow. | Stack steps and pricing cards at 700 px and below. |
| Small supporting text was difficult to read | Hero caption and footer legal text were 11.52 px; other screenshot captions were 13.12 px. | Set these supporting text styles to 14 px, retaining clear contrast and hierarchy. |
| Document headings clipped on the smallest phone | At 320 px, Support's heading needed 283 px and Terms' heading needed 289 px inside a 272 px content area. | Use a smaller mobile heading scale and allow unusually long words to wrap. |

The page retains its existing section order, wording, iPad emphasis, App Store
badge, authentic device artwork, and explicitly upcoming Duo preview. No new
UI, tracking, dependencies, or product claims were added.

## Verification

Production browser measurements passed at **320, 375, 390, 430, 560, 561,
640, 700, 701, 768, 900, 901, 960, 1024, 1180, 1181, 1440, and 1920 px**.
Checks included both sides of each relevant layout breakpoint.

- All screenshot captions have a 20–24 px gap, including the narrowest phone.
- No horizontal overflow, clipped text, or iPhone/iPad text/image collisions
  in the measured layouts.
- Privacy, Support, and Terms passed the corrected 320/390 px heading checks;
  their unchanged tablet/desktop layouts were also inspected.
- All four FAQ answers open/close. Enter toggles a focused FAQ and displays
  its focus indicator. The keyboard skip link becomes visible, then moves
  focus to `main-content` when activated.
- Visible navigation and footer links retain 44 px minimum height. App Store
  links target the correct listing; the Jenny Media Apps footer link remains.
- Computed foreground/background contrast checks found no failures for the
  sampled homepage text, including expanded FAQ answers. Image alt text,
  single page headings, list semantics, and Reduce Motion rules remain intact.
- No browser console errors or framework error overlays were found.
- `npm test`: 9 passed, 0 failed, 0 skipped.
- `npm run lint`: passed.
- `npm run build`: passed; all public routes prerendered.

The browser measurements used Chrome through the computer-use interface.
Contrast was calculated from computed colors/opacity over the plain section
backgrounds; this is not a complete assistive-technology conformance audit.
The owner's iPhone Safari should still be checked with its usual page zoom and
larger text settings, and VoiceOver acceptance requires a manual check.
No iOS source, tests, signing, release configuration, or App Store screenshots
changed, so app/device regression gates were not rerun for this CSS update.

One existing source assertion initially failed because it assumed
`text-wrap` had to be the first heading declaration. It now checks for the
same balanced-text behavior regardless of declaration order. The old fixed
figure-ratio assertion was removed because it required the cramped layout.
An initial local preview also rejected a dependency symlink outside its
Turbopack root; copying the existing locked dependencies resolved that local
configuration issue without changing package inputs.

## Saved proof

- [Mobile hero after](layout-audit-2026-10-01/hero-mobile-after.jpg)
- [901 px iPhone section before](layout-audit-2026-10-01/iphone-tablet-before.jpg)
- [901 px iPhone section after](layout-audit-2026-10-01/iphone-tablet-after.jpg)
- [Baseline geometry](layout-audit-2026-10-01/geometry-before.json)
- [Final geometry](layout-audit-2026-10-01/geometry-after.json)

Additional section screenshots, route measurements, and build/test logs are
retained locally under `/private/tmp/framewink-website-audit-20261001/`.
Proof screenshots include the existing licensed Apple device depictions;
do not extract or redistribute standalone Apple artwork from them.
