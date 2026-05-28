import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier_model.dart';

class SupplierRepository {
  final _client = Supabase.instance.client;

  Future<List<SupplierModel>> fetchAll() async {
    try {
      final response = await _client.rpc('get_supplier_summary').select();
      return (response as List)
          .map((json) => SupplierModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final response = await _client.from('suppliers').select();
      return (response as List)
          .map((json) => SupplierModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }

  Future<SupplierModel?> fetchById(String id) async {
    final data = await _client
        .from('suppliers')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return SupplierModel.fromJson(data);
  }

  Future<SupplierModel> create(SupplierModel supplier) async {
    final inserted = await _client
        .from('suppliers')
        .insert(supplier.toJson())
        .select()
        .single();
    return SupplierModel.fromJson(inserted);
  }

  Future<void> updateTags(String id, List<String> tags) async {
    await _client
        .from('suppliers')
        .update({'tags': tags})
        .eq('id', id);
  }

  Future<SupplierModel> update(String id, SupplierModel supplier) async {
    final updated = await _client
        .from('suppliers')
        .update(supplier.toJson())
        .eq('id', id)
        .select()
        .single();
    return SupplierModel.fromJson(updated);
  }

  Future<void> deactivate(String id) async {
    await _client
        .from('suppliers')
        .update({'is_active': false})
        .eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('suppliers').delete().eq('id', id);
  }
}
