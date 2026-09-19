#!/usr/bin/env python3
"""Host-side adb screenshot server for Phase 4 integration checkpoints."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

PORT = 9474
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots" / "registry_aura_phase4" / "verified"


def find_adb() -> str:
    env = os.environ.get("ADB") or os.environ.get("ANDROID_HOME")
    candidates = []
    if os.environ.get("ADB"):
        candidates.append(os.environ["ADB"])
    home = Path.home()
    for root in (
        os.environ.get("ANDROID_HOME"),
        os.environ.get("ANDROID_SDK_ROOT"),
        str(home / "Library/Android/sdk"),
        str(home / "Android/Sdk"),
    ):
        if root:
            candidates.append(str(Path(root) / "platform-tools" / "adb"))
    which = shutil.which("adb")
    if which:
        candidates.append(which)
    for path in candidates:
        if path and Path(path).exists():
            return path
    raise SystemExit("adb not found")


ADB = find_adb()


def run(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, check=True, capture_output=True, text=True)


def capture(name: str) -> Path:
    if not name.replace("_", "").replace("-", "").isalnum():
        raise ValueError(f"invalid checkpoint name: {name}")
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / f"{name}.png"
    tmp = "/data/local/tmp/phase4_capture.png"
    run([ADB, "shell", "screencap", "-p", tmp])
    run([ADB, "pull", tmp, str(dest)])
    if dest.stat().st_size < 1024:
        raise RuntimeError(f"capture too small: {dest}")
    print(f"captured {dest}", flush=True)
    return dest


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args: object) -> None:
        sys.stderr.write("capture-host: " + (fmt % args) + "\n")

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path not in {"/capture", "/health"}:
            self.send_error(404)
            return
        if parsed.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
            return
        name = (parse_qs(parsed.query).get("name") or [""])[0]
        try:
            path = capture(name)
        except Exception as error:  # noqa: BLE001
            body = str(error).encode()
            self.send_response(500)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        body = str(path).encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"listening on 127.0.0.1:{PORT} adb={ADB}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
