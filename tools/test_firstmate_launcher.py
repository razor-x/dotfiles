"""Exercise the Fish launcher against a recording core, without live vessels."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

LAUNCHER = (
    Path(__file__).resolve().parents[1]
    / "home/dot_local/share/exact_plugin/exact_firstmate/exact_functions/firstmate.fish"
)


@unittest.skipUnless(shutil.which("fish"), "fish is not installed")
class FirstmateLauncherTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="firstmate-launcher-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.anchor = self.root / "anchor with spaces"
        self.anchor.mkdir()
        self.core = self.root / "core"
        self.bin = self.core / "bin"
        self.bin.mkdir(parents=True)
        self.calls = self.root / "calls"
        script = self.bin / "fm-anchor.sh"
        script.write_text(
            '#!/bin/sh\nprintf "%s\\0" "$@" > "$TEST_CALLS"\nexit "${TEST_EXIT:-0}"\n'
        )
        script.chmod(0o755)
        for name in ("pi", "tmux", "nono"):
            tool = self.bin / name
            tool.write_text("#!/bin/sh\nexit 99\n")
            tool.chmod(0o755)

    def launch(self, *arguments, exit_code=0):
        return subprocess.run(
            [
                shutil.which("fish"),
                "--no-config",
                "--command",
                (
                    'source "$TEST_LAUNCHER"; '
                    'function __firstmate_core; printf "%s\\n" "$TEST_CORE"; end; '
                    "firstmate $argv"
                ),
                "--",
                str(self.anchor),
                *arguments,
            ],
            env={
                **os.environ,
                "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
                "TEST_LAUNCHER": str(LAUNCHER),
                "TEST_CORE": str(self.core),
                "TEST_CALLS": str(self.calls),
                "TEST_EXIT": str(exit_code),
            },
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )

    def arguments(self):
        return self.calls.read_bytes().decode().rstrip("\0").split("\0")

    def test_cancel_sail_targets_selected_vessel(self):
        result = self.launch("--vessel", "red", "sail", "--cancel")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.arguments(),
            ["sail", "--anchor", str(self.anchor), "--vessel", "red", "--cancel"],
        )

    def test_cancel_sail_preserves_core_failure(self):
        result = self.launch("sail", "--cancel", exit_code=37)
        self.assertEqual(result.returncode, 37)

    def test_cancel_sail_rejects_conflicting_launcher_operations(self):
        for arguments in (
            ("sail", "--cancel", "--sail-to", "remote"),
            ("sail", "--cancel", "--scuttle"),
        ):
            with self.subTest(arguments=arguments):
                result = self.launch(*arguments)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.calls.exists())

    def test_ordinary_launch_still_uses_core_open(self):
        result = self.launch("--model", "a model")
        self.assertEqual(result.returncode, 0, result.stderr)
        arguments = self.arguments()
        self.assertEqual(
            arguments[:6], ["open", "--anchor", str(self.anchor), "--agent", "pi", "--"]
        )
        self.assertEqual(arguments[-2:], ["--model", "a model"])
