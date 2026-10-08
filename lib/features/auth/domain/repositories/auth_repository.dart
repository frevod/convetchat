import '../entities/auth_mode.dart';

abstract class AuthRepository() {
  Future<void> checkHomeserver(String homeserver);

  Future<void> loginWithSso({required AuthMode mode});

  Future<void> loginWithToken(String token);

  Future<void> logout();

  String? get serverName;
}
