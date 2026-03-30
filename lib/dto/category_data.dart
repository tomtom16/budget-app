import 'package:flutter/material.dart';

class CategoryData {
  final String name;
  final double percentage;
  final Color color;
  final String type;
  final double total;

  const CategoryData({
    required this.name,
    required this.percentage,
    required this.color,
    required this.type,
    required this.total
  });
}