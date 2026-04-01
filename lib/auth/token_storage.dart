abstract class TokenStorage {
  bool _initialized = false;

  bool isInitialized() {
    return _initialized;
  }

  void setInitialized(bool init) {
    _initialized = init;
  }

  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);

  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();

  Future<void> clear();

  Future<bool> hasToken() async {
    return await getAccessToken() != null;
  }
}