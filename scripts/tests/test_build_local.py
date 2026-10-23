"""Behavior checks for cache isolation, retention, locking and existing test gates."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import signal
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock

REPO = Path(__file__).resolve().parents[2]
LAUNCHER = REPO / "scripts/build_local.py"


class LocalBuildTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        developer = self.root / "Xcode.app/Contents/Developer"
        (developer / "usr/bin").mkdir(parents=True)
        (developer / "usr/bin/xcodebuild").touch()
        self.env = {key: value for key, value in os.environ.items()
                    if not key.startswith("FRAMEWINK_") and key not in {"DEVELOPER_DIR", "XCODE_XCCONFIG_FILE"}}
        self.env.update(PATH=str(self.bin) + os.pathsep + self.env["PATH"], DEVELOPER_DIR=str(developer),
                        FRAMEWINK_BUILD_CACHE_ROOT=str(self.root / "compiler"),
                        FRAMEWINK_BUILD_EVIDENCE_ROOT=str(self.root / "evidence"),
                        FAKE_CALLS=str(self.root / "calls.jsonl"))
        self.tool("xcodebuild", '''import json,os,sys
if '-version' in sys.argv:
 print(os.environ.get('FAKE_XCODE_VERSION','Xcode Test 1'))
else:
 with open(os.environ['FAKE_CALLS'],'a') as f: f.write(json.dumps(sys.argv[1:])+'\\n')
 for option in ['-resultBundlePath','-archivePath']:
  if option in sys.argv: os.makedirs(sys.argv[sys.argv.index(option)+1],exist_ok=False)
 print('Recorded build output')
 sys.exit(int(os.environ.get('FAKE_EXIT','0')))
''')
        self.tool("xcrun", '''import json,os,sys
if '--show-sdk-build-version' in sys.argv: print('test-sdk-'+sys.argv[2])
elif '--show-sdk-version' in sys.argv: print('27.1')
elif 'simctl' in sys.argv:
 print(os.environ.get('FAKE_DEVICES') or json.dumps({'devices':{'com.apple.CoreSimulator.SimRuntime.iOS-27-1':[
  {'name':'FrameWink Renamed Phone','udid':'phone','state':'Shutdown','deviceTypeIdentifier':'iPhone-18-Pro'},
  {'name':'FrameWink Renamed Pad','udid':'pad','state':'Shutdown','deviceTypeIdentifier':'iPad-Pro'},
  {'name':'FrameWink Renamed Duo','udid':'duo','state':'Shutdown','deviceTypeIdentifier':'iPhone-Duo'}]}}))
else: print('{}')
''')

    def tool(self, name, body):
        path = self.bin / name
        path.write_text("#!" + sys.executable + "\n" + body)
        path.chmod(0o755)

    def invoke(self, *arguments, env=None):
        return subprocess.run([sys.executable, str(LAUNCHER), *arguments], env=env or self.env,
                              text=True, capture_output=True, timeout=20)

    def manifests(self):
        return sorted((self.root / "evidence").glob("*/build.json"), key=lambda path: path.stat().st_mtime_ns)

    def latest(self):
        return json.loads(self.manifests()[-1].read_text())

    def test_reuses_across_destinations_and_report_dates(self):
        for device in ["phone", "pad"]:
            result = self.invoke("--unsigned", "--", "-destination", "platform=iOS Simulator,id=" + device,
                                 "-only-testing:FrameWinkTests/Example", "build-for-testing")
            self.assertEqual(result.returncode, 0, result.stderr)
        records = [json.loads(path.read_text()) for path in self.manifests()]
        self.assertEqual(records[0]["derived_data"], records[1]["derived_data"])
        self.assertNotEqual(records[0]["evidence"], records[1]["evidence"])
        self.assertTrue(all(record["state"] == "passed" for record in records))

    def test_separates_configuration_signing_sdk_and_flags(self):
        cases = [[], ["--unsigned"], ["--configuration", "Release"], ["--sdk", "iphoneos"],
                 ["--", "OTHER_SWIFT_FLAGS=-DPROBE", "build"]]
        keys = []
        for arguments in cases:
            result = self.invoke(*arguments)
            self.assertEqual(result.returncode, 0, result.stderr)
            keys.append(self.latest()["cache_key"])
        self.assertEqual(len(keys), len(set(keys)))

    def test_new_toolchain_and_environment_get_separate_workspaces(self):
        keys = []
        for changes in [{}, {"FAKE_XCODE_VERSION": "Xcode Test 2"}, {"OTHER_SWIFT_FLAGS": "-DPROBE"}]:
            result = self.invoke(env=dict(self.env, **changes))
            self.assertEqual(result.returncode, 0, result.stderr)
            keys.append(self.latest()["cache_key"])
        self.assertEqual(len(set(keys)), 3)

    def test_fresh_build_preserves_existing_workspace_and_results(self):
        self.assertEqual(self.invoke().returncode, 0)
        original = self.latest()
        for unused in range(2):
            self.assertEqual(self.invoke("--fresh").returncode, 0)
        records = [json.loads(path.read_text()) for path in self.manifests()]
        self.assertEqual(len({record["workspace"] for record in records}), 3)
        self.assertTrue(Path(original["workspace"]).exists())
        self.assertTrue(Path(original["evidence"], "build.log").exists())

    def test_preserves_failed_run_exit_code_and_log(self):
        result = self.invoke(env=dict(self.env, FAKE_EXIT="65"))
        self.assertEqual(result.returncode, 65)
        record = self.latest()
        self.assertEqual(record["state"], "failed")
        self.assertEqual(record["exit_code"], 65)
        self.assertIn("Recorded build output", Path(record["evidence"], "build.log").read_text())

    def test_test_diagnostics_default_and_explicit_override(self):
        for extra in [[], ["-collect-test-diagnostics", "always"]]:
            result = self.invoke("--", *extra, "test")
            self.assertEqual(result.returncode, 0, result.stderr)
        calls = [json.loads(line) for line in (self.root / "calls.jsonl").read_text().splitlines()]
        self.assertEqual(calls[0][calls[0].index("-collect-test-diagnostics") + 1], "never")
        self.assertEqual(calls[1][calls[1].index("-collect-test-diagnostics") + 1], "always")

    def test_rejects_overlapping_evidence_and_compiler_output(self):
        result = self.invoke("--output", str(self.root / "compiler/report"))
        self.assertEqual(result.returncode, 2)
        result = self.invoke("--", "-resultBundlePath", str(self.root / "compiler/result.xcresult"), "build")
        self.assertEqual(result.returncode, 2)
        self.assertFalse((self.root / "compiler").exists())

    def fixture_launcher(self):
        # Keep deliberately bad relative-path regressions inside owned fixtures.
        project = self.root / "source"
        launcher = project / "scripts/build_local.py"
        launcher.parent.mkdir(parents=True)
        shutil.copy2(LAUNCHER, launcher)
        self.tool("git", "import sys\nif 'rev-parse' in sys.argv: print('fixture-head')\n")
        return project, launcher

    def fixture_workflow(self, name):
        project, unused = self.fixture_launcher()
        for filename in ("build_cache.sh", name):
            shutil.copy2(REPO / "scripts" / filename, project / "scripts" / filename)
        return project, project / "scripts" / name

    def test_relative_artifact_paths_use_the_callers_directory(self):
        project, launcher = self.fixture_launcher()
        caller = self.root / "caller"
        caller.mkdir()
        for option, extra in [("-resultBundlePath", []),
                              ("-archivePath", ["--sdk", "iphoneos", "--configuration", "Release"])]:
            result = subprocess.run([sys.executable, str(launcher), *extra, "--", option,
                                     "retained/" + option[1:], "archive" if extra else "build"],
                                    cwd=caller, env=self.env, capture_output=True, text=True, timeout=20)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((caller / "retained" / option[1:]).is_dir())
            self.assertFalse((project / "retained").exists())
        result = subprocess.run([sys.executable, str(launcher), "--", "-resultBundlePath",
                                 "../compiler/result.xcresult", "build"], cwd=caller,
                                env=self.env, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 2)
        self.assertFalse((self.root / "compiler/result.xcresult").exists())

    def test_relative_helper_test_output_is_normalized_and_guarded(self):
        project, launcher = self.fixture_launcher()
        caller = self.root / "caller"
        caller.mkdir()
        script = self.root / "output.sh"
        script.write_text('mkdir -p "$FRAMEWINK_TEST_OUTPUT_ROOT/result.xcresult"\n')
        for value, expected in [("retained", 0), ("../compiler/report", 2)]:
            result = subprocess.run([sys.executable, str(launcher), "--script", str(script)],
                                    cwd=caller, env=dict(self.env, FRAMEWINK_TEST_OUTPUT_ROOT=value),
                                    capture_output=True, text=True, timeout=20)
            self.assertEqual(result.returncode, expected, result.stderr)
        self.assertTrue((caller / "retained/result.xcresult").is_dir())
        self.assertFalse((project / "retained").exists())
        self.assertFalse((self.root / "compiler/report").exists())

    def test_physical_build_and_monitor_modes_keep_caller_relative_reports(self):
        project, script = self.fixture_workflow("physical_acceptance.sh")
        caller = self.root / "caller"
        caller.mkdir()
        # Stop every mode at empty device discovery, before any build/install/monitor action.
        self.tool("jq", "pass\n")
        self.tool("xcrun", '''import json,pathlib,sys
if '--show-sdk-build-version' in sys.argv: print('fixture-sdk')
elif sys.argv[1:4] == ['devicectl','list','devices']:
 pathlib.Path(sys.argv[sys.argv.index('--json-output')+1]).write_text(json.dumps({'result':{'devices':[]}}))
else: sys.exit(99)
''')
        env = dict(self.env, FRAMEWINK_ARTIFACTS="reports")
        for mode in ("prepare", "prepare-storekit", "verify-albums", "sample", "soak"):
            with self.subTest(mode=mode):
                device_list = caller / "reports/.devices.json"
                device_list.unlink(missing_ok=True)
                result = subprocess.run(["/bin/sh", str(script), mode], cwd=caller, env=env,
                                        text=True, capture_output=True, timeout=20)
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                self.assertIn("found 0", result.stdout + result.stderr)
                self.assertTrue(device_list.is_file())
                self.assertFalse((project / "reports").exists())
        self.assertFalse((self.root / "calls.jsonl").exists())

    def test_duo_capture_cleans_only_the_caller_relative_directory(self):
        project, script = self.fixture_workflow("capture_app_store_iphone_duo_proof_screenshots.sh")
        caller = self.root / "caller"
        for directory in (caller / "shots", project / "shots"):
            directory.mkdir(parents=True)
            (directory / "sentinel.jpg").write_bytes(b"owned fixture")
        self.tool("magick", "pass\n")
        self.tool("xcrun", "import sys\nif '--show-sdk-build-version' in sys.argv: print('fixture-sdk')\nelse: sys.exit(99)\n")
        env = dict(self.env, FRAMEWINK_SCREENSHOT_DIRECTORY="shots",
                   FRAMEWINK_SIMULATOR_ID="fixture", FAKE_EXIT="42")
        # The fake build stops the real copied script after its owned JPEG cleanup.
        result = subprocess.run(["/bin/sh", str(script)], cwd=caller, env=env,
                                text=True, capture_output=True, timeout=20)
        self.assertEqual(result.returncode, 42, result.stdout + result.stderr)
        self.assertFalse((caller / "shots/sentinel.jpg").exists())
        self.assertEqual((project / "shots/sentinel.jpg").read_bytes(), b"owned fixture")
        calls = [json.loads(line) for line in (self.root / "calls.jsonl").read_text().splitlines()]
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][-1], "build")

    def test_physical_monitors_validate_reports_before_discovery(self):
        project, script = self.fixture_workflow("physical_acceptance.sh")
        external = "/Volumes/FrameWink-Deferred-Unit-Test-Volume/reports"
        alias = self.root / "external-reports"
        alias.symlink_to(external)
        self.tool("jq", "pass\n")
        self.tool("xcrun", "import os,pathlib\npathlib.Path(os.environ['FAKE_CALLS']).touch()\n")
        paths = [(external, "External storage is deferred"),
                 (str(alias), "External storage is deferred"),
                 (str(self.root / "compiler/reports"), "Evidence and compiler storage must be separate"),
                 (str(self.root), "Evidence and compiler storage must be separate")]
        for mode in ("sample", "soak"):
            for path, error in paths:
                with self.subTest(mode=mode, path=path):
                    result = subprocess.run(["/bin/sh", str(script), mode],
                                            env=dict(self.env, FRAMEWINK_ARTIFACTS=path),
                                            text=True, capture_output=True, timeout=20)
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                    self.assertIn(error, result.stderr)
        self.assertFalse((self.root / "calls.jsonl").exists())
        self.assertFalse((self.root / "compiler").exists())
        self.assertFalse((self.root / "evidence").exists())
        self.assertFalse((project / "TestArtifacts").exists())

    def test_landscape_cancellation_stops_before_retrying_capture(self):
        project, script = self.fixture_workflow("capture_app_store_landscape_screenshots.sh")
        self.tool("jq", "pass\n")
        self.tool("magick", "pass\n")
        self.tool("xcrun", '''import sys
if '--show-sdk-build-version' in sys.argv: print('fixture-sdk')
elif sys.argv[1:4] == ['simctl','list','devices']:
 print('Fixture Pad (pad) (Booted)\\nFixture Phone (phone) (Booted)')
''')
        self.tool("xcodebuild", '''import json,os,pathlib,signal,sys,time
if '-version' in sys.argv:
 print('Xcode Fixture')
else:
 def cancelled(signum,frame): sys.exit(128+signum)
 for signum in (signal.SIGINT,signal.SIGTERM): signal.signal(signum,cancelled)
 with open(os.environ['FAKE_CALLS'],'a') as stream: stream.write(json.dumps(sys.argv[1:])+'\\n')
 pathlib.Path(os.environ['HOLD_STARTED']).touch()
 time.sleep(5)
 sys.exit(70)
''')
        started = self.root / "capture-started"
        env = dict(self.env, HOLD_STARTED=str(started), FRAMEWINK_IPAD_LANDSCAPE_SIMULATOR_ID="pad",
                   FRAMEWINK_IPHONE_LANDSCAPE_SIMULATOR_ID="phone")
        for signum in (signal.SIGINT, signal.SIGTERM):
            with self.subTest(signal=signum):
                started.unlink(missing_ok=True)
                calls_path = self.root / "calls.jsonl"
                calls_path.unlink(missing_ok=True)
                process = subprocess.Popen(["/bin/bash", str(script)], env=env,
                                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                self.addCleanup(self.stop, process)
                self.wait_for(started.exists)
                process.send_signal(signum)
                self.assertEqual(process.wait(timeout=10), 128 + signum)
                calls = [json.loads(line) for line in calls_path.read_text().splitlines()]
                self.assertEqual(len(calls), 1, "Cancellation must not start another capture attempt")
                record = self.latest()
                self.assertEqual((record["state"], record["exit_code"]), ("failed", 128 + signum))
                log = Path(record["evidence"], "build.log").read_text()
                self.assertNotIn("retrying once", log)
                self.assertEqual(log.count("Capture evidence retained:"), 1)

    def test_helper_evidence_overrides_reject_compiler_overlap_before_side_effects(self):
        project, launcher = self.fixture_launcher()
        caller = self.root / "caller"
        caller.mkdir()
        script = self.root / "output.sh"
        marker = self.root / "helper-started"
        script.write_text('touch "$HELPER_STARTED"\n')
        alias = self.root / "compiler-alias"
        alias.symlink_to(self.root / "compiler", target_is_directory=True)
        values = [str(self.root / "compiler/report"), "../compiler/report",
                  str(self.root / "compiler"), str(self.root), str(alias / "report")]
        for name in ("FRAMEWINK_ARTIFACTS", "FRAMEWINK_SCREENSHOT_DIRECTORY"):
            for value in values:
                with self.subTest(name=name, value=value):
                    env = dict(self.env, HELPER_STARTED=str(marker), **{name: value})
                    result = subprocess.run([sys.executable, str(launcher), "--script", str(script)],
                                            cwd=caller, env=env, text=True, capture_output=True, timeout=20)
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                    self.assertIn("Evidence and compiler storage must be separate", result.stderr)
                    self.assertFalse(marker.exists())
                    self.assertFalse((self.root / "compiler").exists())

    def test_helper_keeps_caller_cwd_and_absolute_or_symlink_output_paths(self):
        project, launcher = self.fixture_launcher()
        caller = self.root / "caller with spaces"
        caller.mkdir()
        retained = self.root / "retained shots"
        retained.mkdir()
        alias = self.root / "shots alias"
        alias.symlink_to(retained, target_is_directory=True)
        artifacts = self.root / "absolute reports"
        script = self.root / "output.sh"
        script.write_text('pwd -P > "$HELPER_RECORD"\nprintf "%s\\n" "$FRAMEWINK_ARTIFACTS" "$FRAMEWINK_SCREENSHOT_DIRECTORY" >> "$HELPER_RECORD"\n'
                          'mkdir -p "$FRAMEWINK_ARTIFACTS" "$FRAMEWINK_SCREENSHOT_DIRECTORY"\n')
        record = self.root / "helper-paths"
        result = subprocess.run([sys.executable, str(launcher), "--script", str(script)], cwd=caller,
                                env=dict(self.env, HELPER_RECORD=str(record), FRAMEWINK_ARTIFACTS=str(artifacts),
                                         FRAMEWINK_SCREENSHOT_DIRECTORY=str(alias)),
                                text=True, capture_output=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(record.read_text().splitlines(),
                         [str(caller.resolve()), str(artifacts.resolve()), str(retained.resolve())])
        self.assertEqual(self.latest()["working_directory"], str(caller.resolve()))
        self.assertTrue(artifacts.is_dir())
        self.assertTrue(alias.is_symlink())
        self.assertFalse((project / "absolute reports").exists())

    def test_rejects_compiler_output_overrides_before_starting_builds(self):
        shared = str(self.root / "shared-products")
        for setting in ["CONFIGURATION_BUILD_DIR", "OBJROOT", "SYMROOT", "CLANG_MODULE_CACHE_PATH"]:
            for configuration in ["Debug", "Release"]:
                result = self.invoke("--configuration", configuration, "--", setting + "=" + shared, "build")
                self.assertEqual(result.returncode, 2, result.stderr)
            result = self.invoke(env=dict(self.env, **{setting: shared}))
            self.assertEqual(result.returncode, 2, result.stderr)
        self.assertFalse((self.root / "calls.jsonl").exists())
        self.assertFalse((self.root / "compiler").exists())

    def test_rejects_unchecked_configuration_file_output_overrides(self):
        config = self.root / "custom.xcconfig"
        config.write_text("CONFIGURATION_BUILD_DIR = " + str(self.root / "shared") + "\n")
        self.assertEqual(self.invoke("--", "-xcconfig", str(config), "build").returncode, 2)
        self.assertEqual(self.invoke(env=dict(self.env, XCODE_XCCONFIG_FILE=str(config))).returncode, 2)
        self.assertFalse((self.root / "calls.jsonl").exists())
        self.assertFalse((self.root / "compiler").exists())

    def test_discovery_filters_old_runtimes_before_device_preferences(self):
        devices = {"devices": {}}
        for version, name, state in [("16-4", "FrameWink Preferred", "Booted"),
                                     ("17-0", "Compatible", "Shutdown")]:
            devices["devices"]["com.apple.CoreSimulator.SimRuntime.iOS-" + version] = [
                dict(name=name, state=state, udid=family + version, deviceTypeIdentifier=family)
                for family in ["iPhone-14", "iPad-Pro"]]
        env = dict(self.env, FAKE_DEVICES=json.dumps(devices))
        for family, kind in [("iPhone", "iPhone-14"), ("iPad", "iPad-Pro")]:
            result = self.invoke("--simulator-destination", family, env=env)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(kind + "17-0", result.stdout)
        del devices["devices"]["com.apple.CoreSimulator.SimRuntime.iOS-17-0"]
        result = self.invoke("--simulator-destination", "iPhone", env=dict(self.env, FAKE_DEVICES=json.dumps(devices)))
        self.assertEqual(result.returncode, 2)
        self.assertIn("iOS 17", result.stderr)

    def test_external_cache_and_report_paths_are_deferred_before_writes(self):
        external = "/Volumes/FrameWink-Deferred-Unit-Test-Volume/cache"
        link = self.root / "external-link"
        link.symlink_to(external)
        for path in ("/Volumes", external, str(link)):
            cases = [("cache", ["--cache-root", path], self.env),
                     ("report", ["--output", path], self.env),
                     ("result", ["--", "-resultBundlePath", path, "build"], self.env),
                     ("archive", ["--sdk", "iphoneos", "--configuration", "Release",
                                  "--", "-archivePath", path, "archive"], self.env)]
            cases += [(name, [], dict(self.env, **{name: path})) for name in
                      ("FRAMEWINK_BUILD_EVIDENCE_ROOT", "FRAMEWINK_TEST_OUTPUT_ROOT",
                       "FRAMEWINK_ARTIFACTS", "FRAMEWINK_SCREENSHOT_DIRECTORY")]
            for label, arguments, env in cases:
                with self.subTest(path=path, output=label):
                    result = self.invoke(*arguments, env=env)
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                    self.assertIn("External storage is deferred", result.stderr)
        self.assertFalse((self.root / "compiler").exists())
        self.assertFalse((self.root / "evidence").exists())
        self.assertFalse((self.root / "calls.jsonl").exists())

    def test_rejects_legacy_path_and_mismatched_destination(self):
        result = self.invoke(env=dict(self.env, FRAMEWINK_DERIVED_DATA=str(self.root / "legacy")))
        self.assertEqual(result.returncode, 2)
        self.assertIn("FRAMEWINK_BUILD_CACHE_ROOT", result.stderr)
        self.assertEqual(self.invoke("--", "-destination", "generic/platform=iOS", "build").returncode, 2)
        self.assertEqual(self.invoke("--", "archive").returncode, 2)

    def start_held_workflow(self):
        script = self.root / "hold.sh"
        script.write_text('touch "$HOLD_STARTED"\nwhile [ ! -f "$HOLD_RELEASE" ]; do sleep 0.05; done\n')
        env = dict(self.env, HOLD_STARTED=str(self.root / "started"), HOLD_RELEASE=str(self.root / "release"))
        process = subprocess.Popen([sys.executable, str(LAUNCHER), "--script", str(script)], env=env,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(self.stop, process)
        self.wait_for(lambda: (self.root / "started").exists())
        return process

    def stop(self, process):
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=10)
        else:
            process.wait()

    def wait_for(self, predicate):
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if predicate():
                return
            time.sleep(0.02)
        self.fail("Timed out waiting for build process state")

    def test_lock_covers_workflow_consumption_before_next_build(self):
        first = self.start_held_workflow()
        second = subprocess.Popen([sys.executable, str(LAUNCHER)], env=self.env,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(self.stop, second)
        self.wait_for(lambda: len(self.manifests()) == 2)
        self.assertEqual(self.latest()["state"], "waiting-for-lock")
        self.assertFalse((self.root / "calls.jsonl").exists())
        (self.root / "release").touch()
        self.assertEqual(first.wait(timeout=10), 0)
        self.assertEqual(second.wait(timeout=10), 0)

    def test_termination_retains_failure_and_releases_workspace(self):
        process = self.start_held_workflow()
        process.send_signal(signal.SIGTERM)
        self.assertEqual(process.wait(timeout=10), 143)
        self.assertEqual(self.latest()["exit_code"], 143)
        self.assertEqual(self.invoke().returncode, 0)

    def test_closed_console_still_waits_for_workflow_and_finalizes_evidence(self):
        script = self.root / "output.sh"
        script.write_text('touch "$HOLD_STARTED"\nsleep 0.2\nprintf "Retained output\\n"\nsleep 0.2\ntouch "$HOLD_FINISHED"\n')
        env = dict(self.env, HOLD_STARTED=str(self.root / "started"), HOLD_FINISHED=str(self.root / "finished"))
        process = subprocess.Popen([sys.executable, str(LAUNCHER), "--script", str(script)], env=env,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.addCleanup(self.stop, process)
        self.addCleanup(process.stderr.close)
        process.stdout.readline()
        process.stdout.readline()
        self.wait_for(lambda: (self.root / "started").exists())
        process.stdout.close()
        self.assertEqual(process.wait(timeout=10), 0, process.stderr.read().decode())
        self.assertTrue((self.root / "finished").exists())
        record = self.latest()
        self.assertEqual((record["state"], record["exit_code"]), ("passed", 0))
        self.assertIn("Retained output", Path(record["evidence"], "build.log").read_text())
        self.assertEqual(self.invoke().returncode, 0)

    def test_log_write_failure_reaps_workflow_and_records_failure(self):
        spec = importlib.util.spec_from_file_location("framewink_build_local", LAUNCHER)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        script = self.root / "log-failure.sh"
        script.write_text('printf "Output\\n"\nsleep 20\n')
        args = argparse.Namespace(sdk="iphonesimulator", configuration="Debug", unsigned=False,
                                  fresh=False, cache_root=str(self.root / "compiler"),
                                  output=None, script=str(script), arguments=[])
        children = []
        real_popen, real_open = subprocess.Popen, Path.open

        def spawn(*arguments, **kwargs):
            child = real_popen(*arguments, **kwargs)
            children.append(child)
            self.addCleanup(self.stop, child)
            return child

        class FailingLog:
            def __enter__(self):
                return self

            def __exit__(self, *unused):
                pass

            def write(self, unused):
                raise OSError("fixture log write failure")

        def open_path(path, *arguments, **kwargs):
            return FailingLog() if path.name == "build.log" else real_open(path, *arguments, **kwargs)

        with mock.patch.dict(os.environ, self.env, clear=True), mock.patch.object(Path, "open", open_path), \
                mock.patch.object(module.subprocess, "Popen", spawn):
            self.assertEqual(module.run(args), 2)
        workflow = [child for child in children if child.args[0] == "/bin/bash"][-1]
        self.assertIsNotNone(workflow.poll())
        record = self.latest()
        self.assertEqual((record["state"], record["exit_code"]), ("failed", 2))
        self.assertIn("fixture log write failure", record["launcher_error"])
        self.assertEqual(self.invoke().returncode, 0)

    def test_waiting_run_can_be_cancelled_without_interrupting_lock_owner(self):
        first = self.start_held_workflow()
        second = subprocess.Popen([sys.executable, str(LAUNCHER)], env=self.env,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(self.stop, second)
        self.wait_for(lambda: len(self.manifests()) == 2)
        self.wait_for(lambda: self.latest().get("lock_contended", False))
        second.send_signal(signal.SIGTERM)
        self.assertEqual(second.wait(timeout=10), 143)
        self.assertEqual(self.latest()["exit_code"], 143)
        self.assertIsNone(first.poll())
        (self.root / "release").touch()
        self.assertEqual(first.wait(timeout=10), 0)

    def test_runtime_only_helper_arguments_share_workspace(self):
        script = self.root / "runtime-helper.sh"
        script.write_text('printf "%s\\n" "$@"\n')
        keys = []
        for mode in ["prepare", "prepare-storekit"]:
            result = self.invoke("--script", str(script), "--", mode)
            self.assertEqual(result.returncode, 0, result.stderr)
            keys.append(self.latest()["cache_key"])
        self.assertEqual(keys[0], keys[1])

    def test_explicit_helper_architectures_get_distinct_workspaces(self):
        script = self.root / "helper.sh"
        script.write_text("true\n")
        keys = []
        for device, architecture in [("phone", "arm64"), ("pad", "arm64"), ("phone", "x86_64")]:
            destination = "platform=iOS Simulator,id=" + device + ",arch=" + architecture
            result = self.invoke("--script", str(script), env=dict(self.env, FRAMEWINK_IPHONE_DESTINATION=destination))
            self.assertEqual(result.returncode, 0, result.stderr)
            keys.append(self.latest()["cache_key"])
        self.assertEqual(keys[0], keys[1])
        self.assertNotEqual(keys[0], keys[2])

    def test_full_local_gate_preserves_matrix_and_approved_exclusions(self):
        result = self.invoke("--unsigned", "--script", str(REPO / "scripts/test_local.sh"))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = [json.loads(line) for line in (self.root / "calls.jsonl").read_text().splitlines()]
        self.assertEqual(len(calls), 3)
        self.assertEqual(len({call[call.index("-derivedDataPath") + 1] for call in calls}), 1)
        bundles = [Path(call[call.index("-resultBundlePath") + 1]) for call in calls]
        self.assertEqual(len(set(bundles)), 3)
        for call in calls:
            self.assertIn("-skip-testing:FrameWinkTests/StoreKitConfigurationTests/testStoreKitTestAskToBuyReturnsPendingWithoutUnlocking", call)
            self.assertIn("-skip-testing:FrameWinkUITests/MarketingLandscapeScreenshotTests", call)
        self.assertIn("-skip-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testPersonalFrameRotatesAndSwipeAdvancesToTheNextPhoto", calls[2])


if __name__ == "__main__":
    unittest.main()
