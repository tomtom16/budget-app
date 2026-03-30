import 'package:budget_app/dto/category_data.dart';

class TransactionData {
  final String date;
  final String description;
  final String comment;
  final double price;
  final CategoryData category;

  const TransactionData({
    required this.date,
    required this.description,
    required this.price,
    required this.category,
    required this.comment
  });

}