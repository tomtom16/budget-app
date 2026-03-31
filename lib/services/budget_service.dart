import 'dart:convert';

import 'package:budget_app/context/variable_holder.dart';
import 'package:budget_app/dto/category_data.dart';
import 'package:budget_app/dto/login_request.dart';
import 'package:budget_app/dto/transaction_data.dart';
import 'package:budget_app/enums/enums.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../dto/login_response.dart';
import '../dto/register_response.dart';

class BudgetService {
  static Color parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  static Color getColorForCategory(String categoryName) {
    Color result = Colors.grey;

    for (var cat in VariableHolder.getCategories()) {
      if (categoryName.compareTo(cat.name) == 0) {
        result = cat.color;
        break;
      }
    }

    return result;
  }

  static dynamic findCategory(String categoryName) {
    for (var category in VariableHolder.getCategories()) {
      if (categoryName.isNotEmpty &&
          categoryName.compareTo(category.name) == 0) {
        return category;
      }
    }
    return null;
  }

  static bool contains(List<CategoryData> list, String criteria) {
    bool result = false;

    for (var item in list) {
      if (criteria.compareTo(item.name) == 0) {
        result = true;
        break;
      }
    }

    return result;
  }

  static Future<List<CategoryData>> getExpenseStatistics(
      TimeRange selectedRange, DateTime date) async {
    final Dio dio = VariableHolder.getDio();
    try {
      final response = await dio.get(
        '${VariableHolder.getBaseUrl()}/api/v1/expense-statistics',
        queryParameters: selectedRange == TimeRange.monthly
            ? {'month': date.month, 'year': date.year, 'type': 'ALL'}
            : {'year': date.year, 'type': 'ALL'},
        options: Options(
          headers: {
            'X-Api-Key': '11112', // replace with your real key
          },
        ),
      );
      print(response.data);
      final List<dynamic> stats = response.data[0]['statistics'];

      final sortedStats = List<Map<String, dynamic>>.from(stats);
      sortedStats
          .sort((a, b) => (b['percent'] as num).compareTo(a['percent'] as num));

      List<CategoryData> categoryData = sortedStats.map((item) {
        return CategoryData(
          name: item['category']['name'],
          percentage: (item['percent'] as num).toDouble(),
          color: BudgetService.parseColor(item['category']['color']),
          type: item['category']['type'],
          total: (item['total'] as num).toDouble(),
        );
      }).toList();

      return categoryData;
    } catch (e) {
      throw e;
    }
  }

  static Future<List<TransactionData>> getTransactions(DateTime date) async {
    final Dio dio = VariableHolder.getDio();
    List<TransactionData> transactions = [];
    try {
      final response = await dio.get(
        '${VariableHolder.getBaseUrl()}/api/v1/expense-entry',
        queryParameters: {
          'month': date.month,
          'year': date.year,
        },
        options: Options(
          headers: {
            'X-Api-Key': '11112', // replace with your real key
          },
        ),
      );
      print(response.data);

      if (response.statusCode == 200) {
        final decoded = response.data is String
            ? json.decode(response.data)
            : response.data;

        for (var item in decoded) {
          transactions.add(_parseTransactionData(item));
        }
      }
    } catch (e) {
      throw e;
    }
    return transactions;
  }

  static Future<LoginResponse> login(LoginRequest data) async {
    final Dio dio = VariableHolder.getDio();
    final response = await dio.post(
      "${VariableHolder.getAuthBaseUrl()}/api/v1/login",
      data: jsonEncode(data.toJson()),
      options: Options(
        headers: {
          'X-Api-Key': '11112', // replace with your real key
        },
      ),
    );

    if (response.statusCode == 200) {
      final decoded = response.data is String
          ? json.decode(response.data)
          : response.data;

      return _parseLoginResponse(decoded);
    } else {
      throw Future.error('Auth Error');
    }
  }

  static Future<RegisterResponse> register(LoginRequest data) async {
    final Dio dio = VariableHolder.getDio();
    final response = await dio.post(
      "${VariableHolder.getAuthBaseUrl()}/api/v1/register",
      data: jsonEncode(data.toJson()),
      options: Options(
        headers: {
          'X-Api-Key': '11112', // replace with your real key
        },
      ),
    );

    if (response.statusCode == 200) {
      final decoded = response.data is String
          ? json.decode(response.data)
          : response.data;

      return _parseRegisterResponse(decoded);
    } else {
      throw Future.error('Register Error');
    }
  }

  static Future<Response<dynamic>> submitTransaction(dynamic data) async {
    final Dio dio = VariableHolder.getDio();
    final response = await dio.post(
      "${VariableHolder.getBaseUrl()}/api/v1/expense-entry",
      data: data,
      options: Options(
        headers: {
          'X-Api-Key': '11112', // replace with your real key
        },
      ),
    );
    return response;
  }

  static Future<List<CategoryData>> fetchCategories() async {
    final Dio dio = VariableHolder.getDio();
    final response = await dio.get(
      "${VariableHolder.getBaseUrl()}/api/v1/category",
      options: Options(
        headers: {
          'X-Api-Key': '11112', // replace with your real key
        },
      ),
    );
    List<CategoryData> categories = [];
    if (response.statusCode == 200) {
      final decoded =
          response.data is String ? json.decode(response.data) : response.data;
      print(decoded);

      categories = _parseCategories(decoded);
    }
    return categories;
  }

  static List<CategoryData> _parseCategories(dynamic input) {
    List<CategoryData> categories = [];
    for (var cat in input) {
      CategoryData category = CategoryData(
          name: cat['name'],
          color: BudgetService.parseColor(cat['color']),
          type: cat['type'],
          percentage: 0.0,
          total: 0.0);
      categories.add(category);
    }
    return categories;
  }

  static TransactionData _parseTransactionData(dynamic item) {
    CategoryData category = CategoryData(
        name: item['category']['name'],
        color: parseColor(item['category']['color']),
        type: item['category']['type'],
        percentage: 0.0,
        total: 0.0);
    TransactionData data = TransactionData(
        date: item['date'],
        description: item['description'],
        price: item['value'],
        category: category,
        comment: item['comment'] != null ? item['comment'] : '');
    return data;
  }

  static LoginResponse _parseLoginResponse(dynamic data) {
    return LoginResponse(
        token: data['token'],
        refreshToken: data['refreshToken'],
        validUntil: data['validUntil'] != null ? data['validUntil'] : '',
        username: data['username'],
        uid: data['uid']
    );
  }

  static RegisterResponse _parseRegisterResponse(dynamic data) {
    return RegisterResponse(
        id: data['id'],
        username: data['username'],
        createdAt: data['createdAt'],
    );
  }
}
