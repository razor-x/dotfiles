import os

from kitty.boss import Boss, Window
from kittens.tui.handler import result_handler


def main(args: list[str]) -> str:
    pass


@result_handler(no_ui=True)
def handle_result(
    args: list[str], answer: str, target_window_id: int, boss: Boss
) -> None:
    if len(args) == 1:
        return

    cmd = args[1]

    window = _find_window_running_cmd(cmd, boss)
    if window is None:
        boss.launch("--cwd=current", "--location=before", *args[1:])
    else:
        boss.set_active_window(window, switch_os_window_if_needed=True)


def _find_window_running_cmd(cmd: str, boss: Boss) -> Window | None:
    tab = boss.active_tab
    if tab is None:
        return None

    for window in tab:
        for process in window.child.foreground_processes:
            cmdline = process.get("cmdline") or []
            if len(cmdline) == 0:
                continue

            foreground_cmd = cmdline[0]
            if foreground_cmd == cmd or os.path.basename(foreground_cmd) == cmd:
                return window

    return None
