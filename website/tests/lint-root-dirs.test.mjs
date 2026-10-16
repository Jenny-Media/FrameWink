import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createRequire } from "node:module";
import test from "node:test";
import { Linter } from "eslint";
import nextPlugin from "@next/eslint-plugin-next";

const require = createRequire(import.meta.url);
const { getRootDirs } = require("@next/eslint-plugin-next/dist/utils/get-root-dirs.js");

function fixture(t) {
  const root = mkdtempSync(path.join(tmpdir(), "framewink-lint-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  for (const directory of ["website/app", "website/public", "apps/web/app", "apps/blog/pages", "apps/.hidden/app", "other/app"]) {
    mkdirSync(path.join(root, directory), { recursive: true });
  }
  writeFileSync(path.join(root, "apps/readme.txt"), "Not a project directory.");
  writeFileSync(path.join(root, "apps/blog/pages/about.jsx"), "export default function About() { return null; }");
  return root;
}

function canonical(directories) {
  return directories.map((directory) => realpathSync(path.resolve(directory))).sort();
}

test("Next lint finds the intended project roots without expanding their descendants", async (t) => {
  const root = fixture(t);
  const relative = path.relative(process.cwd(), root).replaceAll(path.sep, "/");
  const cases = [
    ["default cwd", undefined, [root]],
    ["relative literal", `${relative}/website`, ["website"]],
    ["absolute literal", path.join(root, "website"), ["website"]],
    ["relative wildcard", `${relative}/apps/*`, ["apps/web", "apps/blog"]],
    ["absolute wildcard", path.join(root, "apps/*"), ["apps/web", "apps/blog"]],
    ["literal array", [`${relative}/website`, `${relative}/other`], ["website", "other"]],
    ["mixed array", [`${relative}/website`, `${relative}/apps/*`, null], ["website", "apps/web", "apps/blog"]],
    ["brace roots", `${relative}/{website,other}`, ["website", "other"]],
    ["extglob roots", `${relative}/@(website|other)`, ["website", "other"]],
    ["backslash paths", `${relative}/apps/*`.replaceAll("/", "\\"), ["apps/web", "apps/blog"]],
    ["missing directory", `${relative}/missing`, []],
    ["files excluded", `${relative}/apps/readme.txt`, []],
  ];
  for (const [name, rootDir, expected] of cases) {
    await t.test(name, () => {
      const actual = getRootDirs({ cwd: root, settings: { next: { rootDir } } });
      const wanted = rootDir === undefined ? expected : expected.map((directory) => path.join(root, directory));
      assert.deepEqual(canonical(actual), canonical(wanted));
    });
  }
});

test("Next's link rule still discovers pages through configured project globs", (t) => {
  const root = fixture(t);
  const messages = new Linter().verify(
    'export default function Card() { return <a href="/about">About</a>; }',
    [{
      files: ["**/*.jsx"],
      languageOptions: { parserOptions: { ecmaFeatures: { jsx: true } } },
      plugins: { next: nextPlugin },
      settings: { next: { rootDir: path.join(root, "apps/*") } },
      rules: { "next/no-html-link-for-pages": "error" },
    }],
    { filename: "card.jsx" },
  );
  assert.ok(messages.some((message) => message.ruleId === "next/no-html-link-for-pages"), JSON.stringify(messages));
});

test("Next's image lint rule remains enabled and usable", () => {
  const messages = new Linter().verify(
    'export default function Card() { return <img src="/photo.jpg" alt="Photo" />; }',
    [{
      files: ["**/*.jsx"],
      languageOptions: { parserOptions: { ecmaFeatures: { jsx: true } } },
      plugins: { next: nextPlugin },
      rules: { "next/no-img-element": "error" },
    }],
    { filename: "card.jsx" },
  );
  assert.ok(messages.some((message) => message.ruleId === "next/no-img-element"), JSON.stringify(messages));
});
