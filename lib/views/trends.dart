import 'package:budget_app/context/variable_holder.dart';
import 'package:budget_app/dto/category_data.dart';
import 'package:budget_app/services/budget_service.dart'; // for formatting dates
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BarChartView extends StatefulWidget {
  @override
  _BarChartViewState createState() => _BarChartViewState();
}

class _BarChartViewState extends State<BarChartView> {
  final Dio _dio = VariableHolder.getDio();

  List<Map<String, dynamic>> previousMonth = [];
  List<Map<String, dynamic>> currentMonth = [];
  List<CategoryData> categories = [];

  // Track visibility of each series
  Map<String, bool> _visibleSeries = {};

  // Dynamic date range
  late DateTimeRange _dateRange;

  @override
  void initState() {
    super.initState();
    DateTime currentDate = DateTime.timestamp();
    DateTime lastMonth = DateTime(currentDate.year, currentDate.month - 1, 1);
    _dateRange = DateTimeRange(
      start: lastMonth,
      end: currentDate,
    );

    _fetchMonthsData();
  }

  Future<List<Map<String, dynamic>>> _fetchStats(DateTime date) async {
    final response = await _dio.get(
      '${VariableHolder.getBaseUrl()}/api/v1/expense-statistics',
      queryParameters: {'month': date.month, 'year': date.year, 'type': 'ALL'},
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

    return sortedStats;
  }

  Future<void> _fetchMonthsData() async {
    try {
      previousMonth = await _fetchStats(_dateRange.start);
      currentMonth = await _fetchStats(_dateRange.end);

      categories = await BudgetService.fetchCategories();

      print("PREVIOUS MONTH: ");
      print(previousMonth);
      print("CURRENT MONTH: ");
      print(currentMonth);
      print("CATEGORIES: ");
      print(categories);

      setState(() {
        _visibleSeries.clear();
        for (var cat in categories) {
          _visibleSeries.putIfAbsent(cat.name, () => true);
        }
      });
    } catch (e) {
      setState(() {});
    }
  }

  String _formatDateRange(DateTimeRange range) {
    final formatter = DateFormat.MMMM(); // Month name
    return "${formatter.format(range.start)} - ${formatter.format(range.end)} ${range.start.year}";
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Headline
              Text(
                "Trends",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              // Sub-headline with dynamic date range
              Text(
                _formatDateRange(_dateRange),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),

              // Date Range Picker Button
              ElevatedButton.icon(
                onPressed: _pickDateRange,
                icon: Icon(Icons.date_range),
                label: Text("Select Date Range"),
              ),
              SizedBox(height: 20),

              // Chart
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _findMaxValue(),
                    barGroups: _createGroups(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 40),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            switch (value.toInt()) {
                              case 0:
                                return Text("A");
                              case 1:
                                return Text("B");
                              case 2:
                                return Text("C");
                              default:
                                return Text("");
                            }
                          },
                        ),
                      ),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Legend
              Wrap(
                spacing: 16,
                children: _visibleSeries.keys.map((series) {
                  final isVisible = _visibleSeries[series]!;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _visibleSeries[series] = !isVisible;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isVisible
                                ? _getSeriesColor(series)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          series,
                          style: TextStyle(
                            color: isVisible ? Colors.black : Colors.grey,
                            fontWeight:
                                isVisible ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _createGroups() {
    List<BarChartGroupData> groups = [];

    for (var cat in categories) {
      if (_visibleSeries[cat.name]!) {
        double previousMonthValue = findCategoryValue(cat.name, previousMonth);
        double currentMonthValue = findCategoryValue(cat.name, currentMonth);

        groups.add(
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                  toY: previousMonthValue,
                  color: cat.color.withOpacity(0.7),
                  width: 20),
              BarChartRodData(
                  toY: currentMonthValue, color: cat.color, width: 20),
            ],
          ),
        );
      }
    }

    return groups;
  }

  double findCategoryValue(
      String categoryName, List<Map<String, dynamic>> values) {
    for (var value in values) {
      if (categoryName.compareTo(value["category"]["name"]) == 0) {
        return value["total"] as double;
      }
    }
    return 0.0;
  }

  double _findMaxValue() {
    double previousMonthMaxValue = _findMaxValueFromList(previousMonth);
    double currentMonthMaxValue = _findMaxValueFromList(currentMonth);
    return previousMonthMaxValue > currentMonthMaxValue ? previousMonthMaxValue : currentMonthMaxValue;
  }

  double _findMaxValueFromList(List<Map<String, dynamic>> values) {
    double maxValue = 0.0;
    for (var value in values) {
      if (_isVisible(value) && value["total"] as double > maxValue) {
        maxValue = value["total"] as double;
      }
    }
    return maxValue;
  }

  bool _isVisible(Map<String, dynamic> value) {
    String categoryName = value["category"]["name"];
    return _visibleSeries[categoryName] != null ? _visibleSeries[categoryName]! : false;
  }

  Color _getSeriesColor(String series) {
    for (var cat in categories) {
      if (series.compareTo(cat.name) == 0) {
        return cat.color;
      }
    }

    return Colors.grey;
  }
}
