import 'package:flutter/material.dart';
import '../models/expense.dart';

class AddExpenseForm extends StatefulWidget {
  final Function(Expense) onAddExpense;

  const AddExpenseForm({super.key, required this.onAddExpense});

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Other',
  ];

  void _submit() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text);

    if (title.isEmpty || amount == null) {
      return; // basic validation
    }

    final newExpense = Expense(
      title: title,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
    );

    widget.onAddExpense(newExpense);
    Navigator.pop(context);
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Add Expense",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: "Expense title"),
          ),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Amount €"),
          ),

          DropdownButtonFormField(
            value: _selectedCategory,
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
            decoration: InputDecoration(labelText: "Category"),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Date: ${_selectedDate.toLocal()}".split(' ')[0]),
              TextButton(onPressed: _pickDate, child: Text("Choose Date")),
            ],
          ),

          const SizedBox(height: 10),

          ElevatedButton(onPressed: _submit, child: Text("Add Expense")),
        ],
      ),
    );
  }
}
