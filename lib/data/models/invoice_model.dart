import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'payment_model.dart';
import 'discount_model.dart';

enum InvoiceStatus { pending, partial, paid, overdue, rejected }
enum NovedadType { ok, desc, other }

extension InvoiceStatusX on InvoiceStatus {
  String get label => switch (this) {
        InvoiceStatus.pending => 'Pendiente',
        InvoiceStatus.partial => 'Parcial',
        InvoiceStatus.paid => 'Pagada',
        InvoiceStatus.overdue => 'Vencida',
        InvoiceStatus.rejected => 'Rechazada',
      };

  Color get color => switch (this) {
        InvoiceStatus.pending => AppColors.primary,
        InvoiceStatus.partial => AppColors.warning,
        InvoiceStatus.paid => AppColors.success,
        InvoiceStatus.overdue => AppColors.error,
        InvoiceStatus.rejected => AppColors.textTertiary,
      };

  Color get surfaceColor => switch (this) {
        InvoiceStatus.pending => AppColors.primarySurface,
        InvoiceStatus.partial => AppColors.warningSurface,
        InvoiceStatus.paid => AppColors.successSurface,
        InvoiceStatus.overdue => AppColors.errorSurface,
        InvoiceStatus.rejected => AppColors.card,
      };
}

class InvoiceModel {
  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.supplierId,
    required this.supplierName,
    required this.supplierInitials,
    required this.netAmount,
    required this.issueDate,
    required this.dueDate,
    required this.category,
    this.supplierColor,
    this.notes,
    this.isRejected = false,
    this.novedadType = NovedadType.ok,
    this.novedadText,
    this.discount,
    this.reminderDays,
    this.hasMora = false,
    this.moraPercentage,
    this.attachmentPaths = const [],
    this.createdById,
    this.createdByName,
    List<PaymentModel>? payments,
    this._cachedTotalPaid,
    this._cachedPaymentCount,
    this._cachedStatus,
  })  : payments = payments ?? [];

  final String id;
  final String invoiceNumber;
  final String supplierId;
  final String supplierName;
  final String supplierInitials;
  final Color? supplierColor;
  final String category;
  final DateTime issueDate;
  final DateTime dueDate;
  final String? notes;
  final bool isRejected;
  final double netAmount;
  final DiscountModel? discount;
  final NovedadType novedadType;
  final String? novedadText;
  final int? reminderDays;
  final bool hasMora;
  final double? moraPercentage;
  final List<String> attachmentPaths;
  final String? createdById;
  final String? createdByName;
  final List<PaymentModel> payments;

  // Supabase view aggregates (used when full payments list not loaded)
  final double? _cachedTotalPaid;
  final int? _cachedPaymentCount;
  final InvoiceStatus? _cachedStatus;

  // Computed
  double get discountAmount => discount?.totalDiscount ?? 0;
  double get finalAmount => netAmount - discountAmount;

  double get totalPaid =>
      _cachedTotalPaid ?? payments.fold(0.0, (s, p) => s + p.amount);

  int get paymentCount => _cachedPaymentCount ?? payments.length;

  double get balance => finalAmount - totalPaid;

  InvoiceStatus get status {
    // If coming from Supabase view (no payments loaded), use cached status
    if (_cachedStatus != null && payments.isEmpty) return _cachedStatus;
    if (isRejected) return InvoiceStatus.rejected;
    if (balance <= 0.01) return InvoiceStatus.paid;
    if (totalPaid > 0) return InvoiceStatus.partial;
    if (DateTime.now().isAfter(dueDate)) return InvoiceStatus.overdue;
    return InvoiceStatus.pending;
  }

  bool get isOverdue => balance > 0 && DateTime.now().isAfter(dueDate);

  // ─── fromJson (Supabase invoice_summary view) ────────────────────────────
  factory InvoiceModel.fromListJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String? ?? '',
      supplierInitials: json['supplier_initials'] as String? ?? '??',
      netAmount: (json['net_amount'] as num).toDouble(),
      issueDate: DateTime.parse(json['issue_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      category: _inferCategory(json),
      supplierColor: _colorForCategory(_inferCategory(json)),
      notes: json['notes'] as String?,
      isRejected: json['is_rejected'] as bool? ?? false,
      novedadType: _parseNovedad(json['novedad_type'] as String?),
      novedadText: json['novedad_text'] as String?,
      reminderDays: json['reminder_days'] as int?,
      hasMora: json['has_mora'] as bool? ?? false,
      moraPercentage: (json['mora_percentage'] as num?)?.toDouble(),
      payments: [],
      createdById: json['created_by'] as String?,
      cachedTotalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
      cachedPaymentCount: (json['payment_count'] as num?)?.toInt() ?? 0,
      cachedStatus: _parseStatus(json['status'] as String?),
    );
  }

  // ─── fromJson with full details (payments + discounts loaded) ────────────
  factory InvoiceModel.fromDetailJson(
    Map<String, dynamic> json, {
    required List<PaymentModel> payments,
    DiscountModel? discount,
    String? createdByName,
  }) {
    return InvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String? ?? '',
      supplierInitials: json['supplier_initials'] as String? ?? '??',
      netAmount: (json['net_amount'] as num).toDouble(),
      issueDate: DateTime.parse(json['issue_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      category: _inferCategory(json),
      supplierColor: _colorForCategory(_inferCategory(json)),
      notes: json['notes'] as String?,
      isRejected: json['is_rejected'] as bool? ?? false,
      novedadType: _parseNovedad(json['novedad_type'] as String?),
      novedadText: json['novedad_text'] as String?,
      reminderDays: json['reminder_days'] as int?,
      hasMora: json['has_mora'] as bool? ?? false,
      moraPercentage: (json['mora_percentage'] as num?)?.toDouble(),
      discount: discount,
      payments: payments,
      createdById: json['created_by'] as String?,
      createdByName: createdByName,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'invoice_number': invoiceNumber,
        'supplier_id': supplierId,
        'issue_date': issueDate.toIso8601String().split('T').first,
        'due_date': dueDate.toIso8601String().split('T').first,
        'net_amount': netAmount,
        'novedad_type': novedadType.name,
        'novedad_text': novedadText,
        'is_rejected': isRejected,
        'notes': notes,
        'reminder_days': reminderDays,
        'has_mora': hasMora,
        'mora_percentage': moraPercentage,
      };

  InvoiceModel copyWith({
    List<PaymentModel>? payments,
    DiscountModel? discount,
    double? netAmount,
    DateTime? dueDate,
    String? notes,
    bool? isRejected,
    NovedadType? novedadType,
    String? novedadText,
    int? reminderDays,
    bool? hasMora,
    double? moraPercentage,
    List<String>? attachmentPaths,
    double? cachedTotalPaid,
    int? cachedPaymentCount,
    InvoiceStatus? cachedStatus,
  }) {
    return InvoiceModel(
      id: id,
      invoiceNumber: invoiceNumber,
      supplierId: supplierId,
      supplierName: supplierName,
      supplierInitials: supplierInitials,
      supplierColor: supplierColor,
      category: category,
      issueDate: issueDate,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      isRejected: isRejected ?? this.isRejected,
      netAmount: netAmount ?? this.netAmount,
      discount: discount ?? this.discount,
      novedadType: novedadType ?? this.novedadType,
      novedadText: novedadText ?? this.novedadText,
      reminderDays: reminderDays ?? this.reminderDays,
      hasMora: hasMora ?? this.hasMora,
      moraPercentage: moraPercentage ?? this.moraPercentage,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      createdById: createdById,
      createdByName: createdByName,
      payments: payments ?? this.payments,
      cachedTotalPaid: cachedTotalPaid ?? _cachedTotalPaid,
      cachedPaymentCount: cachedPaymentCount ?? _cachedPaymentCount,
      cachedStatus: cachedStatus ?? _cachedStatus,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static String _inferCategory(Map<String, dynamic> json) {
    return json['category'] as String? ?? 'General';
  }

  static Color _colorForCategory(String? category) {
    return switch (category) {
      'Tecnología' => const Color(0xFF3B82F6),
      'Logística' => const Color(0xFF10B981),
      'Servicios' => const Color(0xFF8B5CF6),
      'Manufactura' => const Color(0xFFF59E0B),
      'Diseño' => const Color(0xFFEF4444),
      'Marketing' => const Color(0xFFEC4899),
      'Consultoría' => const Color(0xFF06B6D4),
      _ => const Color(0xFF3B82F6),
    };
  }

  static NovedadType _parseNovedad(String? v) => switch (v) {
        'desc' => NovedadType.desc,
        'other' => NovedadType.other,
        _ => NovedadType.ok,
      };

  static InvoiceStatus _parseStatus(String? v) => switch (v) {
        'paid' => InvoiceStatus.paid,
        'partial' => InvoiceStatus.partial,
        'overdue' => InvoiceStatus.overdue,
        'rejected' => InvoiceStatus.rejected,
        _ => InvoiceStatus.pending,
      };
}
