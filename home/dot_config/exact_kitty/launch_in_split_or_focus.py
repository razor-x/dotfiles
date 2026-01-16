#!/usr/bin/env python3
import argparse
import json
import os
import shlex
import subprocess
from typing import Iterable, Optional


def _kitty_control_prefix() -> list[str]:
    listen_on = os.environ.get("KITTY_LISTEN_ON")
    if listen_on:
        return ["kitty", "@", "--to", listen_on]
    return ["kitty", "@"]


def _run_command(command: Iterable[str]) -> str:
    return subprocess.check_output(list(command), text=True)


def _find_window_id(command: str) -> Optional[int]:
    command_tokens = shlex.split(command)
    if not command_tokens:
        return None

    target = command_tokens[0]
    data = json.loads(_run_command([*_kitty_control_prefix(), "ls"]))

    for os_window in data:
        if not os_window.get("is_active"):
            continue
        for tab in os_window.get("tabs", []):
            if not tab.get("is_active"):
                continue
            for window in tab.get("windows", []):
                for process in window.get("foreground_processes", []):
                    cmdline = process.get("cmdline", [])
                    if not cmdline:
                        continue
                    cmd0 = cmdline[0]
                    if cmd0 == target or os.path.basename(cmd0) == target:
                        return window.get("id")

    return None


def _focus_window(window_id: int) -> None:
    subprocess.check_call(
        [*_kitty_control_prefix(), "focus-window", "--match", f"id:{window_id}"]
    )


def _launch_command(command: str, location: str) -> None:
    subprocess.check_call(
        [
            *_kitty_control_prefix(),
            "launch",
            "--cwd=current",
            f"--location={location}",
            *shlex.split(command),
        ]
    )


def _normalize_args(args: Iterable[str]) -> list[str]:
    normalized = list(args)
    if normalized and normalized[0].endswith(".py"):
        normalized = normalized[1:]
    return normalized


def main(args: Iterable[str]):
    parser = argparse.ArgumentParser(
        description=(
            "Focus an existing kitty split running a command or launch it in a new split."
        )
    )
    parser.add_argument("--command", required=True, help="Command to run or focus")
    parser.add_argument(
        "--before",
        action="store_true",
        help="Launch the split before the current window",
    )
    parsed = parser.parse_args(_normalize_args(args))
    return {"command": parsed.command, "before": parsed.before}


def handle_result(args, result, target_window_id, boss):
    command = result["command"]
    before = result["before"]

    window_id = _find_window_id(command)
    if window_id:
        _focus_window(window_id)
        return

    location = "before" if before else "after"
    _launch_command(command, location)
