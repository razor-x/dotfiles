"""Caller-owned Firstmate ship integration; private fixtures, never real sessions."""

import json
import os
import shutil
import signal
import subprocess
import tempfile
import unittest
from pathlib import Path

BIN = Path(__file__).resolve().parents[1] / "home/dot_local/exact_bin"
WRAPPER = BIN / "executable_firstmate"
NATIVE_ZELLIJ = shutil.which("zellij")


class FirstmateWrapper(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="firstmate-wrapper-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.anchor = self.root / "anchor with spaces"
        self.anchor.mkdir()
        self.entry = self.root / "data/firstmate/bin/fm-board.sh"
        self.entry.parent.mkdir(parents=True)
        self.capture = self.root / "capture.json"
        self.entry.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, signal, sys\n"
            "with open(os.environ['FIRSTMATE_CAPTURE'], 'w') as f:\n"
            "    json.dump({'env':dict(os.environ),'args':sys.argv[1:],'pid':os.getpid()},f)\n"
            "if os.environ.get('TEST_SIGNAL'): os.kill(os.getpid(),signal.SIGTERM)\n"
            "sys.exit(int(os.environ.get('TEST_EXIT','0')))\n"
        )
        self.entry.chmod(0o755)
        fakebin = self.root / "bin"
        fakebin.mkdir()
        for name, version in (
            ("pi", "1.5.0"),
            ("zellij", "zellij 0.45.1"),
            ("nono", "nono 0.81.0"),
        ):
            file = fakebin / name
            file.write_text(
                '#!/bin/sh\n[ "$1" = --version ] || exit 99\nprintf "%s\\n" "'
                + version
                + '"\n'
            )
            file.chmod(0o755)
        self.env = dict(
            os.environ,
            XDG_DATA_HOME=str(self.root / "data"),
            FIRSTMATE_CAPTURE=str(self.capture),
            PATH=f"{fakebin}:{os.environ['PATH']}",
        )
        for name in list(self.env):
            if name.startswith("FM_") or name in (
                "TREEHOUSE_ROOT",
                "NM_HOME",
                "NM_TEST_START_DAEMON",
                "LAVISH_AXI_STATE_DIR",
                "PI_CODING_AGENT_SESSION_DIR",
                "ZELLIJ_SOCKET_DIR",
            ):
                del self.env[name]

    def launch(self, *args, env=None, input=None):
        return subprocess.run(
            ["sh", str(WRAPPER), *map(str, args)],
            check=False,
            cwd=self.root,
            env=dict(self.env, **(env or {})),
            capture_output=True,
            text=True,
            input=input,
        )

    def captured(self):
        return json.loads(self.capture.read_text())

    def test_relative_anchor_and_literal_runtime_arguments(self):
        result = self.launch(
            "anchor with spaces", "--model", "a model", "", "--", "a;echo not-a-command"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        capture = self.captured()
        self.assertEqual(
            capture["args"][:4], ["--anchor", str(self.anchor), "--", "nono"]
        )
        layout = capture["args"][capture["args"].index("--layout-string") + 1]
        self.assertIn(
            'args "--approve" "--model" "a model" "" "--" "a;echo not-a-command"',
            layout,
        )
        self.assertEqual(
            capture["env"]["FM_HOME"], str(self.anchor / ".firstmate/home")
        )
        self.assertEqual(
            capture["env"]["PI_CODING_AGENT_SESSION_DIR"],
            str(self.anchor / ".firstmate/pi/sessions"),
        )
        self.assertEqual(
            capture["env"]["FM_TASK_TMP_ROOT"], str(self.anchor / ".firstmate/task-tmp")
        )
        self.assertEqual(capture["env"]["NM_TEST_START_DAEMON"], "1")
        self.assertIn(
            "NM_TEST_START_DAEMON", capture["env"]["FM_WORKER_ENV_FORWARD"].splitlines()
        )
        self.assertEqual(list(self.anchor.iterdir()), [])

    def test_physical_anchor_and_conflicting_inherited_selectors(self):
        link = self.root / "linked anchor"
        link.symlink_to(self.anchor)
        result = self.launch(
            link, env={"FM_ANCHOR": str(link), "FM_HOME": str(link / ".firstmate/home")}
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.captured()["env"]["FM_ANCHOR"], str(self.anchor))
        self.capture.unlink()
        for key in ("FM_ANCHOR", "FM_HOME"):
            with self.subTest(selector=key):
                result = self.launch(link, env={key: str(self.root / "wrong")})
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.capture.exists())

    def test_caller_preferences_and_explicit_empty_forwarding_are_preserved(self):
        supplied = {
            "FM_WORKER_ENV_FORWARD": "",
            "FM_BACKEND": "caller-backend",
            "FM_ZELLIJ_SESSION": "caller-session",
            "FM_TASK_TMP_ROOT": str(self.anchor / ".firstmate/custom-tmp"),
            "NM_TEST_START_DAEMON": "0",
            "NM_HOME": str(self.anchor / ".firstmate/custom-nm"),
            "LAVISH_AXI_STATE_DIR": str(self.anchor / ".firstmate/custom-prompts"),
            "PI_CODING_AGENT_DIR": str(self.root / "host-pi-preferences"),
            "PI_SKIP_VERSION_CHECK": "0",
            "PI_CLIPBOARD_OSC52": "caller-setting",
            "NO_MISTAKES_NO_UPDATE_CHECK": "0",
        }
        result = self.launch(self.anchor, env=supplied)
        self.assertEqual(result.returncode, 0, result.stderr)
        for key, value in supplied.items():
            self.assertEqual(self.captured()["env"][key], value, key)
        self.assertEqual(
            self.captured()["env"]["XDG_CACHE_HOME"],
            str(self.anchor / ".firstmate/cache"),
        )
        self.assertFalse((self.root / "host-pi-preferences").exists())

    def test_session_paths_cannot_escape_and_ids_are_not_guessed(self):
        for args in (
            ("--session", str(self.root / "outside.jsonl")),
            ("--session-dir=" + str(self.root / "outside"),),
            ("--session", "unscoped-session-id"),
        ):
            with self.subTest(args=args):
                self.assertNotEqual(self.launch(self.anchor, *args).returncode, 0)
                self.assertFalse(self.capture.exists())
        inside = self.anchor / ".firstmate/pi/sessions/inside.jsonl"
        result = self.launch(self.anchor, "--session", inside)
        self.assertEqual(result.returncode, 0, result.stderr)
        layout = self.captured()["args"][-1]
        self.assertIn(str(inside), layout)

    def test_feature_versions_fail_without_falling_back(self):
        pi = self.root / "bin/pi"
        pi.write_text("#!/bin/sh\nprintf '1.2.0\\n'\n")
        pi.chmod(0o755)
        result = self.launch(self.anchor)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Pi 1.5.0+", result.stderr)
        self.assertFalse(self.capture.exists())

    def test_missing_and_nondirectory_anchors(self):
        self.assertNotEqual(self.launch().returncode, 0)
        self.assertNotEqual(self.launch(self.root / "missing").returncode, 0)
        file = self.root / "file"
        file.touch()
        self.assertNotEqual(self.launch(file).returncode, 0)
        self.assertFalse(self.capture.exists())

    def test_exit_status_and_exec_signal_behavior(self):
        result = self.launch(self.anchor, env={"TEST_EXIT": "37"})
        self.assertEqual(result.returncode, 37)
        process = subprocess.Popen(
            ["sh", str(WRAPPER), str(self.anchor)],
            cwd=self.root,
            env=dict(self.env, TEST_SIGNAL="1"),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        process.communicate(timeout=5)
        self.assertEqual(self.captured()["pid"], process.pid)
        self.assertEqual(process.returncode, -signal.SIGTERM)

    def test_external_transport_delegators_preserve_arguments_and_status(self):
        for command in ("fm-dock", "fm-undock"):
            entry = self.entry.with_name(command + ".sh")
            entry.write_text(self.entry.read_text())
            entry.chmod(0o755)
            result = subprocess.run(
                [
                    "sh",
                    str(BIN / ("executable_" + command)),
                    "--anchor",
                    str(self.anchor),
                    "--literal",
                ],
                cwd=self.root,
                check=False,
                env=dict(self.env, TEST_EXIT="37"),
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 37, result.stderr)
            self.assertEqual(
                self.captured()["args"], ["--anchor", str(self.anchor), "--literal"]
            )

    @unittest.skipUnless(
        NATIVE_ZELLIJ, "zellij absent; native layout parser unavailable"
    )
    def test_generated_layout_is_accepted_by_real_zellij(self):
        private = self.root / "native-zellij"
        private.mkdir()
        config = private / "config.kdl"
        config.write_text("")
        env = dict(
            self.env,
            XDG_CONFIG_HOME=str(private / "config"),
            XDG_CACHE_HOME=str(private / "cache"),
            XDG_DATA_HOME=str(private / "data"),
            XDG_STATE_HOME=str(private / "state"),
            ZELLIJ_CONFIG_DIR=str(private / "config/zellij"),
            ZELLIJ_SOCKET_DIR=str(private / "socket"),
            ZELLIJ_LAYOUT_DIR=str(private / "layouts"),
        )
        env.pop("ZELLIJ_CONFIG_FILE", None)
        for value in (
            "a model",
            "control" + "".join(map(chr, range(1, 32))),
            r"literal\u001b",
            "unicode\u2028value",
        ):
            with self.subTest(value=value):
                result = self.launch(self.anchor, "--model", value)
                self.assertEqual(result.returncode, 0, result.stderr)
                layout = self.captured()["args"][-1]
                checked = subprocess.run(
                    [
                        NATIVE_ZELLIJ,
                        "--config",
                        str(config),
                        "--data-dir",
                        str(private / "data"),
                        "--layout-string",
                        layout,
                        "setup",
                        "--check",
                    ],
                    env=env,
                    cwd=private,
                    check=False,
                    capture_output=True,
                    text=True,
                    timeout=10,
                )
                self.assertEqual(checked.returncode, 0, checked.stdout + checked.stderr)


if __name__ == "__main__":
    unittest.main()
