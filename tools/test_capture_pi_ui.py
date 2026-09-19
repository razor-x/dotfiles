"""Capture helper tests; no X11 access needed."""

import socket
import unittest
from unittest.mock import patch

from capture_pi_ui import handle, select_window


class CaptureUiTests(unittest.TestCase):
    def test_explicit_window_skips_selection(self):
        with patch("capture_pi_ui.subprocess.check_output") as select:
            self.assertEqual(select_window("0x123"), "0x123")
            select.assert_not_called()

    def test_click_selects_window(self):
        with patch(
            "capture_pi_ui.subprocess.check_output", return_value="123\n"
        ) as select:
            self.assertEqual(select_window(None), "123")
            select.assert_called_once_with(["xdotool", "selectwindow"], text=True)

    def test_invalid_window_is_rejected(self):
        with self.assertRaises(ValueError):
            select_window("not-a-window")

    def test_only_capture_requests_are_accepted(self):
        for request, expected_calls in [(b"capture\n", 1), (b"exec\n", 0)]:
            with self.subTest(request=request):
                client, server = socket.socketpair()
                with (
                    client,
                    server,
                    patch("capture_pi_ui.capture", return_value=b"PNG") as capture,
                ):
                    client.sendall(request)
                    handle(server, "123", b"identity")
                    self.assertEqual(
                        client.recv(1024),
                        b"PNG"
                        if expected_calls
                        else b"ERROR: Only capture is supported\n",
                    )
                    self.assertEqual(capture.call_count, expected_calls)
