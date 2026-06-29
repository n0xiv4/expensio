import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expensio/login_screen.dart';
import 'package:expensio/widgets/add_expense.dart';
import 'package:expensio/widgets/expense_chart.dart';
import 'package:expensio/models/expense.dart';
import 'package:expensio/services/expense_service.dart';
import 'package:expensio/models/category.dart' as model;
import 'package:expensio/services/category_service.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final _expenseService = ExpenseService();
  final _categoryService = CategoryService();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final _searchController = TextEditingController();

  List<Expense> _expenses = [];
  List<model.Category> _customCategories = [];
  StreamSubscription? _categorySub;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Função nova que vai buscar os dados reais sem bugs de cache
  Future<void> _loadData() async {
    _categorySub ??= _categoryService.getCategoriesStream().listen((data) {
      if (mounted) setState(() => _customCategories = List.from(data));
    });

    final data = await _expenseService.getExpenses();
    if (mounted) {
      setState(() {
        _expenses = data;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _categorySub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Expense> get _filteredExpenses {
    if (_searchQuery.isEmpty) return _expenses;
    return _expenses.where((e) =>
    e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        e.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _openAddExpense({Expense? expense}) async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseForm(initialExpense: expense),
    );

    if (result != null) {
      if (expense == null) {
        // Add new
        try {
          await _expenseService.addExpense(result);
          await _loadData(); // Atualiza a lista com a verdade da BD
        } catch (e) {
          _showError('Failed to save: $e');
        }
      } else {
        // Update existing
        try {
          await _expenseService.updateExpense(result);
          await _loadData(); // Atualiza a lista com a verdade da BD
        } catch (e) {
          _showError('Failed to update: $e');
        }
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _confirmDelete(Expense expense, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Expense"),
        content: const Text("Remove this transaction permanently?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(80, 40),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true && expense.id != null) {
      // Apaga do ecrã instantaneamente para não haver lag (Optimistic UI)
      setState(() {
        _expenses.removeWhere((e) => e.id == expense.id);
      });

      try {
        await _expenseService.deleteExpense(expense.id!);
        await _loadData(); // Garante que a lista está sincronizada com a BD
      } catch (e) {
        _showError('Failed to delete: $e');
      }
    }
  }

  Widget _buildItem(Expense exp, Animation<double> animation, int index, {bool isRemoving = false}) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _buildItemStatic(exp, index, isRemoving: isRemoving),
      ),
    );
  }

  Widget _buildItemStatic(Expense exp, int index, {bool isRemoving = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: isRemoving ? null : () => _openAddExpense(expense: exp),
        onLongPress: isRemoving ? null : () => _confirmDelete(exp, index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getCategoryColor(exp.category).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCategoryIcon(exp.category),
                  color: _getCategoryColor(exp.category),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${exp.category} • ${exp.date.day}/${exp.date.month}",
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                "€${exp.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_car;
      case 'Shopping': return Icons.shopping_bag;
      case 'Bills': return Icons.receipt;
      case 'Health': return Icons.medical_services;
      case 'Entertainment': return Icons.movie;
      case 'Education': return Icons.book;
    }
    try {
      final custom = _customCategories.firstWhere((c) => c.name == categoryName);
      return custom.icon;
    } catch (_) {
      return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
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
    final filtered = _filteredExpenses;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _isSearching ? 80.0 : 120.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: _isSearching 
                  ? null 
                  : const Text("Expensio", style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            bottom: _isSearching 
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Search transactions...",
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                )
              : null,
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
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
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (!_isSearching)
              SliverToBoxAdapter(
                child: ExpenseChart(expenses: _expenses),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, _isSearching ? 16 : 24, 16, 8),
                child: Text(
                  _isSearching ? "Search Results (${filtered.length})" : "Recent Transactions",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    _isSearching ? "No matches found" : "No expenses yet. Tap + to add one!", 
                    style: const TextStyle(color: Colors.white54)
                  )
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildItemStatic(filtered[index], index),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _openAddExpense(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}
