import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../models/category.dart' as model;
import '../services/category_service.dart';

class AddExpenseForm extends StatefulWidget {
  final Expense? initialExpense;

  const AddExpenseForm({super.key, this.initialExpense});

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryService = CategoryService();
  
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  List<model.Category> _customCategories = [];

  final List<Map<String, dynamic>> _defaultCategories = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Bills', 'icon': Icons.receipt},
    {'name': 'Health', 'icon': Icons.medical_services},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Education', 'icon': Icons.book},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialExpense != null) {
      _titleController.text = widget.initialExpense!.title;
      _amountController.text = widget.initialExpense!.amount.toString();
      _selectedCategory = widget.initialExpense!.category;
      _selectedDate = widget.initialExpense!.date;
    }
    _loadCategories();
  }

  void _loadCategories() {
    _categoryService.getCategoriesStream().listen((categories) {
      if (mounted) {
        setState(() {
          _customCategories = categories;
        });
      }
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceFirst(',', '.'));
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (title.isEmpty || amount == null || amount <= 0 || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid details'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context, Expense(
      id: widget.initialExpense?.id,
      userId: userId,
      title: title,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
    ));
  }

  void _addCustomCategory() async {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.category;

    final newCategory = await showDialog<model.Category>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Category"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Category Name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId != null) {
                  Navigator.pop(ctx, model.Category(
                    userId: userId,
                    name: nameController.text.trim(),
                    iconCode: selectedIcon.codePoint,
                  ));
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );

    if (newCategory != null) {
      await _categoryService.addCategory(newCategory);
      setState(() {
        _selectedCategory = newCategory.name;
      });
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final allCategories = [
      ..._defaultCategories.map((c) => {'name': c['name'] as String, 'icon': c['icon'] as IconData}),
      ..._customCategories.map((c) => {'name': c.name, 'icon': c.icon}),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.initialExpense == null ? "New Expense" : "Edit Expense",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _titleController,
              autofocus: widget.initialExpense == null,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Description",
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Amount (€)",
                prefixIcon: Icon(Icons.euro_symbol_rounded),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Category",
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                TextButton.icon(
                  onPressed: _addCustomCategory,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("New", style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final cat = allCategories[index];
                  final isSelected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? null : Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 18,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    Text(
                      "Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              child: Text(widget.initialExpense == null ? "Create Expense" : "Update Expense"),
            ),
          ],
        ),
      ),
    );
  }
}
