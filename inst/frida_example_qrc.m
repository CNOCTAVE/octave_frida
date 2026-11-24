## Copyright (C) 2026 Yu Hongbo <yuhongbo@member.fsf.org>, CNOCTAVE
## SPDX-License-Identifier: GPL-3.0-or-later
##
## -*- texinfo -*-
## @deftypefn {} {@var{res} =} frida_example_qrc (@var{target}, @var{duration})
## Attach the bundled @file{qrc_hook.js} to @var{target} for @var{duration}
## seconds and return the Frida result struct.  This is the instrumentation
## step used while reversing the QRC decryption inside LyricTools.exe.
## @end deftypefn
function res = frida_example_qrc (target, duration = 5)
  here = fileparts (which ('frida_example_qrc'));
  script = fullfile (here, 'examples', 'qrc_hook.js');
  cfg = struct ('script', script, 'target', target, 'mode', 'attach', 'duration', duration);
  res = frida_run (cfg);
endfunction
