import 'package:universal_html/html.dart' as html;
import 'token_storage.dart';

class WebTokenStorage extends TokenStorage {
  @override
  Future<void> saveAccessToken(String token) async {
    html.window.localStorage['access_token'] = token;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    html.window.localStorage['refresh_token'] = token;
  }

  @override
  Future<String?> getAccessToken() async {
    return html.window.localStorage['access_token'];
  }

  @override
  Future<String?> getRefreshToken() async {
    return html.window.localStorage['refresh_token'];
  }

  @override
  Future<void> clear() async {
    html.window.localStorage.remove('access_token');
    html.window.localStorage.remove('refresh_token');
  }
}