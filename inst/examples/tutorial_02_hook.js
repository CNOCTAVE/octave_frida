'use strict';
// 教程示例 2：hook 真实 API，读取参数 + 改写返回值
// LoadLibraryExW(lpLibFileName, hFile, dwFlags) 返回一个模块句柄
try {
  var k32 = Process.getModuleByName('kernel32.dll');
  Interceptor.attach(k32.getExportByName('LoadLibraryExW'), {
    onEnter: function (args) {
      // args[0] 是 UTF-16 字符串指针；用 this 把值带到 onLeave
      this.name = args[0].readUtf16String();
    },
    onLeave: function (retval) {
      send({ type: 'load', name: this.name, handle: retval.toString() });
      // retval.replace(ptr(0));  // 取消注释可让加载失败
    }
  });
  send({ type: 'ready' });
} catch (e) {
  send({ type: 'error', message: String(e) });
}
