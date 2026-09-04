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

The site intentionally has no account, contact form, product analytics,
advertising, tracking scripts, or marketing cookies. Support is provided by
email and the repository's public issue tracker.

FrameWink is available on the App Store at
[apps.apple.com/us/app/framewink/id6800849400](https://apps.apple.com/us/app/framewink/id6800849400).
The homepage uses Apple's official, unmodified Download on the App Store badge.

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
