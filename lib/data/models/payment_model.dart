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

  String get dbValue => name; // matches DB check constraint
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
  });

  final String id;
  final String invoiceId;
  final DateTime paymentDate;
  final double amount;
  final PaymentMethod method;
  final String? notes;
  final DateTime createdAt;
  final String? evidencePath;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      amount: (json['amount'] as num).toDouble(),
      method: _parseMethod(json['method'] as String?),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'invoice_id': invoiceId,
        'payment_date': paymentDate.toIso8601String().split('T').first,
        'amount': amount,
        'method': method.dbValue,
        'notes': notes,
      };

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
