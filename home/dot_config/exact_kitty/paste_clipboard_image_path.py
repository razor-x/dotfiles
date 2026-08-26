import os
import tempfile

from kittens.tui.handler import result_handler
from kitty.boss import Boss

IMAGE_SUFFIXES = {
    "image/png": ".png",
    "image/jpeg": ".jpg",
    "image/gif": ".gif",
    "image/webp": ".webp",
}


def main(args: list[str]) -> None:
    pass


@result_handler(no_ui=True)
def handle_result(
    args: list[str], data: None, target_window_id: int, boss: Boss
) -> None:
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    mime = next(
        (
            mime
            for mime in boss.clipboard.get_available_mime_types_for_paste()
            if mime in IMAGE_SUFFIXES
        ),
        None,
    )
    if mime is None:
        window.paste_text(boss.clipboard.get_text())
        return

    image = boss.clipboard.get_mime_data(mime)
    if not image:
        return

    fd, path = tempfile.mkstemp(prefix="pi-clipboard-", suffix=IMAGE_SUFFIXES[mime])
    with os.fdopen(fd, "wb") as file:
        file.write(image)
    window.paste_text(f"@{path} ")
