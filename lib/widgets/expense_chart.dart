import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  Map<String, double> get groupedData {
    Map<String, double> data = {};

    for (var e in expenses) {
      data[e.category] = (data[e.category] ?? 0) + e.amount;
    }

    return data;
  }

  Color getColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Shopping':
        return Colors.purple;
      case 'Bills':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = groupedData;
    final total = data.values.fold(0.0, (a, b) => a + b);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Expenses by Category",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: data.entries.map((entry) {
                    final percentage = (entry.value / total) * 100;

                    return PieChartSectionData(
                      value: entry.value,
                      title: "${entry.key}\n${percentage.toStringAsFixed(1)}%",
                      color: getColor(entry.key),
                      radius: 60,
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // LEGEND
            Wrap(
              spacing: 10,
              runSpacing: 5,
              children: data.keys.map((category) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: getColor(category)),
                    const SizedBox(width: 5),
                    Text(category),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
