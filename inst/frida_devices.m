## Copyright (C) 2026 Yu Hongbo <yuhongbo@member.fsf.org>, CNOCTAVE
## SPDX-License-Identifier: GPL-3.0-or-later
##
## -*- texinfo -*-
## @deftypefn {} {@var{devices} =} frida_devices ()
## Return a cell array with the names of all Frida devices.
## @end deftypefn
function devices = frida_devices ()
  ctx = frida_init ();
  pyq = frida_quote_python (ctx.python);
  cmd = sprintf ('%s "%s"', pyq, frida_fwd (ctx.devices_driver));
  [st, out] = system (cmd);
  if (st != 0)
    error ('frida_devices: %s', out);
  endif
  devices = jsondecode (strtrim (out));
  if (ischar (devices))
    devices = {devices};
  endif
endfunction
