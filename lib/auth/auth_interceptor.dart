import 'dart:async';

import 'package:budget_app/auth/token_storage.dart';
import 'package:budget_app/context/variable_holder.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final TokenStorage storage;

  bool _isRefreshing = false;
  List<Completer<String>> _retryQueue = [];

  AuthInterceptor(this.dio, this.storage);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;

      // Prevent infinite loop
      if (requestOptions.extra['retry'] == true) {
        return handler.next(err);
      }

      try {
        final newToken = await _refreshToken();

        // Retry original request
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
        requestOptions.extra['retry'] = true;

        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // Refresh failed → logout
        await _logout();
        return handler.next(err);
      }
    }

    handler.next(err);
  }

  Future<String> _refreshToken() async {
    if (_isRefreshing) {
      final completer = Completer<String>();
      _retryQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await storage.getRefreshToken();

      final response = await dio.post(
        VariableHolder.getAuthBaseUrl() + '/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'X-Api-Key': '11112'}), // important!
      );

      final newAccessToken = response.data['token'];

      await storage.saveAccessToken(newAccessToken);

      final newRefreshToken = response.data['refreshToken'];

      await storage.saveRefreshToken(newRefreshToken);

      // Resolve all waiting requests
      for (var completer in _retryQueue) {
        completer.complete(newAccessToken);
      }
      _retryQueue.clear();

      return newAccessToken;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _logout() async {
    await storage.clear();

    // TODO: Navigate to login screen
  }
}
