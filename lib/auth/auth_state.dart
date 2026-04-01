import 'package:budget_app/auth/token_storage.dart';
import 'package:flutter/cupertino.dart';

class AuthState extends ChangeNotifier {
  final TokenStorage storage;

  bool _isAuthorized = false;
  bool _isLoading = true;

  bool get isAuthorized => _isAuthorized;
  bool get isLoading => _isLoading;

  AuthState(this.storage);

  Future<void> init() async {
    final token = await storage.getAccessToken();

    _isAuthorized = token != null;
    _isLoading = false;

    notifyListeners();
  }

  Future<void> login(String token) async {
    await storage.saveAccessToken(token);
    _isAuthorized = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await storage.clear();
    _isAuthorized = false;
    notifyListeners();
  }
}