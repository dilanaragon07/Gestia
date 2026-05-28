import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final _client = Supabase.instance.client;

  Future<List<CategoryModel>> fetchAll() async {
    final response = await _client
        .from('categories')
        .select()
        .order('name');
    return (response as List)
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryModel> create(String name, String colorHex) async {
    final inserted = await _client
        .from('categories')
        .insert({'name': name, 'color': colorHex})
        .select()
        .single();
    return CategoryModel.fromJson(inserted);
  }

  Future<CategoryModel> update(String id, String name, String colorHex) async {
    final updated = await _client
        .from('categories')
        .update({'name': name, 'color': colorHex})
        .eq('id', id)
        .select()
        .single();
    return CategoryModel.fromJson(updated);
  }

  Future<void> delete(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
