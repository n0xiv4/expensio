import 'dart:async';
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
  List<Expense> _expenses = [];
  StreamSubscription? _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Listen to real-time updates from Supabase
    _subscription = _expenseService.getExpensesStream().listen((data) {
      if (mounted) {
        setState(() {
          _expenses = data;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _openAddExpense() async {
    final newExpense = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseForm(),
    );

    if (newExpense != null) {
      // 1. Instant local update (Optimistic UI)
      setState(() {
        _expenses.insert(0, newExpense);
      });

      // 2. Background server update
      try {
        await _expenseService.addExpense(newExpense);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving to cloud: $e')),
        );
      }
    }
  }

  void _confirmDelete(Expense expense) async {
    if (expense.id == null) return;
    
    // Instant local remove
    final index = _expenses.indexOf(expense);
    setState(() {
      _expenses.remove(expense);
    });

    try {
      await _expenseService.deleteExpense(expense.id!);
    } catch (e) {
      // Revert if failed
      setState(() {
        _expenses.insert(index, expense);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expensio", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _expenseService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (_expenses.isNotEmpty) ExpenseChart(expenses: _expenses),
              Expanded(
                child: _expenses.isEmpty
                    ? const Center(child: Text("No expenses yet. Tap + to add one!"))
                    : ListView.builder(
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final exp = _expenses[index];
                          return Dismissible(
                            key: Key(exp.id ?? 'temp_${index}_${exp.title}'),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) => _confirmDelete(exp),
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                                title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text("${exp.category} • ${exp.date.day}/${exp.date.month}"),
                                trailing: Text(
                                  "€${exp.amount.toStringAsFixed(2)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                ),
                              ),
                            ),
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
