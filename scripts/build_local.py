#!/usr/bin/env python3
"""Run local FrameWink builds with locked compiler storage and retained evidence."""
import argparse
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path
import platform
import plistlib
import signal
import subprocess
import sys
import time
import uuid

REPO = Path(__file__).resolve().parent.parent
BUILD_ENV = ("ARCHS", "ONLY_ACTIVE_ARCH", "TOOLCHAINS", "SDKROOT", "OTHER_SWIFT_FLAGS",
             "OTHER_CFLAGS", "OTHER_LDFLAGS", "SWIFT_VERSION", "XCODE_XCCONFIG_FILE",
             "CLANG_MODULE_CACHE_PATH", "SWIFT_MODULE_CACHE_PATH", "ENABLE_TESTABILITY",
             "SWIFT_OPTIMIZATION_LEVEL", "SWIFT_ACTIVE_COMPILATION_CONDITIONS",
             "GCC_PREPROCESSOR_DEFINITIONS", "CODE_SIGN_IDENTITY", "DEVELOPMENT_TEAM",
             "PROVISIONING_PROFILE_SPECIFIER", "CODE_SIGNING_ALLOWED")


def simulator_destination(family, env):
    devices = json.loads(output(["xcrun", "simctl", "list", "devices", "available", "--json"], env))
    candidates = []
    for runtime, group in devices["devices"].items():
        if ".iOS-" not in runtime:
            continue
        for device in group:
            kind = device.get("deviceTypeIdentifier", "")
            matches = ("iPad" in kind if family == "iPad" else
                       "Duo" in kind if family == "Duo" else "iPhone" in kind and "Duo" not in kind)
            if matches and device.get("isAvailable", True):
                candidates.append(device)
    if not candidates:
        raise ValueError("No available " + family + " Simulator; set the corresponding FRAMEWINK destination override.")
    candidates.sort(key=lambda device: (not device["name"].startswith("FrameWink"), device["state"] != "Booted", device["name"]))
    return "platform=iOS Simulator,id=" + candidates[0]["udid"]


def output(command, env=None):
    return subprocess.check_output(command, env=env, text=True).strip()


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def contains(parent, child):
    try:
        child.relative_to(parent)
        return True
    except ValueError:
        return False


def storage_path(value, compiler=True):
    path = Path(value).expanduser().absolute()
    resolved = path.resolve()
    # Never mkdir an absent mount point or fall back to the internal disk.
    for candidate in {path, resolved}:
        if candidate.parts[:2] != ("/", "Volumes"):
            continue
        if len(candidate.parts) < 3:
            raise ValueError("Choose a directory inside a mounted APFS volume.")
        mount = Path(*candidate.parts[:3])
        if not mount.is_mount():
            raise ValueError("External volume is not mounted: " + str(mount))
        if not contains(mount.resolve(), resolved):
            raise ValueError("The configured storage path leaves its mounted volume through a symlink.")
        if not compiler:
            continue
        info = plistlib.loads(subprocess.check_output(["diskutil", "info", "-plist", str(mount)]))
        if info.get("FilesystemType") != "apfs":
            raise ValueError("Compiler storage requires APFS; choose an APFS volume or mounted disk image.")
        expected = os.environ.get("FRAMEWINK_BUILD_CACHE_VOLUME_UUID")
        if expected and info.get("VolumeUUID", "").lower() != expected.lower():
            raise ValueError("External compiler volume UUID does not match the configured volume.")
    return resolved


def source_metadata():
    inputs = output(["git", "-C", str(REPO), "ls-files", "-co", "--exclude-standard", "-z"]).split("\0")
    hashes = {name: hashlib.sha256((REPO / name).read_bytes()).hexdigest() for name in inputs
              if name.startswith(("FrameWink/", "FrameWinkTests/", "FrameWinkUITests/", "FrameWink.xcodeproj/", "scripts/"))
              and (REPO / name).is_file()}
    return {"source_head": output(["git", "-C", str(REPO), "rev-parse", "HEAD"]),
            "source_status": output(["git", "-C", str(REPO), "status", "--porcelain"]),
            "source_hashes": hashes,
            "tracked_diff_sha256": digest(output(["git", "-C", str(REPO), "diff", "HEAD"]))}


def cache_arguments(arguments):
    """Discard only known evidence/destination/test-selection arguments."""
    result = []
    skip_value = {"-destination", "-destination-timeout", "-resultBundlePath", "-archivePath",
                  "-parallel-testing-enabled", "-collect-test-diagnostics",
                  "-test-timeouts-enabled", "-default-test-execution-time-allowance",
                  "-maximum-test-execution-time-allowance"}
    actions = {"build", "build-for-testing", "test", "test-without-building", "analyze", "archive"}
    index = 0
    while index < len(arguments):
        arg = arguments[index]
        if arg in skip_value:
            if arg == "-destination" and index + 1 < len(arguments):
                for item in arguments[index + 1].split(","):
                    if item.startswith("arch="):
                        result.append(item)
            index += 2
            continue
        if arg not in actions and arg not in {"-quiet", "-showBuildTimingSummary"} and not arg.startswith(("-only-testing:", "-skip-testing:")):
            result.append(arg)
        index += 1
    return result


def run(args):
    env = os.environ.copy()
    developer = env.get("FRAMEWINK_XCODE_DEVELOPER_DIR") or env.get("DEVELOPER_DIR") or output(["xcode-select", "-p"])
    developer = str(Path(developer).resolve())
    if not (Path(developer) / "usr/bin/xcodebuild").is_file():
        raise ValueError("Select an installed Xcode with xcode-select or DEVELOPER_DIR: " + developer)
    env.update(DEVELOPER_DIR=developer, FRAMEWINK_XCODE_DEVELOPER_DIR=developer)
    if env.get("FRAMEWINK_DERIVED_DATA"):
        raise ValueError("Use FRAMEWINK_BUILD_CACHE_ROOT instead of FRAMEWINK_DERIVED_DATA; the launcher selects a compatible workspace.")
    extra = args.arguments
    if extra[:1] == ["--"]:
        extra = extra[1:]
    reserved = {"-project", "-workspace", "-scheme", "-target", "-configuration", "-sdk", "-derivedDataPath"}
    if any(item in reserved for item in extra):
        raise ValueError("Use the launcher's --sdk/--configuration options; project, scheme and DerivedData are managed.")
    if "clean" in extra:
        raise ValueError("Use --fresh for cold validation; this launcher does not delete shared compiler workspaces.")
    if any(item.startswith(("CODE_SIGNING_ALLOWED=", "SDKROOT=", "ARCHS=")) for item in extra):
        raise ValueError("Use --unsigned/--sdk for signing/platform; architecture is selected by Xcode.")
    if "archive" in extra and (args.sdk != "iphoneos" or args.configuration != "Release"):
        raise ValueError("Archive with --sdk iphoneos --configuration Release.")
    # A raw -destination must agree with the selected SDK, including generic destinations.
    for index, item in enumerate(extra[:-1]):
        if item == "-destination":
            destination = extra[index + 1]
            simulator = "platform=iOS Simulator" in destination
            if simulator != (args.sdk == "iphonesimulator"):
                raise ValueError("Destination platform must match --sdk.")
    config_file = env.get("XCODE_XCCONFIG_FILE")
    if config_file:
        env["XCODE_XCCONFIG_FILE"] = str(Path(config_file).expanduser().resolve())
    build_environment = {key: env.get(key) for key in BUILD_ENV}
    if config_file:
        build_environment["xcconfig_sha256"] = hashlib.sha256(Path(env["XCODE_XCCONFIG_FILE"]).read_bytes()).hexdigest()
    identity = {"version": 1, "checkout": str(REPO), "developer_dir": developer,
                "xcode": output(["xcodebuild", "-version"], env), "sdk": args.sdk,
                "sdk_build": output(["xcrun", "--sdk", args.sdk, "--show-sdk-build-version"], env),
                "host_architecture": platform.machine(), "configuration": args.configuration,
                "signing": "unsigned" if args.unsigned else "project-default",
                "environment": build_environment, "arguments": [] if args.script else cache_arguments(extra),
                "variant": env.get("FRAMEWINK_BUILD_CACHE_VARIANT", "")}
    key = digest(identity)[:24]
    root = storage_path(args.cache_root)
    evidence_parent = storage_path(env.get("FRAMEWINK_BUILD_EVIDENCE_ROOT", REPO / "TestArtifacts/LocalBuilds"), compiler=False)
    evidence = storage_path(args.output, compiler=False) if args.output else evidence_parent / (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8])
    # Also check legacy test output overrides, which remain supported as evidence destinations.
    artifact_paths = [evidence]
    if env.get("FRAMEWINK_TEST_OUTPUT_ROOT"):
        artifact_paths.append(storage_path(env["FRAMEWINK_TEST_OUTPUT_ROOT"], compiler=False))
    for index, item in enumerate(extra[:-1]):
        if item in {"-resultBundlePath", "-archivePath"}:
            artifact_paths.append(storage_path(extra[index + 1], compiler=False))
    if any(contains(root, path) or contains(path, root) for path in artifact_paths):
        raise ValueError("Evidence and compiler storage must be separate directories.")
    root.mkdir(parents=True, exist_ok=True)
    workspace = root / ("fresh" if args.fresh else "workspaces") / key
    if args.fresh:
        workspace /= uuid.uuid4().hex
    workspace.mkdir(parents=True, exist_ok=True)
    evidence.mkdir(parents=True, exist_ok=False)
    derived = workspace / "DerivedData"
    temp = workspace / "Temp"
    temp.mkdir(exist_ok=True)
    env.update(FRAMEWINK_DERIVED_DATA=str(derived), TMPDIR=str(temp) + "/",
               FRAMEWINK_BUILD_EVIDENCE=str(evidence), FRAMEWINK_CACHE_CHECKOUT=str(REPO),
               FRAMEWINK_CACHE_PROFILE=args.sdk + ":" + args.configuration + ":" + identity["signing"])
    if args.script:
        command = ["/bin/bash", str(Path(args.script).resolve()), *extra]
    else:
        command = ["xcodebuild", "-project", str(REPO / "FrameWink.xcodeproj"), "-scheme", "FrameWink",
                   "-configuration", args.configuration, "-sdk", args.sdk, "-derivedDataPath", str(derived)]
        if "-destination" not in extra:
            command += ["-destination", "generic/platform=" + ("iOS Simulator" if args.sdk == "iphonesimulator" else "iOS")]
        if "-resultBundlePath" not in extra:
            command += ["-resultBundlePath", str(evidence / "result.xcresult")]
        if args.unsigned:
            command += ["CODE_SIGNING_ALLOWED=NO"]
        if any(action in extra for action in ("test", "test-without-building")) and "-collect-test-diagnostics" not in extra:
            # Match test_local.sh: retain results without large Simulator diagnoses.
            command += ["-collect-test-diagnostics", "never"]
        if "archive" in extra and "-archivePath" not in extra:
            command += ["-archivePath", str(evidence / "FrameWink.xcarchive")]
        command += extra or ["build"]
    manifest = {"identity": identity, "cache_key": key, "workspace": str(workspace),
                "derived_data": str(derived), "evidence": str(evidence), "command": command,
                "state": "waiting-for-lock", "fresh": args.fresh}
    manifest_path = evidence / "build.json"
    def save():
        temporary_manifest = manifest_path.with_suffix(".json.tmp")
        temporary_manifest.write_text(json.dumps(manifest, indent=2) + "\n")
        temporary_manifest.replace(manifest_path)
    save()
    print("Compiler workspace: " + str(workspace), flush=True)
    print("Retained evidence: " + str(evidence), flush=True)
    with (workspace / ".build.lock").open("a+") as lock:
        def cancel_wait(signum, frame):
            manifest.update(state="failed", exit_code=128 + signum,
                            finished_at=datetime.now(timezone.utc).isoformat())
            save()
            raise SystemExit(128 + signum)
        waiting_handlers = {sig: signal.signal(sig, cancel_wait) for sig in (signal.SIGINT, signal.SIGTERM)}
        try:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                print("Waiting for the compatible build workspace…", flush=True)
                manifest["lock_contended"] = True
                save()
                fcntl.flock(lock, fcntl.LOCK_EX)
        finally:
            for sig, handler in waiting_handlers.items():
                signal.signal(sig, handler)
        # Capture inputs after waiting, immediately before the actual workflow.
        manifest.update(source_metadata())
        manifest.update(state="running", started_at=datetime.now(timezone.utc).isoformat())
        save()
        started = time.monotonic()
        with (evidence / "build.log").open("wb") as log:
            child = subprocess.Popen(command, cwd=REPO, env=env, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, start_new_session=True,
                                     pass_fds=(lock.fileno(),))
            received = []
            def forward(signum, frame):
                received.append(signum)
                try:
                    os.killpg(child.pid, signum)
                except ProcessLookupError:
                    pass
            previous = {sig: signal.signal(sig, forward) for sig in (signal.SIGINT, signal.SIGTERM)}
            try:
                for chunk in iter(lambda: child.stdout.read1(65536), b""):
                    log.write(chunk)
                    log.flush()
                    sys.stdout.buffer.write(chunk)
                    sys.stdout.buffer.flush()
                code = child.wait()
            finally:
                for sig, handler in previous.items():
                    signal.signal(sig, handler)
        code = 128 + received[-1] if received else (128 - code if code < 0 else code)
        manifest.update(state="passed" if code == 0 else "failed", exit_code=code,
                        elapsed_seconds=round(time.monotonic() - started, 3),
                        finished_at=datetime.now(timezone.utc).isoformat())
        after = source_metadata()
        manifest["source_unchanged_during_run"] = all(manifest[key] == after[key] for key in ("source_head", "source_hashes"))
        save()
        (workspace / "workspace.json").write_text(json.dumps({"identity": identity, "last_evidence": str(evidence)}, indent=2) + "\n")
    return code


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk", choices=("iphonesimulator", "iphoneos"), default="iphonesimulator")
    parser.add_argument("--configuration", choices=("Debug", "Release"), default="Debug")
    parser.add_argument("--unsigned", action="store_true", help="Disable signing for this workspace")
    parser.add_argument("--fresh", action="store_true", default=os.environ.get("FRAMEWINK_FRESH_BUILD") == "1")
    parser.add_argument("--cache-root", default=os.environ.get("FRAMEWINK_BUILD_CACHE_ROOT", str(Path.home() / "Library/Caches/FrameWink/Build")))
    parser.add_argument("--output", help="New evidence directory (must not already exist)")
    parser.add_argument("--script", help=argparse.SUPPRESS)
    parser.add_argument("--simulator-destination", choices=("iPhone", "iPad", "Duo"), help=argparse.SUPPRESS)
    parser.add_argument("arguments", nargs=argparse.REMAINDER, help="xcodebuild arguments after --")
    args = parser.parse_args()
    try:
        if args.simulator_destination:
            print(simulator_destination(args.simulator_destination, os.environ.copy()))
            return 0
        return run(args)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print("FrameWink local build: " + str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
