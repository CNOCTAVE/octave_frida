/*
 * qrc_hook.js -- example GumJS script shipped with octave_frida.
 *
 * Logs CreateFileW paths and the first bytes of every ReadFile buffer.
 * When reversing LyricTools.exe this is how the .qrc input and its
 * 11-byte magic (98 25 b0 ac e3 02 83 68 e8 fc 6c) were observed.
 */
'use strict';

var k32 = 'kernel32.dll';

function wideToString (ptr) {
  try { return ptr.readUtf16String(); } catch (e) { return '<invalid>'; }
}

try {
  var k32 = Process.getModuleByName('kernel32.dll');
  Interceptor.attach(k32.getExportByName('CreateFileW'), {
    onEnter: function (args) {
      this.path = wideToString(args[0]);
    },
    onLeave: function (retval) {
      if (this.path && this.path.toLowerCase().indexOf('.qrc') >= 0) {
        send({ type: 'create', path: this.path, handle: retval.toString() });
      }
    }
  });
} catch (e) {
  send({ type: 'error', where: 'CreateFileW', message: String(e) });
}

try {
  Interceptor.attach(k32.getExportByName('ReadFile'), {
    onEnter: function (args) {
      this.buf = args[1];
      this.lenPtr = args[2];
    },
    onLeave: function (retval) {
      if (retval.toInt32() === 0) return;
      var n = 0;
      try { n = this.lenPtr.readUInt32(); } catch (e) { return; }
      var take = Math.min(n, 24);
      var bytes = [];
      for (var i = 0; i < take; i++) {
        bytes.push(('0' + this.buf.add(i).readU8().toString(16)).slice(-2));
      }
      send({ type: 'read', bytes: n, head: bytes.join(' ') });
    }
  });
} catch (e) {
  send({ type: 'error', where: 'ReadFile', message: String(e) });
}

send({ type: 'ready', script: 'qrc_hook.js' });
