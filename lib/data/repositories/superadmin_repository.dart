import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/debt_model.dart';

class SuperadminRepository {
  final _client = Supabase.instance.client;

  Future<AdminStats> getAdminStats() async {
    final response = await _client.rpc('get_admin_stats');
    final row = (response as List).first as Map<String, dynamic>;
    return AdminStats.fromJson(row);
  }

  Future<List<DebtEvolutionData>> getDebtEvolution() async {
    final response = await _client.rpc('get_debt_evolution');
    return (response as List)
        .map((row) => DebtEvolutionData(
              month: row['month'] as String,
              newDebt: (row['new_debt'] as num).toDouble(),
              paymentsMade: (row['payments_made'] as num).toDouble(),
            ))
        .toList();
  }

  Future<List<InvoiceDebtPoint>> getSupplierDebtTimeline(String supplierId) async {
    final response = await _client
        .rpc('get_supplier_debt_timeline', params: {'p_supplier_id': supplierId});
    return (response as List)
        .map((row) => InvoiceDebtPoint(
              invoiceNumber: row['invoice_number'] as String,
              issueDate: DateTime.parse(row['issue_date'] as String),
              finalAmount: (row['final_amount'] as num).toDouble(),
              balance: (row['balance'] as num).toDouble(),
              status: row['status'] as String,
            ))
        .toList();
  }
}
