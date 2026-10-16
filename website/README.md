# FrameWink website

This directory contains the public FrameWink product website for
`frame.jenny.media`. It is a standard Next.js application deployed through
Vercel from the same repository as the iPhone and iPad app.

## Local development

```sh
npm install
npm run dev
```

## Validation

```sh
npm test
npm run lint
npm run build
npm audit
```

Use Node.js 24, matching the deployment configuration. `npm ci` must reproduce
the checked-in lockfile before running these checks.

### Security dependencies

Next.js and its ESLint plugin are pinned together at 16.4.2. The lockfile also
updates the affected image-processing, source-map, YAML and brace-expansion
packages. Full and production-only `npm audit` checks should both report no
known vulnerabilities.

The pinned Next lint plugin still requires `fast-glob`, whose `braces` dependency
has an [unpatched recursion advisory](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm).
The scoped override uses the local, development-only `tools/next-lint-glob`
adapter. It implements the plugin's sole `globSync` call using pinned
`tinyglobby`, with directory expansion disabled so literal project roots do not
unexpectedly include their descendants. All Next lint rules remain enabled.
The compatibility tests exercise the actual plugin helper and its link/image
rules with literal, wildcard, array, brace and extglob roots.

Recheck this adapter whenever upgrading the lint plugin: it intentionally
implements only the API used by 16.4.2. Remove the override, direct development
dependency and adapter once the upstream plugin no longer needs the vulnerable
chain, then rerun the clean install, tests, lint, build and audit checks.

The site intentionally has no account, contact form, product analytics,
advertising, tracking scripts, or marketing cookies. Support is provided by
email and the repository's public issue tracker.

FrameWink is available on the App Store at
[apps.apple.com/app/framewink/id6800849400](https://apps.apple.com/app/framewink/id6800849400).
The homepage uses Apple's official, unmodified Download on the App Store badge.

## Appearance

One sun/moon button at the top right switches between light and dark themes.
The first visit follows the device appearance. A choice is stored only in this
browser (`framewink-theme` in local storage), persists across pages and visits,
and synchronizes between tabs. The quiet “Use system appearance” button in the
footer removes that choice and follows device appearance again. If storage is
unavailable, both buttons still work for the current visit. No account, cookie,
or network request is needed.

## Navigation on compact screens

The appearance button keeps its own top-right slot. At widths up to 900 pixels,
Menu opens all header destinations without crowding the brand. Escape and outside
clicks close it, and keyboard focus moves to an available control when the layout
changes. The links remain visible if the menu controller cannot load. The header
and its content remain server-rendered; only disclosure behavior is enhanced on
the client. The phone Menu label is omitted through 375 pixels, with its accessible
name preserved.

## Deployment

Configure the Vercel project with `website` as its Root Directory and `main` as
the production branch. The production custom domain is live at
[frame.jenny.media](https://frame.jenny.media). The root `.vercelignore` keeps
the iOS project and local artifacts out of CLI deployment uploads.
The initial production launch can use the Vercel CLI. Automatic Git deployments
require the Vercel GitHub App to be authorized for `Jenny-Media/FrameWink`;
once connected, Vercel should skip deployments when `website/` is unchanged.
Xcode Cloud should use a Files and Folders start condition that does not start
an app build when all changed files are under `website/`.

## iPhone Duo showcase

The Duo showcase links to the approved FrameWink on iPhone Duo custom product
page for version 1.6. General download links retain the iPad-first listing. It uses
a real Xcode 27.1 app capture with Apple's complete official Night Sky Inner
Open Landscape artwork. The owner authorized accepting the Apple Design
Resources license LYL142 (June 21, 2023), accepted October 1, 2026.

Original app captures, artwork hashes, license-use restrictions, and the
reproducible generator are archived in
[the native Duo candidate](https://github.com/Jenny-Media/FrameWink/tree/codex/iphone-duo-native/Design/Website/iPhone-Duo).
The standalone Apple artwork stays outside Git. Version 1.6 build 66 passed
Cloud validation and App Review; its manual release was requested on October
10, 2026, and the public US App Store now shows version 1.6. Physical Duo
acceptance remains separate.
