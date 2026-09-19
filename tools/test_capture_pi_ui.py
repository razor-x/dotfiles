"""Capture helper tests; no X11 access needed."""

import os
import socket
import unittest
from unittest.mock import patch

from capture_pi_ui import current_window, handle


class CaptureUiTests(unittest.TestCase):
    def test_environment_window_is_used(self):
        with patch.dict(os.environ, {"WINDOWID": "456"}):
            self.assertEqual(current_window(), "456")

    def test_missing_window_is_rejected(self):
        with patch.dict(os.environ, {}, clear=True), self.assertRaises(ValueError):
            current_window()

    def test_invalid_window_is_rejected(self):
        with (
            patch.dict(os.environ, {"WINDOWID": "not-a-window"}),
            self.assertRaises(ValueError),
        ):
            current_window()

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
