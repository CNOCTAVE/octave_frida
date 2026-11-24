## Copyright (C) 2026 Yu Hongbo <yuhongbo@member.fsf.org>, CNOCTAVE
## SPDX-License-Identifier: GPL-3.0-or-later
##
## -*- texinfo -*-
## @deftypefn {} {@var{ctx} =} frida_init ()
## Find a Python interpreter that can import the system-installed Frida and
## return a context struct.  No runtime is bundled: Frida must be installed in
## the interpreter (for example with pip install frida).
## @end deftypefn
function ctx = frida_init ()
  persistent cached
  if (! isempty (cached))
    ctx = cached;
    return;
  endif

  here = fileparts (which ('frida_init'));
  driver = fullfile (here, 'frida_driver.py');
  devices_driver = fullfile (here, 'frida_devices.py');
  if (isempty (dir (driver)))
    error ('frida_init: frida_driver.py not found next to frida_init.m');
  endif

  candidates = {};
  envpy = getenv ('FRIDA_PYTHON');
  if (! isempty (envpy))
    candidates{end+1} = envpy;
  endif
  candidates{end+1} = 'python3';
  candidates{end+1} = 'python';
  candidates{end+1} = 'py -3';

  if (ispc ())
    devnull = '2>NUL';
  else
    devnull = '2>/dev/null';
  endif
  ctx = struct ('python', '', 'version', '', 'driver', driver, 'devices_driver', devices_driver);
  for i = 1:numel (candidates)
    py = candidates{i};
    cmd = sprintf ('%s -c "import frida; print(frida.__version__)" %s', ...
                   frida_quote_python (py), devnull);
    [st, out] = system (cmd);
    lines = strsplit (out, '\n');
    ver = '';
    for j = numel (lines):-1:1
      if (! isempty (strtrim (lines{j})))
        ver = strtrim (lines{j});
        break;
      endif
    endfor
    if (st == 0 && ! isempty (ver))
      ctx.python = py;
      ctx.version = ver;
      break;
    endif
  endfor

  if (isempty (ctx.python))
    error ('frida_init: no Python with Frida found. Install frida into a Python interpreter (pip install frida), or set FRIDA_PYTHON to that interpreter.');
  endif
  cached = ctx;
endfunction
