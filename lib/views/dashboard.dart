import 'package:budget_app/dto/category_data.dart';
import 'package:budget_app/enums/enums.dart';
import 'package:budget_app/services/budget_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<CategoryData> categoryData = [];
  int? _touchedIndex;
  bool _isLoading = true;
  String? _error;
  TimeRange _selectedRange = TimeRange.monthly;

  DateTime currentDate = DateTime.timestamp();

  @override
  void initState() {
    super.initState();

    _fetchPieData(currentDate);
  }

  Future<void> _fetchPieData(DateTime date) async {
    try {
      categoryData =
          await BudgetService.getExpenseStatistics(_selectedRange, date);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data';
        _isLoading = false;
      });
      debugPrint('Failed to load data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    bool isMonthly = _selectedRange == TimeRange.monthly;

    List<Widget> widgets = [
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
                  _fetchPieData(currentDate);
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
                  _fetchPieData(currentDate);
                },
              ),
              const Text('Yearly'),
            ],
          ),
        ],
      ),

      const SizedBox(height: 12),

      // Dashbaord headline
      Center(
        child: Text(
            isMonthly
                ? 'Monthly Overview: ${currentDate.year}-${currentDate.month}'
                : 'Yearly Overview: ${currentDate.year}',
            style: Theme.of(context).textTheme.headlineSmall),
      ),

      const SizedBox(height: 24),

      // Row with buttons
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                if (isMonthly) {
                  currentDate = DateTime(
                      currentDate.year, currentDate.month - 1, currentDate.day);
                } else {
                  currentDate = DateTime(
                      currentDate.year - 1, currentDate.month, currentDate.day);
                }
                _fetchPieData(currentDate);
                print('Previous Month clicked');
              },
              child: Text(isMonthly ? 'Previous Month' : 'Previous Year'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                currentDate = DateTime.timestamp();
                _fetchPieData(currentDate);
                print('Today clicked');
              },
              child: const Text('Today'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                if (isMonthly) {
                  currentDate = DateTime(
                      currentDate.year, currentDate.month + 1, currentDate.day);
                } else {
                  currentDate = DateTime(
                      currentDate.year + 1, currentDate.month, currentDate.day);
                }

                _fetchPieData(currentDate);
                print('Next Month clicked');
              },
              child: Text(isMonthly ? 'Next Month' : 'Next Year'),
            ),
          ],
        ),
      )
    ];

    widgets.addAll(_buildChart());

    return Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets
          ),
        ));
  }

  List<Widget> _buildChart() {
    if (categoryData.isEmpty) {
      return [
        SizedBox(
          height: 32
        ),
        Center(
          child: SizedBox(
            height: 32,
            child: const Text('No data available')
          )
        )
      ];
    } else {
      return [
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 20,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex =
                        response?.touchedSection?.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(categoryData.length, (index) {
                final data = categoryData[index];
                final isSelected = index == _touchedIndex;
                return PieChartSectionData(
                  value: data.percentage,
                  color: data.color,
                  title: '',
                  radius: isSelected ? 100 : 80,
                  titleStyle:
                      const TextStyle(color: Colors.white, fontSize: 14),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Category Breakdown',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildTable(),
      ];
    }
  }

  Widget _buildTable() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Color')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Percentage')),
            DataColumn(label: Text('Total')),
          ],
          rows: [
            // Data rows with MouseRegion for hover
            ...List.generate(categoryData.length, (index) {
              final data = categoryData[index];
              final isSelected = index == _touchedIndex;

              // Create a row with hover detection using DataCells wrapped in MouseRegions
              return DataRow(
                color: isSelected
                    ? MaterialStateProperty.all(Colors.grey.withOpacity(0.2))
                    : null,
                cells: [
                  DataCell(
                    MouseRegion(
                      onEnter: (_) => setState(() => _touchedIndex = index),
                      onExit: (_) => setState(() => _touchedIndex = null),
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _touchedIndex = index),
                        //onTapUp: (_) => setState(() => _touchedIndex = null),
                        //onTapCancel: () => setState(() => _touchedIndex = null),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: data.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    MouseRegion(
                      onEnter: (_) => setState(() => _touchedIndex = index),
                      onExit: (_) => setState(() => _touchedIndex = null),
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _touchedIndex = index),
                        //onTapUp: (_) => setState(() => _touchedIndex = null),
                        //onTapCancel: () => setState(() => _touchedIndex = null),
                        child: Text(data.name),
                      ),
                    ),
                  ),
                  DataCell(
                    MouseRegion(
                        onEnter: (_) => setState(() => _touchedIndex = index),
                        onExit: (_) => setState(() => _touchedIndex = null),
                        child: GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _touchedIndex = index),
                          //onTapUp: (_) => setState(() => _touchedIndex = null),
                          //onTapCancel: () => setState(() => _touchedIndex = null),
                          child: Text('${data.percentage}%'),
                        )),
                  ),
                  DataCell(
                    MouseRegion(
                        onEnter: (_) => setState(() => _touchedIndex = index),
                        onExit: (_) => setState(() => _touchedIndex = null),
                        child: GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _touchedIndex = index),
                          //onTapUp: (_) => setState(() => _touchedIndex = null),
                          //onTapCancel: () => setState(() => _touchedIndex = null),
                          child: Text('${data.total} €'),
                        )),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
