import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';

class ExpenseChart extends StatefulWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  int touchedIndex = -1;
  String _filterType = 'All Time'; // 'All Time', 'This Month', 'This Week'

  List<Expense> get filteredExpenses {
    final now = DateTime.now();
    if (_filterType == 'This Month') {
      return widget.expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    } else if (_filterType == 'This Week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return widget.expenses.where((e) => e.date.isAfter(weekAgo)).toList();
    }
    return widget.expenses;
  }

  Map<String, double> get groupedData {
    Map<String, double> data = {};
    for (var e in filteredExpenses) {
      data[e.category] = (data[e.category] ?? 0) + e.amount;
    }
    return data;
  }

  Color getColor(String category) {
    switch (category) {
      case 'Food': return const Color(0xFFF59E0B);
      case 'Transport': return const Color(0xFF3B82F6);
      case 'Shopping': return const Color(0xFF8B5CF6);
      case 'Bills': return const Color(0xFFEF4444);
      case 'Health': return const Color(0xFF10B981);
      case 'Entertainment': return const Color(0xFFF472B6);
      case 'Education': return const Color(0xFF60A5FA);
      default: return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = groupedData;
    final total = data.values.fold(0.0, (a, b) => a + b);

    if (widget.expenses.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardTheme.color!,
              theme.cardTheme.color!.withValues(alpha: 0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overview",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      _filterType,
                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterType,
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(Icons.filter_list, color: Colors.white70, size: 20),
                    onChanged: (String? newValue) {
                      setState(() {
                        _filterType = newValue!;
                        touchedIndex = -1;
                      });
                    },
                    items: <String>['All Time', 'This Month', 'This Week']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 4,
                      centerSpaceRadius: 50,
                      sections: data.entries.toList().asMap().entries.map((mapEntry) {
                        final index = mapEntry.key;
                        final entry = mapEntry.value;
                        final isTouched = index == touchedIndex;
                        final radius = isTouched ? 50.0 : 40.0;

                        return PieChartSectionData(
                          value: entry.value,
                          title: '',
                          color: getColor(entry.key),
                          radius: radius,
                          badgeWidget: isTouched ? null : _Badge(
                            entry.key,
                            size: 32,
                            borderColor: getColor(entry.key),
                          ),
                          badgePositionPercentageOffset: 1.1,
                        );
                      }).toList(),
                    ),
                    duration: const Duration(milliseconds: 150),
                  ),
                ),
                // Custom Tooltip in the center
                if (touchedIndex != -1 && data.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => touchedIndex = -1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.keys.elementAt(touchedIndex),
                          style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "€${data.values.elementAt(touchedIndex).toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: getColor(data.keys.elementAt(touchedIndex)),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "€${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: data.entries.toList().asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final entry = mapEntry.value;
                final isSelected = index == touchedIndex;

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (touchedIndex == index) {
                        touchedIndex = -1;
                      } else {
                        touchedIndex = index;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? getColor(entry.key).withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: getColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12, 
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String category;
  final double size;
  final Color borderColor;

  const _Badge(this.category, {required this.size, required this.borderColor});

  IconData _getIcon() {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_car;
      case 'Shopping': return Icons.shopping_bag;
      case 'Bills': return Icons.receipt;
      case 'Health': return Icons.medical_services;
      case 'Entertainment': return Icons.movie;
      case 'Education': return Icons.book;
      default: return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(_getIcon(), size: size * 0.5, color: Colors.white),
      ),
    );
  }
}
