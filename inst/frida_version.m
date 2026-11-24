## Copyright (C) 2026 Yu Hongbo <yuhongbo@member.fsf.org>, CNOCTAVE
## SPDX-License-Identifier: GPL-3.0-or-later
##
## -*- texinfo -*-
## @deftypefn {} {} frida_version ()
## Print the Frida version used by octave_frida.
## @end deftypefn
function frida_version ()
  ctx = frida_init ();
  printf ('Frida %s (python: %s)\n', ctx.version, ctx.python);
endfunction
