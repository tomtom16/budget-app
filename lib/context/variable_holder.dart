

import 'package:budget_app/context/auth_interceptor.dart';
import 'package:budget_app/enums/enums.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:budget_app/dto/category_data.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VariableHolder {
  static AppProfile profile = AppProfile.azure;

  static List<CategoryData> CATEGORIES = [];

  static Dio dio = new Dio();
  static bool _dioPrepared = false;

  static FlutterSecureStorage storage = FlutterSecureStorage();

  static List<CategoryData> getCategories() {
    return CATEGORIES;
  }

  static void setCategories(List<CategoryData> categories) {
    CATEGORIES = categories;
  }

  static void setAppProfile(AppProfile prof) {
    profile = prof;
  }

  static String getBaseUrl() {
    switch (profile) {
      case AppProfile.azure:
        return "https://budget-service.20.105.38.239.sslip.io";
      case AppProfile.local:
      default:
        return "http://localhost:8088";
    }
  }

  static String getAuthBaseUrl() {
    switch (profile) {
      case AppProfile.azure:
        return "https://auth.20.105.38.239.sslip.io";
      case AppProfile.local:
      default:
        return "http://localhost:8090";
    }
  }

  static Dio getDio() {
    if (!_dioPrepared) {
      // Add logging interceptor
      dio.interceptors.add(AuthInterceptor(dio, storage));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('=== API REQUEST ===');
            debugPrint('URL: ${options.uri}');
            debugPrint('Method: ${options.method}');
            debugPrint('Headers: ${options.headers}');
            debugPrint('Data: ${options.data}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('=== API RESPONSE ===');
            debugPrint('Status Code: ${response.statusCode}');
            debugPrint('Data: ${response.data}');
            return handler.next(response);
          },
          onError: (DioException e, handler) {
            debugPrint('=== API ERROR ===');
            debugPrint('Error: ${e.message}');
            debugPrint('Response: ${e.response?.data}');
            return handler.next(e);
          },
        ),
      );

      _dioPrepared = true;
    }

    return dio;
  }

}