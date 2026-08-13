# Physical acceptance guide

This guide closes the remaining physical-device acceptance gaps without
confusing local test doubles with TestFlight or App Store evidence.

## What is automated

`scripts/physical_acceptance.sh` safely discovers exactly one connected
physical iPad, builds and installs a signed Debug build, opens a real-PhotoKit
acceptance harness, and captures timestamped evidence. The harness unlocks
FrameWink Lifetime only for this explicitly launched Debug process; it still uses the real
Photos library and does not change Release or TestFlight entitlement behavior.

The monitor records whether the iPad is reachable, whether FrameWink is still
running, lock state, screenshots, and a photo-free app heartbeat containing
foreground state, Auto-Lock ownership, Guided Access status, thermal state,
Low Power Mode, and battery state. Evidence is written under the ignored
`TestArtifacts/PhysicalAcceptance/` directory. Device identifiers and private
photos therefore do not enter Git.

Start the harness:

```sh
scripts/physical_acceptance.sh prepare
```

Record a checkpoint after a manual step:

```sh
scripts/physical_acceptance.sh sample
```

Run a short one-hour monitor every minute:

```sh
scripts/physical_acceptance.sh soak 1 60
```

Run the release-gate seven-day monitor every five minutes:

```sh
scripts/physical_acceptance.sh soak 168 300
```

Keep the Mac connected for host-side monitoring. The iPad can use a separate
safe charger after the initial wired launch only if it stays reachable over the
paired local network; otherwise the missing samples are correctly recorded as
monitoring gaps. The app itself does not depend on the Mac.

## Real Photos and iCloud

Prepare a test album in Apple Photos. Use non-private images that Jenny Media
LLC owns or is licensed to test. Include at least one screenshot, one duplicate,
one intentionally blurred image, and one item that is iCloud-only if available.

1. Run `prepare`. It opens the real simplified FrameWink home screen.
2. Tap **Choose an Album** (or **Change Album** if one is already configured).
   This is the only action that should trigger the broad
   Photos prompt. Choose **Limited Access** first and select only the test album
   photos. If the installed OS offers different wording, choose its limited
   equivalent.
3. Select the test album from the visual cover grid. The neutral preparation
   screen should show live counts. After ten representative candidates are
   prepared and curated, **Start Frame** should become available while the
   status says that FrameWink is adding more photos or improving the reel. The
   result should refine again around thirty prepared candidates without making
   the existing reel unavailable. Inspect **Review Photos** from More and
   record a `sample`; interrupt and relaunch once to confirm checkpointed
   progress is retained.
4. Confirm screenshots are absent from suggestions and compare the strongest
   selections against the labelled fixture sheet described below.
5. In Photos, add and remove one test image. Return to FrameWink and confirm the
   album refreshes without changing or deleting any original. Record a sample.

After Photos access has been granted, album discovery itself can be repeated
without exposing album names or photos in the repository:

```sh
scripts/physical_acceptance.sh verify-albums
```

The physical-only UI test taps **Choose Album** and requires the real PhotoKit
album grid to replace the loading state within ten seconds. Simulator runs skip
this check by design. It also waits up to twenty seconds for at least one real
cover to replace its loading placeholder. A cache regression then closes and
reopens the picker and requires both the existing catalog and a visible cover
to return within two seconds. XCTest temporarily shows iPadOS's automation indicator;
the command always relaunches the interactive FrameWink harness afterward,
whether the test passes or fails.
6. With an iCloud-only item in the album, confirm Apple Photos can fetch it and
   that the preparation count advances without resetting to zero. Disconnect
   networking and confirm already prepared photos remain usable. FrameWink has
   no developer endpoint.
7. In Settings, deny Photos access. Return to FrameWink and confirm Sample Mode
   and any free imported reel still work. Restore Limited, then Full Access,
   confirming the automatic album recovers after each foreground return.
8. Tap **Delete Automatic Album Cache** and confirm the app-controlled copies
   disappear while every Apple Photos original remains.

The permission alert, Limited selection sheet, iCloud residency changes, and
Settings authorization controls are Apple-owned privacy surfaces. A tester must
make those choices; unattended code must not bypass them.

For the human-labelled 80% displayability gate, create a private CSV outside
the public repository with columns `filename`, `displayable`, `duplicate_group`,
and `notes`. Have a human label at least 50 licensed test images before viewing
FrameWink's choices. Pass when at least 80% of selected images were pre-labelled
displayable and each duplicate group contributes no more than its intended
winner. Do not commit private photos or their identifying filenames.

## TestFlight purchase, restore, refund, and Family Sharing

First complete Xcode Cloud and obtain a build in the `Jenny Media Internal`
TestFlight group. A development-signed build can test Apple's sandbox too, but
the release gate should use the exact TestFlight binary.

1. Create a dedicated Sandbox Apple Account in App Store Connect under **Users
   and Access → Sandbox**. Use an email address never used as an Apple Account.
2. Install FrameWink from TestFlight. TestFlight builds automatically use
   Apple's sandbox purchase environment.
3. Follow Apple's current TestFlight sandbox sign-in instructions on the iPad.
   Keep credentials in Apple's UI; never place them in scripts, Git, or Codex
   output.
4. Open **More Frame Features** and confirm `FrameWink Lifetime`, `$9.99`, the
   one-time-purchase wording, and Family Sharing metadata. Complete the sandbox
   purchase and verify the paid frame features unlock. No real charge should occur in
   sandbox.
5. Force-quit and relaunch offline. Confirm the verified entitlement remains
   usable. Reconnect and tap **Restore Purchases**; it must remain unlocked.
6. Clear the sandbox tester's purchase history in App Store Connect or the iPad
   sandbox settings, then verify paid access is removed after StoreKit updates.
7. For Family Sharing, create a Sandbox Test Family in App Store Connect, add a
   second sandbox account, install the TestFlight build for that account, and
   verify the shared non-consumable unlocks without another purchase.

Purchase confirmation, sandbox sign-in, purchase-history clearing, and family
membership are Apple-owned account/commerce actions. UI automation may navigate
to the buttons, but a human must verify the account and authorize transactions.
The existing automated StoreKit suite continues to cover success, restore,
pending, failure, refund/revocation, and entitlement logic on every build.

## Wall Mode, Guided Access, and the seven-day run

Before the run, use an undamaged iPad and battery, a safe certified charger and
cable, a stable mount that does not cover vents, and a location where heat can
dissipate. Physically inspect these; software cannot certify mounting or battery
safety.

1. In the Debug acceptance harness, select a prepared local reel or automatic
   album, tap **Start Frame**, and run `sample`. The heartbeat should show
   `idleTimerDisabled: true` while Frame Mode is active.
2. Wait longer than the iPad's configured Auto-Lock interval. Confirm the screen
   remains on. Exit Frame Mode, run another sample, and confirm
   `idleTimerDisabled: false`; then verify normal Auto-Lock resumes.
3. Start the frame and enable Guided Access with the configured Accessibility
   Shortcut. Return to **Frame Settings → Mounted iPad Tips** if needed and confirm it reports active;
   the heartbeat also records `guidedAccessEnabled: true`. Consumer Guided
   Access must be started manually by design.
4. Set dim and blackout times a few minutes ahead and visually confirm both
   overlays while the app remains foregrounded. Confirm a tap can reveal
   controls during blackout.
5. Start `soak 168 300`. Exercise overnight blackout, Wi-Fi loss and recovery,
   an album addition/removal, one foreground/background cycle, and one
   deliberate FrameWink termination. Record each deliberate event and recovery
   time in `incidents.log` or a companion note in the artifact directory.
6. Inspect `timeline.jsonl`, `incidents.log`, screenshots, and heartbeats at the
   end. Fail the run for an unplanned app termination, serious/critical thermal
   state, repeated charging loss, a screen lock while Frame Mode should own the
   idle timer, corrupted display state, or manual recovery not explained by a
   deliberate test event.

The monitor cannot prove smooth animation, perceived brightness, charger heat,
mount stability, battery swelling, or restart recovery. A human must inspect
those. FrameWink intentionally does not promise automatic relaunch after an iPad
restart.

## Remaining device matrix

The connected 2018 iPad Pro is useful real hardware but has 4 GB RAM and runs a
modern OS. It does not prove the approximately 2 GB legacy performance floor or
iPadOS 15 compatibility. Repeat the automated suite and this guide on an iPad
Air 2, iPad mini 4, or another supported 2 GB iPad before claiming the oldest-
device gate is closed.
