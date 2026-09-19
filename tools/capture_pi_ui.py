#!/usr/bin/env python3

"""Human-launched X11 capture server. Only capture\n is accepted over the socket."""

import argparse
import fcntl
import os
import re
import signal
import socket
import stat
import struct
import subprocess
import sys
from pathlib import Path


def fingerprint(window: str) -> bytes:
    result = subprocess.check_output(
        ["xprop", "-id", window, "WM_CLASS", "_NET_WM_PID"],
        stderr=subprocess.DEVNULL,
        timeout=3,
    )
    if b'"kitty"' not in result.lower() or not re.search(
        rb"_NET_WM_PID\(CARDINAL\) = [0-9]+", result
    ):
        raise ValueError("Target must be a Kitty window with a PID")
    return result


def capture(window: str, identity: bytes) -> bytes:
    if fingerprint(window) != identity:
        raise ValueError("Target window identity changed")
    image = subprocess.check_output(
        ["import", "-silent", "-window", window, "png:-"],
        stderr=subprocess.DEVNULL,
        timeout=8,
    )
    if fingerprint(window) != identity:
        raise ValueError("Target window identity changed during capture")
    return image


def handle(connection: socket.socket, window: str, identity: bytes) -> None:
    connection.settimeout(3)
    _, uid, _ = struct.unpack(
        "3i", connection.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12)
    )
    if uid != os.getuid():
        return
    with connection.makefile("rb") as request:
        if request.readline(9) != b"capture\n":
            connection.sendall(b"ERROR: Only capture is supported\n")
            return
        try:
            image = capture(window, identity)
        except (ValueError, OSError, subprocess.SubprocessError) as error:
            connection.sendall(f"ERROR: {error}\n".encode())
            return
        connection.sendall(image)


def select_window(window: str | None) -> str:
    if window is None:
        print(
            "Click the dedicated Pi window (all its splits will be captured).",
            flush=True,
        )
        window = subprocess.check_output(["xdotool", "selectwindow"], text=True).strip()
    if not re.fullmatch(r"(?:0x[0-9a-fA-F]+|[0-9]+)", window):
        raise ValueError("Invalid X11 window ID")
    return window


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Serve captures of one Kitty X11 window."
    )
    parser.add_argument(
        "window_id", nargs="?", help="Omit to select a window by clicking"
    )
    window = select_window(parser.parse_args().window_id)
    identity = fingerprint(window)
    directory = Path(f"/tmp/pi-capture-ui-{os.getuid()}")
    directory.mkdir(mode=0o700, exist_ok=True)
    info = directory.lstat()
    if (
        not stat.S_ISDIR(info.st_mode)
        or info.st_uid != os.getuid()
        or info.st_mode & 0o077
    ):
        raise SystemExit("Capture socket directory must be owned by you and mode 0700")
    # Hold the directory inode: no lock files or stale-lock recovery needed.
    lock = os.open(directory, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        endpoint = directory / "capture.sock"
        endpoint.unlink(missing_ok=True)
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as server:
            server.bind(str(endpoint))
            endpoint.chmod(0o600)
            server.listen(1)
            print(f"Capture socket: {endpoint}\nStop: Ctrl-C", flush=True)
            try:
                while True:
                    connection, _ = server.accept()
                    with connection:
                        try:
                            handle(connection, window, identity)
                        except OSError:
                            pass  # Disconnected or timed-out client; accept the next request.
            finally:
                endpoint.unlink(missing_ok=True)
    finally:
        os.close(lock)


if __name__ == "__main__":
    for shutdown_signal in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(shutdown_signal, lambda *_: sys.exit(0))
    try:
        main()
    except KeyboardInterrupt:
        pass
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        sys.exit(str(error))
