## Copyright (C) 2026 Yu Hongbo <yuhongbo@member.fsf.org>, CNOCTAVE
## SPDX-License-Identifier: GPL-3.0-or-later
##
## -*- texinfo -*-
## @deftypefn {} {@var{msgs} =} frida_messages (@var{result})
## Read the JSONL message log produced by @code{frida_run} and return a cell
## array of message structs.  Return an empty cell array when nothing was sent.
## @end deftypefn
function msgs = frida_messages (result)
  msgs = {};
  if (! isfield (result, 'message_file'))
    return;
  endif
  f = result.message_file;
  if (isempty (dir (f)))
    return;
  endif
  fid = fopen (f, 'r');
  if (fid == -1)
    return;
  endif
  unwind_protect
    while (! feof (fid))
      line = fgetl (fid);
      if (ischar (line) && ! isempty (strtrim (line)))
        msgs{end+1} = jsondecode (line);
      endif
    endwhile
  unwind_protect_cleanup
    fclose (fid);
  end_unwind_protect
endfunction
