import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

class ExpenseService {
  final _supabase = Supabase.instance.client;

  // Stream of expenses for the current user
  Future<List<Expense>> getExpenses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabase
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return data.map((map) => Expense.fromMap(map)).toList();
  }

  // Create a new expense
  Future<void> addExpense(Expense expense) async {
    await _supabase.from('expenses').insert(expense.toMap());
  }

  // Update an existing expense
  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) return;
    await _supabase.from('expenses').update(expense.toMap()).eq('id', expense.id!);
  }

  // Delete an expense
  Future<void> deleteExpense(String id) async {
    await _supabase.from('expenses').delete().eq('id', id);
  }

  // Sign out helper
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
