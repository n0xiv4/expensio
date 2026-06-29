import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryService {
  final _supabase = Supabase.instance.client;

  Stream<List<Category>> getCategoriesStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('name')
        .map((data) => data.map((map) => Category.fromMap(map)).toList());
  }

  Future<void> addCategory(Category category) async {
    await _supabase.from('categories').insert(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from('categories').delete().eq('id', id);
  }
}
