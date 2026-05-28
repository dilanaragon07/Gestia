import 'package:flutter/material.dart';

class SupplierModel {
  const SupplierModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.taxId,
    required this.totalInvoices,
    required this.totalAmount,
    required this.pendingAmount,
    required this.isActive,
    required this.avatarColor,
    required this.tags,
    this.address,
    this.website,
  });

  final String id;
  final String name;
  final String initials;
  final String contactName;
  final String email;
  final String phone;
  final String taxId;
  final int totalInvoices;
  final double totalAmount;
  final double pendingAmount;
  final bool isActive;
  final Color avatarColor;
  final List<String> tags;
  final String? address;
  final String? website;

  String get category => tags.isNotEmpty ? tags.first : '';

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List
        ? List<String>.from(rawTags.map((t) => t?.toString() ?? '').where((t) => t.isNotEmpty))
        : <String>[];

    return SupplierModel(
      id: (json['id'] ?? json['supplier_id']) as String,
      name: (json['name'] ?? json['supplier_name']) as String,
      initials: json['initials'] as String? ?? _initials(json['name'] as String? ?? ''),
      contactName: json['contact_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      taxId: json['tax_id'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      address: json['address'] as String?,
      website: json['website'] as String?,
      tags: tags,
      avatarColor: _colorForTags(tags),
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
        'tax_id': taxId,
        'is_active': isActive,
        'address': address,
        'website': website,
        'tags': tags,
      };

  SupplierModel copyWith({List<String>? tags}) => SupplierModel(
        id: id,
        name: name,
        initials: initials,
        contactName: contactName,
        email: email,
        phone: phone,
        taxId: taxId,
        totalInvoices: totalInvoices,
        totalAmount: totalAmount,
        pendingAmount: pendingAmount,
        isActive: isActive,
        avatarColor: tags != null ? _colorForTags(tags) : avatarColor,
        tags: tags ?? this.tags,
        address: address,
        website: website,
      );

  static String _initials(String name) {
    final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '??';
    if (words.length == 1) return words[0].substring(0, 2).toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  static const _palette = [
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFF8B5CF6),
    Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFEC4899),
    Color(0xFF06B6D4), Color(0xFF84CC16), Color(0xFFF97316),
    Color(0xFF14B8A6),
  ];

  static Color _colorForTags(List<String> tags) {
    if (tags.isEmpty) return _palette[0];
    final hash = tags.first.codeUnits.fold(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }
}
