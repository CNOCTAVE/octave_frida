## Copyright (C) 2026 Yu Hongbo <yuhongbo@member.fsf.org>, CNOCTAVE
## SPDX-License-Identifier: GPL-3.0-or-later
##
## -*- texinfo -*-
## @deftypefn {} {@var{res} =} frida_run (@var{cfg})
## Run one Frida instrumentation session.  @var{cfg} is a struct with fields
## @code{script} (path to a GumJS file), @code{target} (process name, PID or
## argv list), @code{mode} ("spawn" or "attach"), @code{duration} (seconds),
## optional @code{device}, @code{stop_file}, @code{pid_hint} and
## @code{kill_on_exit}.  Returns status plus the path to a JSONL message log.
## @end deftypefn
function res = frida_run (cfg)
  if (nargin < 1 || ! isstruct (cfg))
    print_usage ();
  endif
  ctx = frida_init ();

  if (! isfield (cfg, 'script'))
    error ('frida_run: cfg.script is required');
  endif
  if (isempty (dir (cfg.script)))
    error ('frida_run: script file not found: %s', cfg.script);
  endif
  if (! isfield (cfg, 'target'))
    cfg.target = 'notepad.exe';
  endif
  if (! isfield (cfg, 'mode'))
    cfg.mode = 'attach';
  endif
  if (! isfield (cfg, 'duration'))
    cfg.duration = 5;
  endif
  if (! isfield (cfg, 'device'))
    cfg.device = '';
  endif
  if (! isfield (cfg, 'stop_file'))
    cfg.stop_file = '';
  endif
  if (! isfield (cfg, 'pid_hint'))
    cfg.pid_hint = 0;
  endif
  if (! isfield (cfg, 'kill_on_exit'))
    cfg.kill_on_exit = true;
  endif

  base = tempname ();
  cfg_file = [base '_config.json'];
  status_file = [base '_status.json'];
  message_file = [base '_messages.jsonl'];

  cfg.script = frida_fwd (cfg.script);
  cfg.message_file = frida_fwd (message_file);
  cfg.status_file = frida_fwd (status_file);
  cfg.stop_file = frida_fwd (cfg.stop_file);
  if (! isempty (cfg.stop_file) && isempty (dir (cfg.stop_file)))
    fid = fopen (cfg.stop_file, 'w');
    if (fid != -1)
      fclose (fid);
    endif
  endif

  fid = fopen (cfg_file, 'w');
  if (fid == -1)
    error ('frida_run: cannot write temporary config');
  endif
  fwrite (fid, jsonencode (cfg));
  fclose (fid);

  pyq = frida_quote_python (ctx.python);
  cmd = sprintf ('%s "%s" "%s"', pyq, frida_fwd (ctx.driver), frida_fwd (cfg_file));
  [st, out] = system (cmd);

  status = struct ('ok', false, 'error', 'status file missing', 'version', ctx.version, 'pid', 0, 'messages', 0);
  if (! isempty (dir (status_file)))
    try
      status = jsondecode (fileread (status_file));
    catch
      status.error = out;
    end_try_catch
  else
    status.error = out;
  endif

  res = struct ('status', status, 'message_file', message_file, 'config_file', cfg_file, 'raw_output', out);
endfunction
