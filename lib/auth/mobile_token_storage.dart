import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_storage.dart';

class MobileTokenStorage extends TokenStorage {
  final _storage = const FlutterSecureStorage();

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: 'access_token', value: token);

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: 'refresh_token', value: token);

  @override
  Future<String?> getAccessToken() =>
      _storage.read(key: 'access_token');

  @override
  Future<String?> getRefreshToken() =>
      _storage.read(key: 'refresh_token');

  @override
  Future<void> clear() => _storage.deleteAll();

}