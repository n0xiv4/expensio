import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

class AddExpenseForm extends StatefulWidget {
  const AddExpenseForm({super.key});

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Other'];

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceFirst(',', '.'));
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (title.isEmpty || amount == null || amount <= 0 || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid data')));
      return;
    }

    Navigator.pop(context, Expense(
      userId: userId,
      title: title,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // Moves up with keyboard
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("New Expense", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit)),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Amount (€)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.euro)),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
              decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("Save Expense"),
            ),
          ],
        ),
      ),
    );
  }
}
