import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/invoice_model.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final InvoiceStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: status.color.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: AppTypography.tag.copyWith(
          color: status.color,
          fontSize: compact ? 9 : 10,
        ),
      ),
    );
  }
}
