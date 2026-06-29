import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

class ExpenseService {
  final _supabase = Supabase.instance.client;

  // Stream of expenses for the current user
  Stream<List<Expense>> getExpensesStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date', ascending: false)
        .map((data) => data.map((map) => Expense.fromMap(map)).toList());
  }

  // Create a new expense
  Future<void> addExpense(Expense expense) async {
    await _supabase.from('expenses').insert(expense.toMap());
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
