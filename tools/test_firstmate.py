"""Local vessel caller policy and native tmux argument parsing; no user sessions."""

import json
import os
import shutil
import signal
import subprocess
import tempfile
import unittest
from pathlib import Path

WRAPPER = (
    Path(__file__).resolve().parents[1]
    / "home/dot_local/exact_bin/executable_firstmate"
)
TMUX = shutil.which("tmux")
CORE = os.environ.get("FIRSTMATE_TEST_CORE")


class LocalVessel(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="firstmate-anchor-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.anchor = self.root / "anchor with spaces"
        self.anchor.mkdir()
        self.entry = self.root / "data/firstmate/bin/fm-anchor.sh"
        self.entry.parent.mkdir(parents=True)
        self.capture = self.root / "capture.json"
        recorder = (
            "#!/usr/bin/env python3\nimport json, os, signal, sys\n"
            "if sys.argv[1] == 'init':\n"
            "    os.makedirs(os.environ['NM_HOME'],exist_ok=True)\n"
            "    open(sys.argv[3] + '/.firstmate.json','w').write('{}')\n"
            "    sys.exit(0)\n"
            "json.dump({'env':dict(os.environ),'args':sys.argv[1:],'pid':os.getpid()},open(os.environ['TEST_CAPTURE'],'w'))\n"
            "if os.environ.get('TEST_SIGNAL'): os.kill(os.getpid(),signal.SIGTERM)\n"
            "sys.exit(int(os.environ.get('TEST_EXIT','0')))\n"
        )
        self.entry.write_text(recorder)
        self.entry.chmod(0o755)
        binaries = self.root / "bin"
        binaries.mkdir()
        for name in ("pi", "tmux", "nono"):
            executable = binaries / name
            executable.write_text(recorder)
            executable.chmod(0o755)
        self.env = dict(
            os.environ,
            XDG_DATA_HOME=str(self.root / "data"),
            TEST_CAPTURE=str(self.capture),
            PATH=f"{binaries}:{os.environ['PATH']}",
        )
        for key in list(self.env):
            if key.startswith("FM_") or key in (
                "TREEHOUSE_ROOT",
                "NM_HOME",
                "LAVISH_AXI_STATE_DIR",
                "PI_CODING_AGENT_SESSION_DIR",
                "NM_TEST_START_DAEMON",
                "TMUX_TMPDIR",
            ):
                del self.env[key]

    def launch(self, *arguments, env=None, input="y\n"):
        return subprocess.run(
            ["sh", str(WRAPPER), *map(str, arguments)],
            cwd=self.root,
            env=dict(self.env, **(env or {})),
            input=input,
            capture_output=True,
            text=True,
            check=False,
        )

    def captured(self):
        return json.loads(self.capture.read_text())

    def test_local_layout_and_literal_arguments(self):
        arguments = ("--model", "a model", "", "--", "literal ; argument")
        result = self.launch("anchor with spaces", *arguments)
        self.assertEqual(result.returncode, 0, result.stderr)
        record = self.captured()
        vessel = self.anchor / ".firstmate"
        self.assertEqual(record["env"]["FM_HOME"], str(vessel))
        self.assertEqual(
            record["env"]["FM_PROJECTS_OVERRIDE"], str(vessel / "projects")
        )
        self.assertEqual(record["env"]["TREEHOUSE_ROOT"], str(vessel / "worktrees"))
        self.assertEqual(
            record["env"]["PI_CODING_AGENT_SESSION_DIR"], str(vessel / "pi/sessions")
        )
        self.assertEqual(record["env"]["FM_BACKEND"], "tmux")
        self.assertEqual(
            record["args"][-7:], [str(self.root / "bin/pi"), "--approve", *arguments]
        )
        allowed = [
            record["args"][i + 1]
            for i, arg in enumerate(record["args"])
            if arg == "--allow"
        ]
        self.assertEqual(allowed, [str(vessel)])

    def test_decline_missing_anchor_and_unsupported_backend_never_launch(self):
        for arguments, env, answer in (
            ((self.anchor,), {}, "n\n"),
            ((self.root / "missing",), {}, "y\n"),
            ((self.anchor,), {"FM_BACKEND": "zellij"}, "y\n"),
        ):
            result = self.launch(*arguments, env=env, input=answer)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(self.capture.exists())
            self.assertEqual(list(self.anchor.iterdir()), [])

    def test_physical_anchor_and_inherited_conflicts(self):
        link = self.root / "alias"
        link.symlink_to(self.anchor)
        result = self.launch(link)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.captured()["env"]["FM_ANCHOR"], str(self.anchor))
        self.capture.unlink()
        result = self.launch(link, env={"FM_HOME": str(self.root / "other")})
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.capture.exists())

    def test_personal_inputs_empty_forwarding_and_private_routing(self):
        supplied = {
            "FM_WORKER_ENV_FORWARD": "",
            "PI_SKIP_VERSION_CHECK": "0",
            "PI_CODING_AGENT_DIR": str(self.root / "host-preferences"),
            "TMUX": "/host/socket,1,0",
            "TMUX_PANE": "%1",
        }
        result = self.launch(self.anchor, env=supplied)
        self.assertEqual(result.returncode, 0, result.stderr)
        actual = self.captured()["env"]
        for key in (
            "FM_WORKER_ENV_FORWARD",
            "PI_SKIP_VERSION_CHECK",
            "PI_CODING_AGENT_DIR",
        ):
            self.assertEqual(actual[key], supplied[key])
        self.assertNotIn("TMUX", actual)
        self.assertNotIn("TMUX_PANE", actual)
        self.assertEqual(actual["TMUX_TMPDIR"], str(self.anchor / ".firstmate/tmux"))
        self.assertFalse((self.root / "host-preferences").exists())

    def test_session_paths_status_and_exec_pid(self):
        for argument in ("unscoped-id", str(self.root / "outside.jsonl")):
            result = self.launch(self.anchor, "--session", argument)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(self.capture.exists())
        inside = self.anchor / ".firstmate/pi/sessions/session.jsonl"
        result = self.launch(self.anchor, "--session", inside, env={"TEST_EXIT": "37"})
        self.assertEqual(result.returncode, 37, result.stderr)
        process = subprocess.Popen(
            ["sh", str(WRAPPER), str(self.anchor)],
            env=dict(self.env, TEST_SIGNAL="1"),
            cwd=self.root,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        process.communicate(timeout=5)
        self.assertEqual(process.returncode, -signal.SIGTERM)
        self.assertEqual(self.captured()["pid"], process.pid)

    @unittest.skipUnless(TMUX, "native tmux is unavailable")
    def test_native_tmux_parser_preserves_terminal_semicolons(self):
        values = ("explain this;", ";", r"\;", "double;;", "", "literal ; argument")
        result = self.launch(self.anchor, *values)
        self.assertEqual(result.returncode, 0, result.stderr)
        arguments = self.captured()["args"][-len(values) :]
        private = self.root / "tmux"
        private.mkdir()
        config = private / "tmux.conf"
        config.write_text("set -s exit-empty off\n")
        env = dict(
            self.env,
            HOME=str(private),
            TMUX_TMPDIR=str(private),
            XDG_CONFIG_HOME=str(private / "config"),
            XDG_CACHE_HOME=str(private / "cache"),
            XDG_DATA_HOME=str(private / "data"),
            XDG_STATE_HOME=str(private / "state"),
        )
        env.pop("TMUX", None)
        env.pop("TMUX_PANE", None)
        command = [TMUX, "-L", "private-parser", "-f", str(config)]
        try:
            subprocess.run(
                [*command, "start-server"],
                env=env,
                check=True,
                capture_output=True,
                timeout=10,
            )
            for value, argument in zip(values, arguments, strict=True):
                decoded = subprocess.run(
                    [*command, "display-message", "-p", "--", argument],
                    env=env,
                    check=False,
                    capture_output=True,
                    text=True,
                    timeout=10,
                )
                self.assertEqual(decoded.returncode, 0, decoded.stderr)
                self.assertEqual(decoded.stdout, value + "\n")
        finally:
            subprocess.run(
                [*command, "kill-server"],
                env=env,
                check=False,
                capture_output=True,
                timeout=10,
            )

    @unittest.skipUnless(
        CORE, "set FIRSTMATE_TEST_CORE for real caller/core integration"
    )
    def test_real_core_gate(self):
        self.entry.unlink()
        self.entry.symlink_to(Path(CORE).resolve())
        result = self.launch(self.anchor, "--model", "literal model")
        self.assertEqual(result.returncode, 0, result.stderr)
        metadata = self.anchor / ".firstmate.json"
        record = json.loads(metadata.read_text())
        self.assertTrue(record["anchored"])
        self.assertEqual(record["backend"], "tmux")
        self.assertEqual(
            (self.anchor / ".firstmate/no-mistakes/config.yaml").read_text(),
            "agent: pi\n",
        )
        record["anchored"] = False
        metadata.write_text(json.dumps(record))
        self.capture.unlink()
        result = self.launch(self.anchor)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.capture.exists())


if __name__ == "__main__":
    unittest.main()
