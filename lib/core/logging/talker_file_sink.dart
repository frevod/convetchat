import 'dart:async';
import 'dart:collection';
import 'dart:io';

abstract final class TalkerFileSink() {
  static const _fileName = 'talker.log';
  static const _backupFileName = 'talker.log.1';

  static const _maxFileBytes = 512 * 1024;

  static const _maxBufferLines = 500;

  static File? _file;
  static final Queue<String> _buffer = Queue<String>();

  static File? get logFile => _file;

  static Future<void> init() async {
    if (_file != null) return;
    try {
      final dir = Directory('/data/user/0/com.convet.convetchat/files');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('${dir.path}/$_fileName');
      if (await file.exists() && await file.length() > _maxFileBytes) {
        final backup = File('${dir.path}/$_backupFileName');
        if (await backup.exists()) await backup.delete();
        await file.rename(backup.path);
      }
      if (!await file.exists()) await file.create(recursive: true);
      _file = file;
      while (_buffer.isNotEmpty) {
        final line = _buffer.removeFirst();
        unawaited(_append(line));
      }
    } catch (_) {
      _file = null;
    }
  }

  static void write(String message) {
    try {
      final file = _file;
      if (file == null) {
        if (_buffer.length >= _maxBufferLines) _buffer.removeFirst();
        _buffer.addLast(message);
        return;
      }
      unawaited(_append(message));
    } catch (_) {}
  }

  static Future<void> _append(String message) async {
    try {
      await _file?.writeAsString('$message\n', mode: FileMode.append);
    } catch (_) {}
  }
}
