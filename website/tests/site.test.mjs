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
  const [home, privacy, support] = await Promise.all([
    source("app/page.tsx"),
    source("app/privacy/page.tsx"),
    source("app/support/page.tsx"),
  ]);

  assert.match(home, /No account/);
  assert.match(home, /No tracking/);
  assert.match(home, /On-device curation/);
  assert.match(home, /up to 500 candidates/i);
  assert.match(home, /up to 100 recommendations/i);
  assert.match(home, /\$9\.99/);
  assert.match(home, /iPhone and iPad only/i);
  assert.match(privacy, /never edits\s+your Photos library/i);
  assert.match(privacy, /Delete Imported Photos/);
  assert.match(support, /iOS or iPadOS 15 or later/);
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
