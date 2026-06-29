import 'package:flutter/material.dart';
import 'widgets/add_expense.dart';
import 'widgets/expense_chart.dart';
import 'models/expense.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final List<Expense> _expenses = [];

  void _addExpense(Expense expense) {
    setState(() {
      _expenses.add(expense);
    });
  }

  void _openAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return AddExpenseForm(onAddExpense: _addExpense);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Expense Tracker")),
      body: Column(
        children: [
          if (_expenses.isNotEmpty) ExpenseChart(expenses: _expenses),
          Expanded(
            child: _expenses.isEmpty
                ? const Center(child: Text("No expenses yet. Add one!"))
                : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final exp = _expenses[index];
                return ListTile(
                  title: Text(exp.title),
                  subtitle: Text(
                    "${exp.category} • ${exp.date.day}/${exp.date.month}/${exp.date.year}",
                  ),
                  trailing: Text("€${exp.amount.toStringAsFixed(2)}"),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        child: const Icon(Icons.add),
      ),
    );
  }
}