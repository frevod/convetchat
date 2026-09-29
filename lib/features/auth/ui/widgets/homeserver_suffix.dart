import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/auth/domain/repositories/auth_repository.dart';
import 'package:matrix/matrix.dart';

String? homeserverSuffix() {
  final name = getIt<AuthRepository>().serverName;
  if (name != null && name.isNotEmpty) return ':$name';
  final host = getIt<Client>().homeserver?.host;
  return (host == null || host.isEmpty) ? null : ':$host';
}
