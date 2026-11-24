#!/usr/bin/env python3
# Copyright (C) 2026 Yu Hongbo <yuhongbo@member.fsf.org>, CNOCTAVE
# SPDX-License-Identifier: GPL-3.0-or-later
"""
frida_driver.py -- one-shot Frida session driven by octave_frida.

Usage:
    python frida_driver.py <config.json>

The Octave side writes a JSON config file (script path, target, mode,
duration, message file, ...), calls this driver with `system`, then reads
back the JSONL message file and the status JSON.  Using files instead of
command-line arguments avoids shell quoting problems on both Linux and
Windows.

Only the public Frida Python API is used.  Frida must be installed in the
Python interpreter selected by frida_init (for example with pip install
frida); this package does not bundle a runtime.
"""

import json
import os
import re
import sys
import time
from datetime import datetime, timezone

def fix_path(p):
    """Accept both Windows and MSYS2-style paths (Octave's built-in Python)."""
    p = str(p).replace("\\", "/")
    if os.name == "nt":
        return p
    return re.sub(r"^([A-Za-z]):/", lambda m: "/" + m.group(1).lower() + "/", p)

import frida  # noqa: E402


def write_json(path, obj):
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(obj, fh, ensure_ascii=False, indent=2)


def append_jsonl(path, obj):
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(obj, ensure_ascii=False) + "\n")


def main():
    if len(sys.argv) < 2:
        print("usage: frida_driver.py <config.json>", file=sys.stderr)
        return 2

    with open(fix_path(sys.argv[1]), "r", encoding="utf-8") as fh:
        cfg = json.load(fh)

    message_file = fix_path(cfg["message_file"])
    status_file = fix_path(cfg["status_file"])
    stop_file = fix_path(cfg.get("stop_file", ""))
    script_file = fix_path(cfg["script"])
    with open(script_file, "r", encoding="utf-8") as fh:
        source = fh.read()

    with open(message_file, "w", encoding="utf-8") as fh:
        fh.write("")

    messages = []

    def on_message(message, data):
        rec = {
            "ts": datetime.now(timezone.utc).isoformat(),
            "message": message,
            "data": "" if data is None else data.hex(),
        }
        messages.append(rec)
        append_jsonl(message_file, rec)

    status = {"ok": False, "version": frida.__version__, "pid": 0, "error": ""}
    session = None
    script = None
    pid = 0
    spawned = False

    try:
        manager = frida.get_device_manager()
        device_name = cfg.get("device", "")
        device = manager.get_device(device_name) if device_name else manager.get_local_device()

        target = cfg.get("target", "")
        mode = cfg.get("mode", "attach")
        if mode == "spawn":
            argv = target if isinstance(target, list) else [target]
            pid = device.spawn(argv)
            spawned = True
        else:
            target = str(target)
            if target.isdigit():
                pid = int(target)
            else:
                session = device.attach(target)
                pid = int(cfg.get("pid_hint", 0))

        if session is None:
            session = device.attach(pid)

        script = session.create_script(source)
        script.on("message", on_message)
        script.load()

        if spawned:
            device.resume(pid)

        duration = float(cfg.get("duration", 5))
        deadline = time.monotonic() + duration
        while time.monotonic() < deadline:
            if stop_file and os.path.exists(stop_file):
                break
            time.sleep(0.05)

        status["ok"] = True
        status["pid"] = pid
    except Exception as exc:  # noqa: BLE001 -- surfaced to Octave as status.error
        status["error"] = "%s: %s" % (type(exc).__name__, exc)
    finally:
        try:
            if script is not None:
                script.unload()
        except Exception:
            pass
        try:
            if session is not None:
                session.detach()
        except Exception:
            pass
        try:
            if spawned and cfg.get("kill_on_exit", True):
                frida.kill(pid)
        except Exception:
            pass

    status["messages"] = len(messages)
    write_json(status_file, status)
    print(json.dumps(status, ensure_ascii=False))
    return 0 if status["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
