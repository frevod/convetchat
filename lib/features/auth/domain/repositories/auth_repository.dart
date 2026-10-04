abstract class AuthRepository() {
  Future<void> checkHomeserver(String homeserver);

  Future<void> loginWithSso();

  Future<void> logout();

  String? get serverName;
}
