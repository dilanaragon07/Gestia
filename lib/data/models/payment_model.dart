import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

enum PaymentMethod { transfer, cash, check, card, other }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.transfer => 'Transferencia',
        PaymentMethod.cash => 'Efectivo',
        PaymentMethod.check => 'Cheque',
        PaymentMethod.card => 'Tarjeta',
        PaymentMethod.other => 'Otro',
      };

  IconData get icon => switch (this) {
        PaymentMethod.transfer => Iconsax.money_send,
        PaymentMethod.cash => Iconsax.dollar_circle,
        PaymentMethod.check => Iconsax.document_text,
        PaymentMethod.card => Iconsax.card,
        PaymentMethod.other => Iconsax.moneys,
      };

  String get dbValue => name;
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.paymentDate,
    required this.amount,
    required this.method,
    required this.createdAt,
    this.notes,
    this.evidencePath,
    this.evidenceUrl,
    this.createdById,
    this.createdByName,
  });

  final String id;
  final String invoiceId;
  final DateTime paymentDate;
  final double amount;
  final PaymentMethod method;
  final String? notes;
  final DateTime createdAt;
  final String? evidencePath; // local file (in-session only)
  final String? evidenceUrl;  // persisted URL in Supabase Storage
  final String? createdById;
  final String? createdByName;

  bool get hasEvidence => evidenceUrl != null || evidencePath != null;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      amount: (json['amount'] as num).toDouble(),
      method: _parseMethod(json['method'] as String?),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      evidenceUrl: json['evidence_url'] as String?,
      createdById: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'invoice_id': invoiceId,
        'payment_date': paymentDate.toIso8601String().split('T').first,
        'amount': amount,
        'method': method.dbValue,
        'notes': notes,
        if (evidenceUrl != null) 'evidence_url': evidenceUrl,
      };

  PaymentModel copyWith({
    String? evidencePath,
    String? evidenceUrl,
    String? createdByName,
  }) =>
      PaymentModel(
        id: id,
        invoiceId: invoiceId,
        paymentDate: paymentDate,
        amount: amount,
        method: method,
        notes: notes,
        createdAt: createdAt,
        evidencePath: evidencePath ?? this.evidencePath,
        evidenceUrl: evidenceUrl ?? this.evidenceUrl,
        createdById: createdById,
        createdByName: createdByName ?? this.createdByName,
      );

  static PaymentMethod _parseMethod(String? value) {
    return switch (value) {
      'transfer' => PaymentMethod.transfer,
      'cash' => PaymentMethod.cash,
      'check' => PaymentMethod.check,
      'card' => PaymentMethod.card,
      _ => PaymentMethod.other,
    };
  }
}
