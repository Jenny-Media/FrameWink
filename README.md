# FrameWink

FrameWink is a small, local-first photo-frame app for iPhone and iPad only.
macOS—including Mac Catalyst and Designed for iPhone/iPad on Apple silicon—and
Apple Vision Pro compatibility are not supported in the first release. This
repository contains the durable product context, implementation, tests, and
release plan for a 40-active-hour soft-launch timebox.

The product name is `FrameWink`. The app uses bundle identifier
`media.jenny.FrameWink`, the unit tests use `media.jenny.FrameWinkTests`, and
both targets use the Jenny Media LLC Apple Developer team. FrameWink Lifetime
is a Family Sharing-enabled non-consumable with production identifier
`media.jenny.FrameWink.wallmode`.

The public [privacy policy](PRIVACY.md) and
[support tracker](https://github.com/Jenny-Media/FrameWink/issues) are maintained
by Jenny Media LLC. Support email: `framewink@jenny.media`.

## Recreating the Xcode project

The checked-in `FrameWink.xcodeproj` is the active project. If the starter ever
needs to be recreated from the durable docs:

1. In Xcode, choose **File → New → Project → iOS App**.
2. Choose the final product name and organization identifier.
3. Select SwiftUI, Swift, and include tests.
4. Make the target universal (`TARGETED_DEVICE_FAMILY = 1,2`).
5. Set the minimum deployment target to iOS/iPadOS 15.0.
6. Initialize a Git repository.
7. Copy `AGENTS.md`, `docs/`, and `prompts/` into the Git root beside the
   `.xcodeproj`.
8. Open that Git root as the local Codex project.

Do not add production dependencies during the MVP. The intended system
frameworks are SwiftUI, UIKit, PhotoKit, PhotosUI, Vision, StoreKit 2, and
Foundation.

## Recommended source layout

```text
<AppName>/
├── AGENTS.md
├── docs/
├── prompts/
├── <AppName>.xcodeproj
├── <AppName>/
│   ├── App/
│   ├── Domain/
│   ├── Features/
│   │   ├── Demo/
│   │   ├── PhotoSetup/
│   │   ├── ReelReview/
│   │   ├── Frame/
│   │   ├── Paywall/
│   │   └── Settings/
│   ├── Services/
│   │   ├── PhotoImport/
│   │   ├── Curation/
│   │   ├── Layout/
│   │   ├── Display/
│   │   └── Purchases/
│   ├── Persistence/
│   └── Resources/SamplePhotos/
├── <AppName>Tests/
└── <AppName>UITests/
```

## Using this kit with local Codex

Run one milestone at a time. The initial scaffold and zero-permission preview
are already implemented; continue from the next incomplete milestone in
`docs/PLAN.md`. After Codex finishes a milestone:

1. Review the diff.
2. Confirm the build and tests actually ran.
3. Run the feature yourself in Simulator or on an iPhone or iPad.
4. Commit only when the milestone acceptance criteria pass.
5. Continue to the next milestone under the durable project goal.

`AGENTS.md` is the durable contract. `docs/PLAN.md` is the execution record.
Any attractive but unnecessary feature belongs in `docs/BACKLOG.md`.

Release preparation is recorded in `docs/DISTRIBUTION.md`, App Store privacy,
review, screenshot, and Xcode Cloud inputs are in `docs/APP_STORE.md`, and the
localized internal-beta checklist is in `TestFlight/WhatToTest.en-US.txt`.

Physical Photos/iCloud, TestFlight sandbox-purchase, Guided Access, Auto-Lock,
and unattended frame acceptance are guided by
[`docs/PHYSICAL_ACCEPTANCE.md`](docs/PHYSICAL_ACCEPTANCE.md). The accompanying
`scripts/physical_acceptance.sh` command builds the Debug real-PhotoKit harness,
verifies authorized album discovery, and captures ignored, device-local
acceptance evidence without committing device identifiers or tester photos.

## Forty-hour rule

The goal is a narrow TestFlight-ready product, not a complete digital-frame
platform. At 40 active hours, remove or postpone unfinished nonessential work.
Do not extend the schedule for integrations, custom machine-learning models,
weather, video, NAS support, or elaborate animation.

The seven-day unattended test consumes calendar time but should run in parallel
with release preparation.
