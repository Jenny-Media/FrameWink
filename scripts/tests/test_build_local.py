"""Behavior checks for cache isolation, retention, locking and existing test gates."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest

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
 if '-resultBundlePath' in sys.argv:
  os.makedirs(sys.argv[sys.argv.index('-resultBundlePath')+1],exist_ok=False)
 print('Recorded build output')
 sys.exit(int(os.environ.get('FAKE_EXIT','0')))
''')
        self.tool("xcrun", '''import json,sys
if '--show-sdk-build-version' in sys.argv: print('test-sdk-'+sys.argv[2])
elif '--show-sdk-version' in sys.argv: print('27.1')
elif 'simctl' in sys.argv:
 print(json.dumps({'devices':{'com.apple.CoreSimulator.SimRuntime.iOS-27-1':[
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

    def test_missing_external_mount_and_symlink_fail_without_fallback(self):
        missing = "/Volumes/FrameWink-Missing-Unit-Test-Volume/cache"
        link = self.root / "external-link"
        link.symlink_to(missing)
        for root in [missing, str(link)]:
            result = self.invoke("--cache-root", root)
            self.assertEqual(result.returncode, 2)
            self.assertIn("not mounted", result.stderr)
        self.assertFalse((self.root / "compiler").exists())

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
