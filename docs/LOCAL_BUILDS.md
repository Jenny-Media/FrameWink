# Local compiler storage and retained evidence

Use `scripts/build_local.py` for normal command-line builds. Existing local
tests, screenshot captures and physical-device build helpers use the same
launcher automatically. Python 3 and a selected installed Xcode are required.

```sh
# Simulator app build.
python3 scripts/build_local.py --unsigned

# Compile the app and test bundles for a specific Simulator.
python3 scripts/build_local.py --unsigned -- \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_ID' build-for-testing

# Release simulator compilation.
python3 scripts/build_local.py --unsigned --configuration Release

# Signed device build, using existing project signing settings.
python3 scripts/build_local.py --sdk iphoneos -- \
  -destination 'platform=iOS,id=YOUR_DEVICE_UDID' build

# Local Release archive; Xcode Cloud remains the distribution builder.
python3 scripts/build_local.py --sdk iphoneos --configuration Release -- archive

# Deliberately fresh compilation; warm workspaces are preserved.
python3 scripts/build_local.py --unsigned --fresh
```

Place xcodebuild arguments after `--`. Use the launcher's `--configuration`,
`--sdk` and `--unsigned` options for those settings. Project, scheme and
DerivedData are managed. Other compiler arguments get distinct workspace
identities. Destination platform must match the SDK; explicit destination
architecture also affects identity. Every invocation lets Xcode check changed
inputs. `test-without-building` deliberately requires existing test products.
Compiler product/intermediate/module-cache paths are managed by the launcher.
Overrides such as `CONFIGURATION_BUILD_DIR`, `OBJROOT` and `SYMROOT` are rejected
in arguments and environment variables. Additional xcconfig files and package
output-path overrides are unsupported because they can redirect writes outside
the workspace lock; pass supported compiler settings directly instead. Custom
compiler flags must preserve the managed output paths.
Test actions default to `-collect-test-diagnostics never`, matching the existing
local gate. An explicit diagnostic collection option remains available.

## Reuse and locking

The default internal compiler root is `~/Library/Caches/FrameWink/Build`.
Compatible workspaces use `workspaces/<key>/DerivedData` and a build-scoped
`Temp` directory. Identity includes checkout path, Xcode path/build, SDK/build,
host architecture, configuration, signing, compiler arguments and build
environment. Custom setups may also set `FRAMEWINK_BUILD_CACHE_VARIANT`.
Commit IDs and run dates are recorded as evidence and do not create workspaces.

Normal builds and test builds can share compatible storage; Xcode may rebuild
tasks when an action changes effective flags. Device/Simulator, signed/unsigned,
Debug/Release, checkouts and toolchains remain separate. Fixed helper workflows
declare platform/signing; runtime-only helper arguments do not create caches.
Explicit architecture components in test-helper destination overrides also
affect identity; changing only a device ID preserves reuse.

An exclusive `fcntl.flock` on `.build.lock` covers the complete workflow,
including installation and result/screenshot export. A second compatible run
waits. Interrupts are forwarded to the child process group. Failures and
cancellation retain exit status and logs. Physical `sample` and `soak` commands
validate their report path without holding a compiler lock. Landscape capture
cancellation exits through cleanup without starting another capture attempt.
Closing the console pipe (for example with `head`) lets the workflow finish and
retains its full log and final status. A log-write failure cancels and reaps the
owned workflow before recording failure and releasing its workspace.

`--fresh` or `FRAMEWINK_FRESH_BUILD=1` creates an isolated workspace beneath
`fresh/` without erasing a warm cache. No automatic deletion is implemented.
Obsolete toolchains/checkouts and fresh builds still require a separate budget
and cleanup review. Future cleanup must acquire the same workspace lock.

## Evidence and deliverables

Every invocation retains `build.json` and `build.log` under a unique
`TestArtifacts/LocalBuilds/<UTC>-<id>/` directory. Metadata records source
commit/status, native input hashes, compiler identity/path, command, timing and
exit status. Normal builds also retain `.xcresult`; archives default to
`FrameWink.xcarchive` inside the run directory.

Use `FRAMEWINK_BUILD_EVIDENCE_ROOT` for another evidence parent or `--output`
for one new exact run directory. Evidence and compiler storage must not overlap.
`FRAMEWINK_TEST_OUTPUT_ROOT` remains an explicit test-result override; otherwise
family-named results live under the current run's `tests/` directory.
Relative output paths, including explicit result/archive arguments,
`FRAMEWINK_TEST_OUTPUT_ROOT`, `FRAMEWINK_ARTIFACTS` and
`FRAMEWINK_SCREENSHOT_DIRECTORY`, are resolved from the caller's directory and
forwarded as absolute paths. These destinations must be separate from compiler
storage, including through symlinks or parent directories. Helper scripts keep
the caller's working directory; normal xcodebuild commands run from the checkout.
Physical build and monitoring modes therefore keep the same report location.
Absolute output destinations remain supported. Landscape
capture retries retain `attempt-1.xcresult` and `attempt-2.xcresult`. Capture
attachments and failed results are retained. Existing screenshot export paths
and image-validation rules are preserved.

Compiler products are disposable after the workflow finishes. Save app copies
and symbols separately when later installation or exact-binary review is
required. A result bundle is test evidence, not an installable app backup.
Finished archives, evidence and media have independent retention policies.

## Toolchains, destinations and other builders

Selection order is `FRAMEWINK_XCODE_DEVELOPER_DIR`, `DEVELOPER_DIR`, then
`xcode-select -p`. A missing explicit toolchain fails. System selection,
signing and production identifiers are not changed. Removed RC/beta app paths
are no longer defaults.

`test_local.sh` discovers available iPhone/iPad and SDK-eligible Duo Simulators,
preferring dedicated FrameWink names and then booted devices. Existing
`FRAMEWINK_IPHONE_DESTINATION`, `FRAMEWINK_IPAD_DESTINATION` and
`FRAMEWINK_DUO_DESTINATION` overrides remain. Screenshot helpers preserve their
specific destination and geometry requirements; supply their existing simulator
override when the original device is unavailable.
Automatic test destination discovery requires iOS 17 or later, matching both
test targets; older available devices cannot win the name/boot preference.

The Xcode GUI already reuses its independently managed DerivedData. Keep that
directory separate from launcher workspaces because the GUI does not acquire
this lock. IDE preferences and Xcode Cloud cache/release policies are unchanged.

## Internal storage

Compiler caches and retained reports use internal storage. Use
`FRAMEWINK_BUILD_CACHE_ROOT` or `--cache-root` for another internal compiler path.
External-disk routing is deferred: `/Volumes` paths and symlink aliases resolving
there fail before output directories are created. There is no filesystem-type,
mount-state or volume-UUID management. Changing the compiler root does not move
old caches or evidence; no automatic cleanup or migration is implemented.

`FRAMEWINK_DERIVED_DATA` is now an internal launcher output. Old direct path
overrides fail with guidance to use `FRAMEWINK_BUILD_CACHE_ROOT`, so incompatible
builds cannot accidentally share a manually selected directory.

## Workflow verification

```sh
python3 -m unittest discover -s scripts/tests -v
```

These checks use fake Xcode commands to verify identity, retention, locking,
cancellation, fresh builds and rejection of deferred external paths. They execute
the local test gate to verify its device matrix and owner-approved exclusions.
Copied physical and capture entry points with inert tools check caller-relative outputs, JPEG cleanup
boundaries and rejection of compiler/evidence overlap. Native compiler and
runtime evidence is recorded in `docs/TESTING.md`.

Capture helpers validate their effective screenshot destinations, including
defaults, before starting a cached workflow. Custom internal compiler roots
cannot contain retained screenshots or be nested inside their directories.
