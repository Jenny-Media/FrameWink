import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const root = new URL("../", import.meta.url);

async function source(path) {
  return readFile(new URL(path, root), "utf8");
}

test("publishes every required public route", async () => {
  await Promise.all([
    access(new URL("app/page.tsx", root)),
    access(new URL("app/privacy/page.tsx", root)),
    access(new URL("app/support/page.tsx", root)),
    access(new URL("app/terms/page.tsx", root)),
    access(new URL("app/robots.ts", root)),
    access(new URL("app/sitemap.ts", root)),
  ]);
});

test("keeps product promises aligned with the app contract", async () => {
  const [home, privacy, support, terms] = await Promise.all([
    source("app/page.tsx"),
    source("app/privacy/page.tsx"),
    source("app/support/page.tsx"),
    source("app/terms/page.tsx"),
  ]);

  assert.match(home, /No account/);
  assert.match(home, /No tracking/);
  assert.match(home, /Processed on your device/);
  assert.match(home, /up to 500 photos/i);
  assert.match(home, /up to 100 highlights/i);
  assert.match(home, /\$4\.99/);
  assert.match(home, /iPhone and iPad only/i);
  assert.match(privacy, /never edits\s+your Photos library/i);
  assert.match(privacy, /Delete Imported Photos/);
  assert.match(support, /iOS or iPadOS 15 or later/);
  assert.match(terms, /\$4\.99 non-consumable/i);
});

test("keeps keyboard, touch, and metadata affordances explicit", async () => {
  const [home, chrome, styles, layout, privacy, routeMetadata] = await Promise.all([
    source("app/page.tsx"),
    source("app/components/SiteChrome.tsx"),
    source("app/globals.css"),
    source("app/layout.tsx"),
    source("app/privacy/page.tsx"),
    source("app/siteMetadata.ts"),
  ]);

  assert.match(home, /id="main-content" tabIndex=\{-1\}/);
  assert.match(home, /id="features"[^>]+tabIndex=\{-1\}/);
  assert.match(home, /id="availability"[^>]+tabIndex=\{-1\}/);
  assert.match(home, /application\/ld\+json/);
  assert.match(home, /placeholder="blur"/);
  assert.match(home, /className="faq-icon" aria-hidden="true"/);
  assert.match(home, /role="listitem"/);
  assert.match(chrome, /aria-current=/);
  assert.match(chrome, /className="review-pill" href="\/#availability"/);
  assert.match(styles, /min-height: 44px/);
  assert.match(styles, /prefers-reduced-motion/);
  assert.doesNotMatch(styles, /infinite/);
  assert.match(styles, /#availability:focus-visible/);
  assert.match(layout, /alternates: \{ canonical: "\/" \}/);
  assert.match(privacy, /pageMetadata\(/);
  assert.match(routeMetadata, /images: \[\]/);
  assert.match(routeMetadata, /card: "summary"/);
  assert.doesNotMatch(routeMetadata, /og\.png/);
});

test("describes the paid album boundary and foreground behavior precisely", async () => {
  const [home, terms] = await Promise.all([
    source("app/page.tsx"),
    source("app/terms/page.tsx"),
  ]);

  assert.match(home, /one supported Photos album/i);
  assert.match(home, /night schedules while FrameWink is open/i);
  assert.doesNotMatch(home, /removes the import cap|No import cap/i);
  assert.doesNotMatch(terms, /candidates|recommendations/i);
});

test("ships without analytics, advertising, or starter preview code", async () => {
  const [packageJson, home, layout] = await Promise.all([
    source("package.json"),
    source("app/page.tsx"),
    source("app/layout.tsx"),
  ]);
  const combined = `${packageJson}\n${home}\n${layout}`;

  assert.doesNotMatch(combined, /google-analytics|segment|mixpanel|posthog|sentry/i);
  assert.doesNotMatch(combined, /codex-preview|SkeletonPreview|react-loading-skeleton/);
});

test("uses the intended public domain and support address", async () => {
  const [layout, robots, sitemap, privacy] = await Promise.all([
    source("app/layout.tsx"),
    source("app/robots.ts"),
    source("app/sitemap.ts"),
    source("app/privacy/page.tsx"),
  ]);
  const combined = `${layout}\n${robots}\n${sitemap}\n${privacy}`;

  assert.match(combined, /https:\/\/frame\.jenny\.media/);
  assert.match(combined, /framewink@jenny\.media/);
});

test("shows authentic native captures in a realistic product scene", async () => {
  const [home, styles, landscapeGenerator, portraitGenerator] = await Promise.all([
    source("app/page.tsx"),
    source("app/globals.css"),
    source("../scripts/generate_landscape_marketing_assets.sh"),
    source("../scripts/generate_app_store_marketing_screenshots.sh"),
  ]);

  assert.match(home, /hero-lifestyle-frame-v5\.webp/);
  assert.match(home, /hero-lifestyle-mosaic-v5\.webp/);
  assert.match(home, /ipad-landscape-mosaic-clean-v2\.webp/);
  assert.match(home, /ipad-landscape-controls-v3\.webp/);
  assert.match(home, /actual landscape app screen/);
  assert.match(home, /Works on iPhone too\./);
  assert.match(home, /The same private reel, adapted for a smaller screen\./);
  assert.match(home, /From your photos to a frame in a few taps\./);
  assert.doesNotMatch(home, /From camera roll to frame in minutes\./);
  assert.doesNotMatch(home, /hero-lifestyle-(?:frame|mosaic)-v4\.webp/);
  assert.doesNotMatch(home, /ipad-landscape-(?:mosaic-clean|controls)\.webp/);
  assert.doesNotMatch(home, /steps\.map\(\(\[title, body\], index\)/);
  assert.match(home, /className="step-symbol"/);
  assert.doesNotMatch(home, /iphone-portrait-[^"']+\.webp/);
  assert.doesNotMatch(home, /ipad-room-frame|generic tablet/i);
  assert.match(landscapeGenerator, /ACTUAL IN-APP SCREEN/);
  assert.doesNotMatch(landscapeGenerator, /room_base|prefix-(?:device|shell)|-strokewidth/);
  assert.doesNotMatch(portraitGenerator, /-bordercolor|-border 2/);
  assert.doesNotMatch(styles, /\.landscape-shot\s*\{[^}]*border:/s);
  assert.match(styles, /\.iphone-note\s*\{[^}]*grid-template-columns:\s*auto/s);
  assert.match(styles, /\.iphone-note\s*\{[^}]*padding-block:\s*30px/s);
  assert.doesNotMatch(styles, /\.iphone-screen-pair/);
  assert.match(styles, /\.feature-card h3\s*\{[^}]*margin:\s*58px 0 18px;/s);
  assert.doesNotMatch(styles, /\.feature-card h3\s*\{[^}]*margin:\s*116px/s);
});
