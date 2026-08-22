from kittens.tui.handler import result_handler
from kitty.boss import Boss
from kitty.clipboard import get_clipboard_string, set_clipboard_string
from kitty.window import CommandOutput


def main(args: list[str]) -> None:
    pass


@result_handler(no_ui=True)
def handle_result(
    args: list[str], data: None, target_window_id: int, boss: Boss
) -> None:
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return
    output = window.cmd_output(CommandOutput.last_non_empty)
    if output:
        clipboard = get_clipboard_string().lstrip("\n")
        prompt = "$ " + clipboard
        set_clipboard_string(prompt + ("" if prompt.endswith("\n") else "\n") + output)
