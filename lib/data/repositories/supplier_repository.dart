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
      // Fallback: direct table query when RPC is unavailable
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
}
