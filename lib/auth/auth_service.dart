import 'package:dio/dio.dart';
import 'token_storage.dart';

class AuthService {
  final Dio dio;
  final TokenStorage storage;

  AuthService(this.dio, this.storage);

  Future<void> login(String username, String password) async {
    final response = await dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });

    await storage.saveAccessToken(response.data['accessToken']);
    await storage.saveRefreshToken(response.data['refreshToken']);
  }

  Future<void> logout() async {
    await storage.clear();
  }

  Future<bool> isLoggedIn() async {
    return await storage.getAccessToken() != null;
  }
}