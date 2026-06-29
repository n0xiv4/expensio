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
      case 'Food': return Colors.orange;
      case 'Transport': return Colors.blue;
      case 'Shopping': return Colors.purple;
      case 'Bills': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = groupedData;
    final total = data.values.fold(0.0, (a, b) => a + b);

    return RepaintBoundary( // Prevents unnecessary repaints when typing in modals
      child: Card(
        margin: const EdgeInsets.all(12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Expenses by Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: data.entries.map((entry) {
                      final percentage = total > 0 ? (entry.value / total) * 100 : 0;
                      return PieChartSectionData(
                        value: entry.value,
                        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                        color: getColor(entry.key),
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                  swapAnimationDuration: Duration.zero, // DRASTICALLY reduces lag
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: data.keys.map((category) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: getColor(category), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(category, style: const TextStyle(fontSize: 12)),
                  ],
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
