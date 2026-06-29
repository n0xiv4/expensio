import 'package:flutter/material.dart';
import 'models/expense.dart';
import 'widgets/expense_chart.dart';
import 'widgets/add_expense.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Temporary local list to record the transactions
  final List<Expense> _expenses = [];

  void _addNewExpense(Expense newExpense) {
    setState(() {
      _expenses.add(newExpense);
    });
  }

  void _removeExpense(Expense expense) {
    setState(() {
      _expenses.remove(expense);
    });
  }

  void _openAddExpenseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddExpenseForm(
            onAddExpense: _addNewExpense,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expensio Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddExpenseModal,
          )
        ],
      ),
      body: Column(
        children: [
          ExpenseChart(expenses: _expenses),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Transactions Record',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Your ListViwe
          Expanded(
            child: _expenses.isEmpty
                ? const Center(
              child: Text('No transactions recorded. Click on +'),
            )
                : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (ctx, index) {
                final exp = _expenses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    onTap: () async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Expense"),
                          content: const Text(
                            "Are you sure you want to delete this expense?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (shouldDelete == true) {
                        _removeExpense(exp);
                      }
                    },
                    leading: const CircleAvatar(
                      child: Icon(Icons.credit_card),
                    ),
                    title: Text(
                      exp.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${exp.category} • ${exp.date.day}/${exp.date.month}/${exp.date.year}',
                    ),
                    trailing: Text(
                      '${exp.amount.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}