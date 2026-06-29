import 'package:flutter/material.dart';
import 'package:expensio/login_screen.dart';
import 'package:expensio/widgets/add_expense.dart';
import 'package:expensio/widgets/expense_chart.dart';
import 'package:expensio/models/expense.dart';
import 'package:expensio/services/expense_service.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final _expenseService = ExpenseService();

  void _openAddExpense() async {
    final newExpense = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddExpenseForm(),
    );

    if (newExpense != null) {
      try {
        await _expenseService.addExpense(newExpense);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save expense: $e')),
        );
      }
    }
  }

  void _confirmDelete(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Expense"),
        content: const Text("Are you sure you want to delete this record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true && expense.id != null) {
      await _expenseService.deleteExpense(expense.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expensio Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _expenseService.signOut();
              if (!mounted) return;
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.getExpensesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final expenses = snapshot.data ?? [];

          return Column(
            children: [
              if (expenses.isNotEmpty) ExpenseChart(expenses: expenses),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(
                        child: Text("No expenses yet. Tap + to add one!"),
                      )
                    : ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final exp = expenses[index];
                          return Dismissible(
                            key: Key(exp.id ?? index.toString()),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              if (exp.id != null) {
                                _expenseService.deleteExpense(exp.id!);
                              }
                            },
                            child: ListTile(
                              onTap: () => _confirmDelete(exp),
                              leading: const CircleAvatar(child: Icon(Icons.shopping_cart)),
                              title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                "${exp.category} • ${exp.date.day}/${exp.date.month}/${exp.date.year}",
                              ),
                              trailing: Text(
                                "€${exp.amount.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        child: const Icon(Icons.add),
      ),
    );
  }
}
