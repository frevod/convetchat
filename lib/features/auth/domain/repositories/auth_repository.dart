abstract class AuthRepository() {
  Future<void> checkHomeserver(String homeserver);

  Future<void> login({required String username, required String password});

  Future<void> logout();

  String? get serverName;

  Future<bool> supportsSso();

  Future<void> loginWithSso();
}
