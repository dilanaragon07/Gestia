import 'package:flutter/material.dart';

class SupplierModel {
  const SupplierModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.category,
    required this.taxId,
    required this.totalInvoices,
    required this.totalAmount,
    required this.pendingAmount,
    required this.isActive,
    required this.avatarColor,
    this.address,
    this.website,
  });

  final String id;
  final String name;
  final String initials;
  final String contactName;
  final String email;
  final String phone;
  final String category;
  final String taxId;
  final int totalInvoices;
  final double totalAmount;
  final double pendingAmount;
  final bool isActive;
  final Color avatarColor;
  final String? address;
  final String? website;

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: (json['id'] ?? json['supplier_id']) as String,
      name: (json['name'] ?? json['supplier_name']) as String,
      initials: json['initials'] as String? ?? _initials(json['name'] as String),
      contactName: json['contact_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      taxId: json['tax_id'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      address: json['address'] as String?,
      website: json['website'] as String?,
      avatarColor: _colorForCategory(json['category'] as String?),
      // Aggregates — from get_supplier_summary() function
      totalInvoices: (json['total_invoices'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'initials': initials,
        'contact_name': contactName,
        'email': email,
        'phone': phone,
        'category': category,
        'tax_id': taxId,
        'is_active': isActive,
        'address': address,
        'website': website,
      };

  static String _initials(String name) {
    final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '??';
    if (words.length == 1) return words[0].substring(0, 2).toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
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
}
