import 'dart:convert';
import 'package:budget_app/context/variable_holder.dart';
import 'package:budget_app/enums/enums.dart';
import 'package:budget_app/services/budget_service.dart';
import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';

import 'package:budget_app/dto/category_data.dart';

class DetailDashboard extends StatefulWidget {
  @override
  _DetailDashboardState createState() => _DetailDashboardState();
}

class _DetailDashboardState extends State<DetailDashboard> {
  Map<String, List<double>> data = {};
  Set<String> visibleSeries = {};
  bool isLoading = true;
  TimeRange _selectedRange = TimeRange.monthly;
  DateTime currentDate = DateTime.timestamp();
  final _dio = VariableHolder.getDio();

  @override
  void initState() {
    super.initState();
    fetchChartData(currentDate);
  }

  Future<void> fetchChartData(DateTime date) async {
    try {
      data.clear();
      VariableHolder.setCategories([]);

      var isMonthly = TimeRange.monthly == _selectedRange;

      final response = await _dio.get(
        '${VariableHolder.getBaseUrl()}/api/v1/expense-statistics',
        queryParameters: isMonthly ? {
          'year': date.year,
          'type': 'MONTHLY'
        } : {
          'type': 'YEARLY'
        } ,
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
        initCategories(decoded);
        initData(decoded);

        
        setState(() {
          visibleSeries = data.keys.toSet(); // all visible by default
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  void initCategories(dynamic input) {
    for (var item in input) {
      var statistics = (item['statistics']);
      for (var stat in statistics) {
        var category = CategoryData(
          name: stat['category']['name'],
          color: BudgetService.parseColor(stat['category']['color']),
          type: stat['category']['type'],
          percentage: 0.0,
          total: 0.0
        );
        if (!BudgetService.contains(VariableHolder.getCategories(), category.name)) {
          VariableHolder.getCategories().add(category);
        }
      }
    }

    print (VariableHolder.getCategories());
  }

  void initData(dynamic input) {
    for (var cat in VariableHolder.getCategories()) {
      List<double> catValues = [];
      for (var item in input) {
        bool found = false;
        for (var stat in item['statistics']) {
          if (cat.name.compareTo(stat['category']['name']) == 0) {
            var catValue = stat['total'] as double;
            catValues.add(catValue);
            found = true;
          }
        }
        if (!found) {
          catValues.add(0.0);
        }
        data.putIfAbsent(cat.name, () => catValues);
      }
    }

    print(data);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    var isMonthly = TimeRange.monthly == _selectedRange;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Radio buttons row
          Row(
            children: [
              Row(
                children: [
                  Radio<TimeRange>(
                    value: TimeRange.monthly,
                    groupValue: _selectedRange,
                    onChanged: (value) {
                      setState(() {
                        _selectedRange = value!;
                      });
                      fetchChartData(currentDate);
                    },
                  ),
                  const Text('Monthly'),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Radio<TimeRange>(
                    value: TimeRange.yearly,
                    groupValue: _selectedRange,
                    onChanged: (value) {
                      setState(() {
                        _selectedRange = value!;
                      });
                      fetchChartData(currentDate);
                    },
                  ),
                  const Text('Yearly'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Dashbaord headline
          Text(isMonthly ? 'Monthly Details: ${currentDate.year}' : 'Yearly Details', style: Theme
              .of(context)
              .textTheme
              .headlineSmall),
          const SizedBox(height: 24),

          _buildButtons(),
          _buildSpacer(),

          Expanded(
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1, // one label per data index
                      getTitlesWidget: (value, meta) {
                        const months = [
                          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                        ];
                        const years = ['2022', '2023', '2024', '2025'];
                        int index = value.toInt();
                        if (isMonthly) {
                          if (index >= 0 && index < months.length) {
                            return Text(
                              months[index],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                        } else {
                          if (index >= 0 && index < years.length) {
                            return Text(
                              years[index],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: _buildSeries(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  List<LineChartBarData> _buildSeries() {

    return data.entries
        .where((entry) => visibleSeries.contains(entry.key)) // only visible ones
        .map((entry) {
      final spots = entry.value.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value);
      }).toList();

      final line = LineChartBarData(
        spots: spots,
        isCurved: false,
        color: BudgetService.getColorForCategory(entry.key),
        barWidth: 3,
        dotData: FlDotData(show: false),
      );

      return line;
    }).toList();
  }

  Widget _buildLegend() {

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: data.keys.map((category) {
        final color = BudgetService.getColorForCategory(category);
        final isActive = visibleSeries.contains(category);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isActive) {
                visibleSeries.remove(category);
              } else {
                visibleSeries.add(category);
              }
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? color : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButtons() {
    var isMonthly = TimeRange.monthly == _selectedRange;
    if (isMonthly) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                if (isMonthly) {
                  currentDate = DateTime(
                      currentDate.year - 1, currentDate.month, currentDate.day);
                }
                fetchChartData(currentDate);
                print('Previous Year clicked');
              },
              child: Text('Previous Year'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                currentDate = DateTime.timestamp();
                fetchChartData(currentDate);
                print('Today clicked');
              },
              child: const Text('Current Year'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                if (isMonthly) {
                  currentDate = DateTime(
                      currentDate.year + 1, currentDate.month, currentDate.day);
                }
                fetchChartData(currentDate);
                print('Next Year clicked');
              },
              child: Text('Next Year'),
            ),
          ],
        ),
      );
    } else {
      return SizedBox(height: 24);
    }

  }

  Widget _buildSpacer() {
    var isMonthly = TimeRange.monthly == _selectedRange;
    double space = isMonthly ? 24 : 0;
    return SizedBox(height: space);
  }
}
