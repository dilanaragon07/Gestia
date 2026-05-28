import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/supplier_repository.dart';
import '../models/supplier_model.dart';
import 'category_store.dart';

class InvoiceStore extends ChangeNotifier {
  static final InvoiceStore instance = InvoiceStore._();
  InvoiceStore._();

  final _invoiceRepo = InvoiceRepository();
  final _supplierRepo = SupplierRepository();

  List<InvoiceModel> _invoices = [];
  List<SupplierModel> _suppliers = [];
  bool _loadingInvoices = false;
  bool _loadingSuppliers = false;
  String? _error;
  RealtimeChannel? _channel;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<InvoiceModel> get invoices => List.unmodifiable(_invoices);
  List<SupplierModel> get suppliers => List.unmodifiable(_suppliers);
  bool get isLoading => _loadingInvoices || _loadingSuppliers;
  bool get isLoadingInvoices => _loadingInvoices;
  String? get error => _error;

  InvoiceModel? findById(String id) {
    try {
      return _invoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  InvoiceModel? findByNumber(String number) {
    try {
      return _invoices.firstWhere(
        (i) => i.invoiceNumber.toLowerCase() == number.toLowerCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  bool invoiceNumberExists(String number) {
    return _invoices.any(
      (i) => i.invoiceNumber.toLowerCase() == number.toLowerCase().trim(),
    );
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    await Future.wait([loadInvoices(), loadSuppliers()]);
  }

  Future<void> loadInvoices() async {
    _loadingInvoices = true;
    _error = null;
    notifyListeners();

    try {
      _invoices = await _invoiceRepo.fetchAll();
    } on PostgrestException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingInvoices = false;
      notifyListeners();
    }
  }

  Future<void> loadSuppliers() async {
    _loadingSuppliers = true;
    notifyListeners();

    try {
      _suppliers = await _supplierRepo.fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingSuppliers = false;
      notifyListeners();
    }
  }

  /// Fetches full invoice detail (with payments + discounts).
  Future<InvoiceModel?> loadInvoiceDetail(String id) async {
    final detail = await _invoiceRepo.fetchById(id);
    if (detail != null) {
      final idx = _invoices.indexWhere((i) => i.id == id);
      if (idx != -1) {
        _invoices[idx] = detail;
        notifyListeners();
      }
    }
    return detail;
  }

  // ─── Write ────────────────────────────────────────────────────────────────

  /// Returns error string on failure, null on success.
  Future<String?> registerPayment(String invoiceId, PaymentModel payment) async {
    final inv = findById(invoiceId);
    if (inv == null) return 'Factura no encontrada.';
    if (payment.amount <= 0) return 'Monto debe ser mayor a cero.';
    if (payment.amount > inv.balance + 0.01) {
      return 'El pago supera el saldo pendiente (\$${inv.balance.toStringAsFixed(2)}).';
    }

    try {
      await _invoiceRepo.addPayment(payment.toJson().containsKey('invoice_id')
          ? payment
          : PaymentModel(
              id: payment.id,
              invoiceId: invoiceId,
              paymentDate: payment.paymentDate,
              amount: payment.amount,
              method: payment.method,
              notes: payment.notes,
              createdAt: payment.createdAt,
            ));
      // Optimistic update
      final idx = _invoices.indexWhere((i) => i.id == invoiceId);
      if (idx != -1) {
        _invoices[idx] = _invoices[idx].copyWith(
          payments: [..._invoices[idx].payments, payment],
          cachedTotalPaid: null,
          cachedStatus: null,
        );
        notifyListeners();
      }
      // Refresh from server in background
      _refreshInvoice(invoiceId);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Returns error string on failure, null on success.
  Future<String?> addInvoice(InvoiceModel invoice) async {
    if (invoiceNumberExists(invoice.invoiceNumber)) {
      return 'Ya existe una factura con el número ${invoice.invoiceNumber}.';
    }

    try {
      final created = await _invoiceRepo.create(invoice);
      _invoices = [created, ..._invoices];
      notifyListeners();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      // Strip "Exception: " prefix for clean UX
      final msg = e.toString().replaceFirst('Exception: ', '');
      return msg;
    }
  }

  // ─── Realtime ─────────────────────────────────────────────────────────────

  void subscribeToChanges() {
    _channel?.unsubscribe();
    _channel = _invoiceRepo.subscribeToChanges(loadInvoices);
  }

  void unsubscribeFromChanges() {
    _channel?.unsubscribe();
    _channel = null;
  }

  // ─── Computed stats ───────────────────────────────────────────────────────

  double get totalPayable =>
      _invoices.where((i) => i.balance > 0).fold(0.0, (s, i) => s + i.balance);

  double get totalOverdue => _invoices
      .where((i) => i.status == InvoiceStatus.overdue)
      .fold(0.0, (s, i) => s + i.balance);

  double get paidThisMonth {
    final now = DateTime.now();
    return _invoices
        .expand((i) => i.payments)
        .where((p) =>
            p.paymentDate.month == now.month && p.paymentDate.year == now.year)
        .fold(0.0, (s, p) => s + p.amount);
  }

  List<InvoiceModel> get overdueInvoices =>
      _invoices.where((i) => i.status == InvoiceStatus.overdue).toList();

  List<InvoiceModel> get pendingInvoices =>
      _invoices.where((i) => i.status == InvoiceStatus.pending).toList();

  // ─── Private ──────────────────────────────────────────────────────────────

  Future<void> _refreshInvoice(String id) async {
    try {
      final updated = await _invoiceRepo.fetchById(id);
      if (updated != null) {
        final idx = _invoices.indexWhere((i) => i.id == id);
        if (idx != -1) {
          final existing = _invoices[idx];
          // Preserve local evidencePath that isn't stored in DB
          final mergedPayments = updated.payments.map((p) {
            final mem = existing.payments.where((e) => e.id == p.id).firstOrNull;
            if (mem == null) return p;
            return p.copyWith(
              evidencePath: mem.evidencePath,
              evidenceUrl: p.evidenceUrl ?? mem.evidenceUrl,
            );
          }).toList();
          _invoices[idx] = updated.copyWith(payments: mergedPayments);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void reset() {
    _invoices = [];
    _suppliers = [];
    _error = null;
    _loadingInvoices = false;
    _loadingSuppliers = false;
    unsubscribeFromChanges();
    CategoryStore.instance.reset();
    notifyListeners();
  }
}
