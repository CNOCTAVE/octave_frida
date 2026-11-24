## Copyright (C) 2026 Yu Hongbo <yuhongbo@member.fsf.org>, CNOCTAVE
## SPDX-License-Identifier: GPL-3.0-or-later
##
## -*- texinfo -*-
## @deftypefn {} {} frida_selftest ()
## Verify the system Frida install: print version and enumerate devices.
## No process is spawned or attached, so the test is safe everywhere.
## @end deftypefn
function frida_selftest ()
  ctx = frida_init ();
  printf ('Frida %s via %s\n', ctx.version, ctx.python);
  d = frida_devices ();
  printf ('devices: %d\n', numel (d));
  for i = 1:numel (d)
    printf ('  - %s\n', d{i});
  endfor
endfunction
