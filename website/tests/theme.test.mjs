import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { runInNewContext } from "node:vm";
import { themeInitialization } from "../app/theme.js";

function visit({ saved = null, dark = false, blocked = false } = {}) {
  const documentEvents = new Map();
  const windowEvents = new Map();
  const systemEvents = new Map();
  const root = { dataset: {} };
  const storage = new Map(saved === null ? [] : [["framewink-theme", saved]]);
  let themeColor;
  let colorMeta;
  let metaCount = 0;
  class Element {
    constructor(action = null) { this.action = action; }
    closest(selector) { return selector === this.action ? this : null; }
  }
  const system = {
    matches: dark,
    addEventListener: (name, listener) => systemEvents.set(name, listener),
  };
  runInNewContext(themeInitialization, {
    Element,
    document: {
      documentElement: root,
      getElementById: () => colorMeta,
      createElement: () => ({ setAttribute: (_name, value) => { themeColor = value; } }),
      head: { appendChild(meta) { colorMeta = meta; metaCount += 1; } },
      addEventListener: (name, listener) => documentEvents.set(name, listener),
    },
    window: {
      matchMedia: () => system,
      localStorage: {
        getItem(key) { if (blocked) throw new Error("Storage denied"); return storage.get(key) ?? null; },
        setItem(key, value) { if (blocked) throw new Error("Storage denied"); storage.set(key, value); },
        removeItem(key) { if (blocked) throw new Error("Storage denied"); storage.delete(key); },
      },
      addEventListener: (name, listener) => windowEvents.set(name, listener),
    },
  });
  return {
    theme: () => root.dataset.theme,
    color: () => themeColor,
    metaCount: () => metaCount,
    saved: () => storage.get("framewink-theme"),
    click: (toggle = true) => documentEvents.get("click")({ target: new Element(toggle ? "[data-theme-toggle]" : null) }),
    reset: () => documentEvents.get("click")({ target: new Element("[data-theme-reset]") }),
    systemChange(dark) { system.matches = dark; systemEvents.get("change")(); },
    storageChange(value, key = "framewink-theme") { windowEvents.get("storage")({ key, newValue: value }); },
  };
}

for (const saved of [null, "system", "light", "dark"]) {
  for (const dark of [false, true]) {
    test(`first paint: saved=${saved}, system=${dark ? "dark" : "light"}`, () => {
      const page = visit({ saved, dark });
      const expected = saved === "light" || saved === "dark" ? saved : dark ? "dark" : "light";
      assert.equal(page.theme(), expected);
      assert.equal(page.color(), expected === "dark" ? "#101626" : "#fffdf7");
    });
  }
}

test("one click switches appearance and the saved choice survives a new visit", () => {
  const page = visit();
  page.click();
  assert.equal(page.theme(), "dark");
  assert.equal(visit({ saved: page.saved() }).theme(), "dark");
  page.click();
  assert.equal(page.theme(), "light");
  assert.equal(page.saved(), "light");
  page.click(false);
  assert.equal(page.theme(), "light", "other page controls must not change appearance");
  assert.equal(page.metaCount(), 1, "theme changes must reuse a single browser-color meta element");
});

test("follows device changes until the visitor chooses a theme", () => {
  const page = visit();
  page.systemChange(true);
  assert.equal(page.theme(), "dark");
  page.click();
  page.systemChange(false);
  page.systemChange(true);
  assert.equal(page.theme(), "light");
});

test("synchronizes other tabs and returns to device appearance when the choice is cleared", () => {
  const page = visit({ dark: true });
  page.storageChange("light");
  assert.equal(page.theme(), "light");
  page.storageChange("dark", "unrelated-key");
  assert.equal(page.theme(), "light");
  page.storageChange(null, null);
  assert.equal(page.theme(), "dark");
  page.systemChange(false);
  assert.equal(page.theme(), "light");
});

test("blocked storage keeps the toggle working and retains this visit's choice", () => {
  const page = visit({ blocked: true, dark: true });
  assert.equal(page.theme(), "dark");
  page.click();
  assert.equal(page.theme(), "light");
  page.systemChange(true);
  assert.equal(page.theme(), "light");
  page.click();
  assert.equal(page.theme(), "dark");
});

test("invalid saved values fall back to device appearance", () => {
  const page = visit({ saved: "unexpected", dark: true });
  assert.equal(page.theme(), "dark");
  page.storageChange("unexpected");
  assert.equal(page.theme(), "dark");
});

test("appearance setup precedes the body and remains separate from React hydration", async () => {
  const layout = await readFile(new URL("../app/layout.tsx", import.meta.url), "utf8");
  assert.ok(layout.indexOf('id="theme-init"') < layout.indexOf("<body>"));
  assert.match(layout, /<html lang="en" suppressHydrationWarning>/);
  assert.doesNotMatch(themeInitialization, /document\.body|innerHTML/);
});

for (const dark of [false, true]) {
  test(`system reset clears an override and follows ${dark ? "dark" : "light"} device appearance`, () => {
    const page = visit({ saved: dark ? "light" : "dark", dark });
    page.reset();
    assert.equal(page.theme(), dark ? "dark" : "light");
    assert.equal(page.saved(), undefined);
    assert.equal(visit({ saved: page.saved(), dark }).theme(), dark ? "dark" : "light");
    page.systemChange(!dark);
    assert.equal(page.theme(), dark ? "light" : "dark");
    page.reset();
    assert.equal(page.metaCount(), 1);
  });
}

test("system reset works when storage is blocked and a later toggle can override again", () => {
  const page = visit({ blocked: true });
  page.click();
  assert.equal(page.theme(), "dark");
  page.reset();
  assert.equal(page.theme(), "light");
  page.systemChange(true);
  assert.equal(page.theme(), "dark");
  page.click();
  page.systemChange(false);
  page.systemChange(true);
  assert.equal(page.theme(), "light");
});
