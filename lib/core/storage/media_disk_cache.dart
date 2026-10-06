import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaDiskCache {
  static const _rootName = 'media_cache';

  static Future<Directory> resolveDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, _rootName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Directory? _root;

  Future<Directory> _dir() async {
    final cached = _root;
    if (cached != null) return cached;
    final dir = await resolveDir();
    _root = dir;
    return dir;
  }

  String _fileName(String key) {
    final safe = key.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');
    final trimmed = safe.length > 80 ? safe.substring(safe.length - 80) : safe;
    return '${key.hashCode}_$trimmed.bin';
  }

  Future<File> _fileFor(String key) async {
    final dir = await _dir();
    return File(p.join(dir.path, _fileName(key)));
  }

  Future<Directory> directory() => _dir();

  Future<bool> hasBytes(String key) async {
    try {
      final file = await _fileFor(key);
      if (!await file.exists()) return false;
      return await file.length() > 0;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?> getBytes(String key) async {
    try {
      final file = await _fileFor(key);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        try {
          await file.delete();
        } catch (_) {}
        return null;
      }
      try {
        await file.setLastModified(DateTime.now());
      } catch (_) {}
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> putBytes(
    String key,
    Uint8List bytes, {
    int maxBytes = 0,
  }) async {
    if (bytes.isEmpty) return;
    try {
      final file = await _fileFor(key);
      await file.writeAsBytes(bytes, flush: false);
      await enforceQuota(maxBytes);
    } catch (_) {}
  }

  Future<int> totalSize() async {
    try {
      final dir = await _dir();
      var total = 0;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        try {
          total += await entity.length();
        } catch (_) {}
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<int> fileCount() async {
    try {
      final dir = await _dir();
      var count = 0;
      await for (final entity in dir.list()) {
        if (entity is File) count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<void> enforceQuota(int maxBytes) async {
    if (maxBytes <= 0) return;
    try {
      final dir = await _dir();
      final files = <File>[];
      await for (final entity in dir.list()) {
        if (entity is File) files.add(entity);
      }
      if (files.isEmpty) return;
      final stats = <MapEntry<File, ({int size, DateTime modified})>>[];
      var total = 0;
      for (final file in files) {
        try {
          final stat = await file.stat();
          final size = stat.size;
          total += size;
          stats.add(MapEntry(file, (size: size, modified: stat.modified)));
        } catch (_) {}
      }
      if (total <= maxBytes) return;
      final entries = stats.toList()
        ..sort((a, b) => a.value.modified.compareTo(b.value.modified));
      for (final entry in entries) {
        if (total <= maxBytes) break;
        try {
          await entry.key.delete();
          total -= entry.value.size;
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final dir = await _dir();
      await for (final entity in dir.list()) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
  }
}
