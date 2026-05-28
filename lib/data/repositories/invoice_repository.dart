import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_model.dart';
import '../models/discount_model.dart';
import '../models/payment_model.dart';

class InvoiceRepository {
  final _client = Supabase.instance.client;

  // ─── List ─────────────────────────────────────────────────────────────────

  Future<List<InvoiceModel>> fetchAll() async {
    final response = await _client
        .from('invoice_summary')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => InvoiceModel.fromListJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── Detail ───────────────────────────────────────────────────────────────

  Future<InvoiceModel?> fetchById(String id) async {
    final invoiceData = await _client
        .from('invoice_summary')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (invoiceData == null) return null;

    final paymentsData = await _client
        .from('payments')
        .select()
        .eq('invoice_id', id)
        .order('payment_date', ascending: false);

    final discountData = await _client
        .from('discount_items')
        .select()
        .eq('invoice_id', id);

    final payments = (paymentsData as List)
        .map((p) => PaymentModel.fromJson(p as Map<String, dynamic>))
        .toList();

    DiscountModel? discount;
    if ((discountData as List).isNotEmpty) {
      discount = DiscountModel(
        items: discountData
            .map((d) => DiscountDetail(
                  product: d['product'] as String,
                  quantity: (d['quantity'] as num).toDouble(),
                  originalValue: (d['original_value'] as num).toDouble(),
                  discountedValue: (d['discounted_value'] as num).toDouble(),
                  reason: d['reason'] as String? ?? '',
                ))
            .toList(),
      );
    }

    return InvoiceModel.fromDetailJson(
      invoiceData,
      payments: payments,
      discount: discount,
    );
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<InvoiceModel> create(InvoiceModel invoice) async {
    // Check duplicate
    final existing = await _client
        .from('invoices')
        .select('id')
        .eq('invoice_number', invoice.invoiceNumber)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Ya existe una factura con el número ${invoice.invoiceNumber}.');
    }

    // Insert invoice
    final inserted = await _client
        .from('invoices')
        .insert(invoice.toInsertJson())
        .select()
        .single();

    final newId = inserted['id'] as String;

    // Insert discount items
    if (invoice.discount != null) {
      for (final item in invoice.discount!.items) {
        await _client.from('discount_items').insert({
          'invoice_id': newId,
          'product': item.product,
          'quantity': item.quantity,
          'original_value': item.originalValue,
          'discounted_value': item.discountedValue,
          'reason': item.reason,
        });
      }
    }

    // Insert initial payments
    for (final p in invoice.payments) {
      await _client.from('payments').insert({
        ...p.toJson(),
        'invoice_id': newId,
      });
    }

    // Return full model
    return (await fetchById(newId)) ?? invoice;
  }

  // ─── Register payment ─────────────────────────────────────────────────────

  Future<void> addPayment(PaymentModel payment) async {
    await _client.from('payments').insert(payment.toJson());
  }

  // ─── Reject ───────────────────────────────────────────────────────────────

  Future<void> reject(String id, {String? reason}) async {
    await _client.from('invoices').update({
      'is_rejected': true,
      'rejection_notes': reason,
    }).eq('id', id);
  }

  // ─── Real-time subscription ───────────────────────────────────────────────

  RealtimeChannel subscribeToChanges(void Function() onChange) {
    return _client
        .channel('db-invoices')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
