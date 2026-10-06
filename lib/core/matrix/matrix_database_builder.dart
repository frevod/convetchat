import 'dart:io';

import 'package:convetchat/core/storage/media_disk_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<DatabaseApi> buildMatrixDatabase(String clientName) async {
  if (kIsWeb) {
    return MatrixSdkDatabase.init(clientName);
  }

  return _constructDatabase(clientName);
}

Future<String> _databasePath(String clientName) async {
  final databaseDirectory = await getApplicationSupportDirectory();
  return p.join(databaseDirectory.path, '$clientName.sqlite');
}

DatabaseFactory _databaseFactory() {
  return switch (defaultTargetPlatform) {
    .android || .iOS => databaseFactory,
    .windows || .linux || .macOS || .fuchsia => createDatabaseFactoryFfi(),
  };
}

Future<DatabaseApi> _constructDatabase(String clientName) async {
  final path = await _databasePath(clientName);
  final factory = _databaseFactory();

  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.fuchsia:
      databaseFactory = factory;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      break;
  }

  final database = await factory.openDatabase(
    path,
    options: OpenDatabaseOptions(version: 1),
  );

  final cacheDir = await MediaDiskCache.resolveDir();
  await _adoptLegacyBlobs(cacheDir);

  return MatrixSdkDatabase.init(
    clientName,
    database: database,
    sqfliteFactory: factory,
    maxFileSize: 200 * 1000 * 1000,
    fileStorageLocation: cacheDir.uri,
    deleteFilesAfterDuration: null,
  );
}

Future<void> _adoptLegacyBlobs(Directory cacheDir) async {
  try {
    final support = await getApplicationSupportDirectory();
    await for (final entity in support.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('.')) continue;
      if (name.endsWith('.sqlite')) continue;
      if (name.contains('.sqlite-')) continue;
      final target = File(p.join(cacheDir.path, name));
      if (await target.exists()) {
        try {
          await entity.delete();
        } catch (_) {}
        continue;
      }
      try {
        await entity.rename(target.path);
      } catch (_) {}
    }
  } catch (_) {}
}
