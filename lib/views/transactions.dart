import 'package:budget_app/context/variable_holder.dart';
import 'package:budget_app/dto/transaction_data.dart';
import 'package:budget_app/services/budget_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  List<TransactionData> transactions = [];
  bool isLoading = true;
  String? errorMessage;
  DateTime currentDate = DateTime.timestamp();

  double total = 0;
  String totalString = '';

  @override
  void initState() {
    super.initState();
    fetchTransactions(DateTime.timestamp());
  }

  void initCategories() {
    for (var item in transactions) {
      var category = item.category;
      if (!BudgetService.contains(
          VariableHolder.getCategories(), category.name)) {
        VariableHolder.getCategories().add(category);
      }
    }
  }

  Future<void> fetchTransactions(DateTime date) async {
    try {
      transactions = await BudgetService.getTransactions(date);

      total = 0;
      for (var transaction in transactions) {
        total += transaction.price;
      }

      totalString = total.toStringAsFixed(2);

      initCategories();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    List<Widget> colChildren = [
      const SizedBox(height: 12),

      // Dashbaord headline
      Center(
          child: Text(
              'Monthly Overview: ${currentDate.year}-${currentDate.month}',
              style: Theme.of(context).textTheme.headlineSmall)),

      const SizedBox(height: 24),

      // Row with buttons
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                currentDate = DateTime(
                    currentDate.year, currentDate.month - 1, currentDate.day);
                transactions.clear();
                fetchTransactions(currentDate);
                print('Previous Month clicked');
              },
              child: Text('Previous Month'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                currentDate = DateTime.timestamp();
                transactions.clear();
                fetchTransactions(currentDate);
                print('Today clicked');
              },
              child: const Text('Today'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                currentDate = DateTime(
                    currentDate.year, currentDate.month + 1, currentDate.day);
                transactions.clear();
                fetchTransactions(currentDate);
                print('Next Month clicked');
              },
              child: Text('Next Month'),
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),
    ];

    colChildren.addAll(_buildTable());

    return Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: colChildren)));
  }

  List<Widget> _buildTable() {
    if (transactions.isEmpty) {
      return [
        SizedBox(height: 32),
        Center(
            child: SizedBox(height: 32, child: const Text('No data available')))
      ];
    } else {
      return [
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.blue),
              columns: const [
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Description")),
                DataColumn(label: Text("Price")),
                DataColumn(label: Text("Category")),
                DataColumn(label: Text("Comment")),
              ],
              rows: transactions.map((tx) {
                return DataRow(cells: [
                  DataCell(Text(DateFormat("dd.MM.yyyy")
                      .format(DateTime.parse(tx.date)))),
                  DataCell(Text(tx.description)),
                  DataCell(Text("${tx.price} €")),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: tx.category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(tx.category.name),
                    ],
                  )),
                  DataCell(Text(tx.comment)),
                ]);
              }).toList(),
            ),
          ),
        ),
        Center(
          child: Text('Transaction Totals: ${totalString}€',
              style: Theme.of(context).textTheme.titleMedium),
        ),
      ];
    }
  }
}
