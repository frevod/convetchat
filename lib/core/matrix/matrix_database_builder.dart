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
  final databaseDirectory = await getApplicationSupportDirectory();
  final path = await _databasePath(clientName);
  final factory = _databaseFactory();

  databaseFactory = factory;

  final database = await factory.openDatabase(
    path,
    options: OpenDatabaseOptions(version: 1),
  );

  return MatrixSdkDatabase.init(
    clientName,
    database: database,
    sqfliteFactory: factory,
    maxFileSize: 1000 * 1000 * 10,
    fileStorageLocation: databaseDirectory.uri,
    deleteFilesAfterDuration: const Duration(days: 30),
  );
}
