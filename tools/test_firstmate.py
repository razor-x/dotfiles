"""Contract for the minimal public firstmate wrapper; no real capsule or server."""

import json
import os
import signal
import subprocess
import tempfile
import unittest
from pathlib import Path

WRAPPER = (
    Path(__file__).resolve().parents[1]
    / "home/dot_local/exact_bin/executable_firstmate"
)


class FirstmateWrapper(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="firstmate-wrapper-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.anchor = self.root / "anchor with spaces"
        self.anchor.mkdir()
        self.entry = self.root / "data/firstmate/bin/fm-firstmate.sh"
        self.entry.parent.mkdir(parents=True)
        self.capture = self.root / "capture.json"
        self.entry.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, signal, sys\n"
            "with open(os.environ['FIRSTMATE_CAPTURE'], 'w') as f:\n"
            "    json.dump({'env': dict(os.environ), 'args': sys.argv[1:], 'pid': os.getpid()}, f)\n"
            "if os.environ.get('TEST_SIGNAL'): os.kill(os.getpid(), signal.SIGTERM)\n"
            "sys.exit(int(os.environ.get('TEST_EXIT', '0')))\n"
        )
        self.entry.chmod(0o755)
        self.env = dict(
            os.environ,
            XDG_DATA_HOME=str(self.root / "data"),
            FIRSTMATE_CAPTURE=str(self.capture),
        )
        for name in list(self.env):
            if name.startswith("FM_"):
                del self.env[name]

    def launch(self, *args, env=None):
        return subprocess.run(
            ["sh", str(WRAPPER), *map(str, args)],
            check=False,
            cwd=self.root,
            env=dict(self.env, **(env or {})),
            capture_output=True,
            text=True,
        )

    def captured(self):
        return json.loads(self.capture.read_text())

    def test_relative_anchor_and_forwarded_arguments(self):
        result = self.launch(
            "anchor with spaces", "--model", "a model", "", "--", "a;echo not-a-command"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.captured()["args"],
            ["--model", "a model", "", "--", "a;echo not-a-command"],
        )
        self.assertEqual(self.captured()["env"]["FM_ANCHOR"], str(self.anchor))
        self.assertEqual(
            self.captured()["env"]["FM_HOME"], str(self.anchor / ".firstmate/home")
        )
        self.assertEqual(list(self.anchor.iterdir()), [])

    def test_physical_anchor_overrides_inherited_paths(self):
        link = self.root / "linked anchor"
        link.symlink_to(self.anchor)
        self.assertEqual(
            self.launch(
                link, env={"FM_ANCHOR": "/wrong-anchor", "FM_HOME": "/wrong-home"}
            ).returncode,
            0,
        )
        self.assertEqual(self.captured()["env"]["FM_ANCHOR"], str(self.anchor))
        self.assertEqual(
            self.captured()["env"]["FM_HOME"], str(self.anchor / ".firstmate/home")
        )

    def test_only_two_path_variables_are_added(self):
        self.assertEqual(self.launch(self.anchor).returncode, 0)
        env = self.captured()["env"]
        # Shell-maintained '_' and PWD are not wrapper path configuration.
        added = set(env) - set(self.env) - {"_", "PWD"}
        self.assertEqual(added, {"FM_ANCHOR", "FM_HOME"})
        for key in set(self.env) - {"_", "PWD"}:
            self.assertEqual(env[key], self.env[key], key)

    def test_missing_and_nondirectory_anchors(self):
        self.assertNotEqual(self.launch().returncode, 0)
        self.assertNotEqual(self.launch(self.root / "absent").returncode, 0)
        file = self.root / "file"
        file.touch()
        self.assertNotEqual(self.launch(file).returncode, 0)
        self.assertFalse(self.capture.exists())

    def test_exit_status(self):
        self.assertEqual(
            self.launch(self.anchor, env={"TEST_EXIT": "37"}).returncode, 37
        )

    def test_exec_and_signal_behavior(self):
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


if __name__ == "__main__":
    unittest.main()
