#!/usr/bin/env python3
# Copyright (C) 2026 Yu Hongbo <yuhongbo@member.fsf.org>, CNOCTAVE
# SPDX-License-Identifier: GPL-3.0-or-later
"""List Frida devices as JSON for octave_frida."""
import json
import sys

import frida  # noqa: E402

manager = frida.get_device_manager()
print(json.dumps([d.name for d in manager.enumerate_devices()], ensure_ascii=False))
