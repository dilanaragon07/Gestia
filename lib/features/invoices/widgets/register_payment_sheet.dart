import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/store/invoice_store.dart';
import '../../../shared/widgets/attachment_picker_widget.dart';
import '../../../shared/widgets/status_badge.dart';

class RegisterPaymentSheet extends StatefulWidget {
  const RegisterPaymentSheet({super.key, this.preloadInvoiceId});

  final String? preloadInvoiceId;

  static Future<void> show(BuildContext context, {String? invoiceId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegisterPaymentSheet(preloadInvoiceId: invoiceId),
    );
  }

  @override
  State<RegisterPaymentSheet> createState() => _RegisterPaymentSheetState();
}

class _RegisterPaymentSheetState extends State<RegisterPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  InvoiceModel? _foundInvoice;
  String? _searchError;
  PaymentMethod _method = PaymentMethod.transfer;
  DateTime _paymentDate = DateTime.now();
  bool _saving = false;
  bool _saved = false;
  final List<XFile> _attachments = [];

  final _fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    if (widget.preloadInvoiceId != null) {
      final inv = InvoiceStore.instance.findById(widget.preloadInvoiceId!);
      if (inv != null) {
        _foundInvoice = inv;
        _invoiceNumberCtrl.text = inv.invoiceNumber;
      }
    }
  }

  @override
  void dispose() {
    _invoiceNumberCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _searchInvoice(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _foundInvoice = null;
        _searchError = null;
      });
      return;
    }

    final found = InvoiceStore.instance.findByNumber(value);
    setState(() {
      if (found == null) {
        _foundInvoice = null;
        _searchError = 'No se encontró la factura "$value"';
      } else if (found.status == InvoiceStatus.paid) {
        _foundInvoice = found;
        _searchError = 'Esta factura ya está pagada completamente.';
      } else if (found.status == InvoiceStatus.rejected) {
        _foundInvoice = found;
        _searchError = 'Esta factura fue rechazada — no acepta pagos.';
      } else {
        _foundInvoice = found;
        _searchError = null;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_foundInvoice == null) return;

    final amount = double.tryParse(
          _amountCtrl.text.replaceAll(',', '').replaceAll('\$', '').trim(),
        ) ??
        0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido.')),
      );
      return;
    }

    if (amount > _foundInvoice!.balance + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El pago (\$${amount.toStringAsFixed(2)}) supera el saldo '
            '(\$${_foundInvoice!.balance.toStringAsFixed(2)}).',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final payment = PaymentModel(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      invoiceId: _foundInvoice!.id,
      paymentDate: _paymentDate,
      amount: amount,
      method: _method,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
      evidencePath: _attachments.isNotEmpty ? _attachments.first.path : null,
    );

    final error = await InvoiceStore.instance.registerPayment(_foundInvoice!.id, payment);

    if (!mounted) return;

    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _saving = false;
      _saved = true;
      _foundInvoice = InvoiceStore.instance.findById(_foundInvoice!.id);
    });

    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              _SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.money_send, size: 20, color: AppColors.success),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Registrar Pago', style: AppTypography.textTheme.headlineSmall),
                          Text('Abono a factura existente', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Iconsax.close_circle, size: 20),
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              if (_saved)
                _SuccessConfirmation()
              else
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(20),
                      children: [
                        _SectionLabel(label: 'Buscar Factura'),

                        // Invoice number search
                        TextFormField(
                          controller: _invoiceNumberCtrl,
                          onChanged: _searchInvoice,
                          style: AppTypography.textTheme.bodyLarge,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Número de factura',
                            hintText: 'FAC-2025-XXXX',
                            prefixIcon: const Icon(Iconsax.search_normal, size: 18),
                            suffixIcon: _invoiceNumberCtrl.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _invoiceNumberCtrl.clear();
                                      setState(() {
                                        _foundInvoice = null;
                                        _searchError = null;
                                      });
                                    },
                                    icon: const Icon(Iconsax.close_circle, size: 18),
                                  )
                                : null,
                          ),
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? 'Ingresa el número de factura' : null,
                        ),

                        if (_searchError != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.errorSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Iconsax.warning_2, size: 16, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _searchError!,
                                    style: AppTypography.textTheme.bodySmall
                                        ?.copyWith(color: AppColors.errorLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Invoice summary card
                        if (_foundInvoice != null && _searchError == null) ...[
                          const SizedBox(height: 16),
                          _InvoiceSummaryCard(invoice: _foundInvoice!, fmt: _fmt),
                        ],

                        if (_foundInvoice != null && _searchError == null) ...[
                          const SizedBox(height: 24),
                          _SectionLabel(label: 'Datos del Pago'),

                          // Amount
                          TextFormField(
                            controller: _amountCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            style: AppTypography.moneySmall,
                            decoration: InputDecoration(
                              labelText: 'Valor abonado',
                              prefixIcon: const Icon(Iconsax.dollar_circle, size: 18),
                              prefixText: '\$ ',
                              helperText: _foundInvoice != null
                                  ? 'Saldo: ${_fmt.format(_foundInvoice!.balance)}'
                                  : null,
                              helperStyle: AppTypography.caption.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
                              final n = double.tryParse(v.replaceAll(',', ''));
                              if (n == null || n <= 0) return 'Monto inválido';
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // Payment date
                          _DateField(
                            label: 'Fecha del pago',
                            value: _paymentDate,
                            icon: Iconsax.calendar,
                            onPick: (d) => setState(() => _paymentDate = d),
                          ),

                          const SizedBox(height: 14),

                          // Payment method
                          _MethodSelector(
                            selected: _method,
                            onChanged: (m) => setState(() => _method = m),
                          ),

                          const SizedBox(height: 14),

                          // Notes
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 2,
                            style: AppTypography.textTheme.bodyLarge,
                            decoration: const InputDecoration(
                              labelText: 'Observación (opcional)',
                              prefixIcon: Icon(Iconsax.message, size: 18),
                            ),
                          ),

                          const SizedBox(height: 24),

                          _SectionLabel(label: 'Evidencia Fotográfica'),
                          AttachmentPickerWidget(
                            files: _attachments,
                            onAdd: () async {
                              final picked = await pickAttachments(context);
                              if (picked.isNotEmpty) {
                                setState(() => _attachments.addAll(picked));
                              }
                            },
                            onRemove: (i) => setState(() => _attachments.removeAt(i)),
                          ),

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Iconsax.tick_circle, size: 18),
                              label: Text(_saving ? 'Registrando...' : 'Registrar Pago'),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  const _InvoiceSummaryCard({required this.invoice, required this.fmt});
  final InvoiceModel invoice;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGlowBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (invoice.supplierColor ?? AppColors.primary)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    invoice.supplierInitials,
                    style: TextStyle(
                      color: invoice.supplierColor ?? AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.supplierName, style: AppTypography.textTheme.titleMedium),
                    Text(invoice.invoiceNumber, style: AppTypography.caption),
                  ],
                ),
              ),
              StatusBadge(status: invoice.status),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryPill(
                label: 'Valor final',
                value: fmt.format(invoice.finalAmount),
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              _SummaryPill(
                label: 'Pagado',
                value: fmt.format(invoice.totalPaid),
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _SummaryPill(
                label: 'Saldo',
                value: fmt.format(invoice.balance),
                color: invoice.balance > 0 ? AppColors.warning : AppColors.success,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTypography.textTheme.labelLarge
                  ?.copyWith(color: color, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({required this.selected, required this.onChanged});
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de pago',
          style: AppTypography.textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: PaymentMethod.values.map((m) {
              final isSelected = m == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryMuted : AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          m.icon,
                          size: 16,
                          color: isSelected ? AppColors.primaryLight : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          m.label,
                          style: AppTypography.textTheme.labelMedium?.copyWith(
                            color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SuccessConfirmation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
              ),
              child: const Icon(Iconsax.tick_circle5, size: 40, color: AppColors.success),
            )
                .animate()
                .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.easeOutBack)
                .fadeIn(),
            const SizedBox(height: 20),
            Text('¡Pago Registrado!', style: AppTypography.textTheme.headlineMedium)
                .animate()
                .fadeIn(delay: 150.ms),
            const SizedBox(height: 8),
            Text(
              'El saldo de la factura fue actualizado correctamente.',
              style: AppTypography.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sheet helpers ─────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.tag.copyWith(letterSpacing: 1.2),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPick,
  });
  final String label;
  final DateTime value;
  final IconData icon;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textTertiary),
            const SizedBox(width: 10),
            Text(label, style: AppTypography.textTheme.bodyMedium),
            const Spacer(),
            Text(
              fmt.format(value),
              style: AppTypography.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
