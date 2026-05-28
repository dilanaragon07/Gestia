import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/discount_model.dart';
import '../../../data/store/invoice_store.dart';
import '../../../shared/widgets/attachment_picker_widget.dart';

class RegisterInvoiceSheet extends StatefulWidget {
  const RegisterInvoiceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RegisterInvoiceSheet(),
    );
  }

  @override
  State<RegisterInvoiceSheet> createState() => _RegisterInvoiceSheetState();
}

class _RegisterInvoiceSheetState extends State<RegisterInvoiceSheet> {
  final _formKey = GlobalKey<FormState>();

  // Basic info
  final _invoiceNumberCtrl = TextEditingController();
  final _netAmountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedSupplierId;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  // Novedad
  NovedadType _novedad = NovedadType.ok;
  final _novedadTextCtrl = TextEditingController();

  // Discounts
  final List<_DiscountItem> _discountItems = [];

  // Initial payment
  bool _hasInitialPayment = false;
  final _paymentAmountCtrl = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.transfer;
  DateTime _paymentDate = DateTime.now();
  final _paymentNotesCtrl = TextEditingController();

  // Recordatorio
  int? _reminderDays;

  // Mora
  bool _hasMora = false;
  final _moraPercentageCtrl = TextEditingController();

  // Adjuntos
  final List<XFile> _attachments = [];

  bool _saving = false;
  bool _saved = false;
  bool _duplicateError = false;

  final _fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 2);

  double get _totalDiscount =>
      _discountItems.fold(0.0, (s, d) => s + d.lineTotal);

  double get _netAmount =>
      double.tryParse(_netAmountCtrl.text.replaceAll(',', '').trim()) ?? 0;

  double get _finalAmount => _netAmount - _totalDiscount;

  @override
  void dispose() {
    _invoiceNumberCtrl.dispose();
    _netAmountCtrl.dispose();
    _notesCtrl.dispose();
    _novedadTextCtrl.dispose();
    _paymentAmountCtrl.dispose();
    _paymentNotesCtrl.dispose();
    _moraPercentageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _duplicateError = false);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un proveedor.')),
      );
      return;
    }

    if (InvoiceStore.instance.invoiceNumberExists(_invoiceNumberCtrl.text.trim())) {
      setState(() => _duplicateError = true);
      return;
    }

    if (_novedad == NovedadType.desc && _discountItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un ítem de descuento.')),
      );
      return;
    }

    if (_finalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El valor final debe ser mayor a cero.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 900));

    final supplier = InvoiceStore.instance.suppliers
        .firstWhere((s) => s.id == _selectedSupplierId);

    // Build discount
    DiscountModel? discount;
    if (_novedad == NovedadType.desc && _discountItems.isNotEmpty) {
      discount = DiscountModel(
        items: _discountItems
            .map((d) => DiscountDetail(
                  product: d.productCtrl.text,
                  quantity: double.tryParse(d.quantityCtrl.text) ?? 1,
                  originalValue: double.tryParse(d.originalCtrl.text) ?? 0,
                  discountedValue: double.tryParse(d.discountedCtrl.text) ?? 0,
                  reason: d.reasonCtrl.text,
                ))
            .toList(),
      );
    }

    // Build initial payment
    final List<PaymentModel> payments = [];
    if (_hasInitialPayment) {
      final amount =
          double.tryParse(_paymentAmountCtrl.text.replaceAll(',', '').trim()) ?? 0;
      if (amount > 0) {
        payments.add(PaymentModel(
          id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
          invoiceId: 'inv_${DateTime.now().millisecondsSinceEpoch}',
          paymentDate: _paymentDate,
          amount: amount,
          method: _paymentMethod,
          notes: _paymentNotesCtrl.text.trim().isEmpty
              ? null
              : _paymentNotesCtrl.text.trim(),
          createdAt: DateTime.now(),
        ));
      }
    }

    final invoiceId = 'inv_${DateTime.now().millisecondsSinceEpoch}';

    final moraVal = double.tryParse(
        _moraPercentageCtrl.text.replaceAll(',', '').trim());

    final newInvoice = InvoiceModel(
      id: invoiceId,
      invoiceNumber: _invoiceNumberCtrl.text.trim().toUpperCase(),
      supplierId: _selectedSupplierId!,
      supplierName: supplier.name,
      supplierInitials: supplier.initials,
      supplierColor: supplier.avatarColor,
      category: supplier.category,
      issueDate: _issueDate,
      dueDate: _dueDate,
      netAmount: _netAmount,
      discount: discount,
      novedadType: _novedad,
      novedadText: _novedad == NovedadType.other
          ? _novedadTextCtrl.text.trim()
          : null,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      reminderDays: _reminderDays,
      hasMora: _hasMora,
      moraPercentage: _hasMora ? moraVal : null,
      attachmentPaths: _attachments.map((f) => f.path).toList(),
      payments: payments,
    );

    final error = await InvoiceStore.instance.addInvoice(newInvoice);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _duplicateError = true;
      });
      return;
    }

    setState(() {
      _saving = false;
      _saved = true;
    });

    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.97,
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
                        color: AppColors.purpleSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.document_text1, size: 20, color: AppColors.purple),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Registrar Factura', style: AppTypography.textTheme.headlineSmall),
                          Text('Nueva factura a deber', style: AppTypography.caption),
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
                _SuccessBanner()
              else
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // ── INFORMACIÓN PRINCIPAL ──────────────────────────
                        _SectionLabel(label: 'Información Principal'),

                        // Supplier
                        _SupplierPicker(
                          selected: _selectedSupplierId,
                          onChanged: (v) => setState(() => _selectedSupplierId = v),
                        ),

                        const SizedBox(height: 14),

                        // Invoice number
                        TextFormField(
                          controller: _invoiceNumberCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: AppTypography.textTheme.bodyLarge,
                          onChanged: (_) {
                            if (_duplicateError) setState(() => _duplicateError = false);
                          },
                          decoration: InputDecoration(
                            labelText: 'Número de factura',
                            hintText: 'FAC-2025-XXXX',
                            prefixIcon: const Icon(Iconsax.document_text, size: 18),
                            errorText: _duplicateError
                                ? 'Este número ya existe'
                                : null,
                          ),
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? 'Requerido' : null,
                        ),

                        const SizedBox(height: 14),

                        // Dates
                        Row(
                          children: [
                            Expanded(
                              child: _DateField(
                                label: 'Fecha ingreso',
                                value: _issueDate,
                                icon: Iconsax.calendar,
                                onPick: (d) => setState(() => _issueDate = d),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateField(
                                label: 'Vencimiento',
                                value: _dueDate,
                                icon: Iconsax.timer,
                                onPick: (d) => setState(() => _dueDate = d),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Net amount
                        TextFormField(
                          controller: _netAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: AppTypography.moneySmall,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Valor neto',
                            prefixIcon: Icon(Iconsax.dollar_circle, size: 18),
                            prefixText: '\$ ',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            final n = double.tryParse(v.replaceAll(',', ''));
                            if (n == null || n <= 0) return 'Monto inválido';
                            return null;
                          },
                        ),

                        // ── NOVEDADES ────────────────────────────────────
                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Novedades'),

                        _NovedadSelector(
                          selected: _novedad,
                          onChanged: (n) => setState(() {
                            _novedad = n;
                            if (n != NovedadType.desc) _discountItems.clear();
                          }),
                        ),

                        if (_novedad == NovedadType.other) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _novedadTextCtrl,
                            style: AppTypography.textTheme.bodyLarge,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Descripción de la novedad',
                              prefixIcon: Icon(Iconsax.message, size: 18),
                            ),
                            validator: (v) => _novedad == NovedadType.other &&
                                    (v?.isEmpty ?? true)
                                ? 'Describe la novedad'
                                : null,
                          ),
                        ],

                        // Discount section
                        if (_novedad == NovedadType.desc) ...[
                          const SizedBox(height: 16),
                          _DiscountSection(
                            items: _discountItems,
                            onAdd: () => setState(() => _discountItems.add(_DiscountItem())),
                            onRemove: (i) => setState(() => _discountItems.removeAt(i)),
                            onChanged: () => setState(() {}),
                          ),

                          if (_discountItems.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _FinalAmountCard(
                              netAmount: _netAmount,
                              discountAmount: _totalDiscount,
                              finalAmount: _finalAmount,
                              fmt: _fmt,
                            ),
                          ],
                        ],

                        // ── ABONO INICIAL ─────────────────────────────────
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ABONO INICIAL',
                                style: AppTypography.tag.copyWith(letterSpacing: 1.2),
                              ),
                            ),
                            Switch(
                              value: _hasInitialPayment,
                              onChanged: (v) => setState(() => _hasInitialPayment = v),
                              activeThumbColor: AppColors.primary,
                            ),
                          ],
                        ),

                        if (_hasInitialPayment) ...[
                          const SizedBox(height: 12),
                          _InitialPaymentSection(
                            amountCtrl: _paymentAmountCtrl,
                            notesCtrl: _paymentNotesCtrl,
                            method: _paymentMethod,
                            paymentDate: _paymentDate,
                            finalAmount: _finalAmount,
                            fmt: _fmt,
                            onMethodChanged: (m) => setState(() => _paymentMethod = m),
                            onDatePicked: (d) => setState(() => _paymentDate = d),
                            onAmountChanged: () => setState(() {}),
                          ),
                        ],

                        // ── RECORDATORIO ──────────────────────────────────
                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Recordatorio de Vencimiento'),

                        _ReminderSelector(
                          selected: _reminderDays,
                          onChanged: (d) => setState(() => _reminderDays = d),
                        ),

                        // ── MORA ──────────────────────────────────────────
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MORA POR RETRASO',
                                    style: AppTypography.tag.copyWith(letterSpacing: 1.2),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '¿Esta empresa genera mora?',
                                    style: AppTypography.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _hasMora,
                              onChanged: (v) => setState(() => _hasMora = v),
                              activeThumbColor: AppColors.error,
                              activeTrackColor: AppColors.errorSurface,
                            ),
                          ],
                        ),

                        if (_hasMora) ...[
                          const SizedBox(height: 12),
                          _MoraSection(ctrl: _moraPercentageCtrl),
                        ],

                        // ── EVIDENCIA FOTOGRÁFICA ─────────────────────────
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

                        // ── OBSERVACIONES ─────────────────────────────────
                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Observaciones'),

                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          style: AppTypography.textTheme.bodyLarge,
                          decoration: const InputDecoration(
                            hintText: 'Notas adicionales (opcional)',
                            prefixIcon: Icon(Iconsax.message, size: 18),
                          ),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Iconsax.document_upload, size: 18),
                            label: Text(_saving ? 'Guardando...' : 'Registrar Factura'),
                          ),
                        ),

                        const SizedBox(height: 40),
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

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _SupplierPicker extends StatelessWidget {
  const _SupplierPicker({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Empresa / Proveedor', style: AppTypography.textTheme.bodyMedium),
          ),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Iconsax.arrow_down, size: 18, color: AppColors.textTertiary),
          ),
          dropdownColor: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(12),
          items: InvoiceStore.instance.suppliers.map((s) {
            return DropdownMenuItem(
              value: s.id,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: s.avatarColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          s.initials,
                          style: TextStyle(
                            color: s.avatarColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(s.name, style: AppTypography.textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _NovedadSelector extends StatelessWidget {
  const _NovedadSelector({required this.selected, required this.onChanged});
  final NovedadType selected;
  final ValueChanged<NovedadType> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (NovedadType.ok, 'OK', 'Sin novedades', AppColors.success),
      (NovedadType.desc, 'DESC', 'Con descuento', AppColors.warning),
      (NovedadType.other, 'OTRA', 'Novedad personalizada', AppColors.purple),
    ];

    return Row(
      children: options.map((entry) {
        final (type, code, label, color) = entry;
        final isSelected = selected == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color.withValues(alpha: 0.4) : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      code,
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: isSelected ? color : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? color : AppColors.textDisabled,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DiscountItem {
  final productCtrl = TextEditingController();
  final quantityCtrl = TextEditingController(text: '1');
  final originalCtrl = TextEditingController();
  final discountedCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();

  double get lineTotal {
    final qty = double.tryParse(quantityCtrl.text) ?? 1;
    final orig = double.tryParse(originalCtrl.text) ?? 0;
    final disc = double.tryParse(discountedCtrl.text) ?? 0;
    return (orig - disc) * qty;
  }

  void dispose() {
    productCtrl.dispose();
    quantityCtrl.dispose();
    originalCtrl.dispose();
    discountedCtrl.dispose();
    reasonCtrl.dispose();
  }
}

class _DiscountSection extends StatelessWidget {
  const _DiscountSection({
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final List<_DiscountItem> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DETALLE DE DESCUENTO',
          style: AppTypography.tag.copyWith(
            color: AppColors.warning,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        ...List.generate(items.length, (i) {
          return _DiscountItemCard(
            item: items[i],
            index: i,
            onRemove: () => onRemove(i),
            onChanged: onChanged,
          );
        }),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Iconsax.add, size: 16),
          label: const Text('Agregar ítem'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.warning,
            side: const BorderSide(color: AppColors.warning),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }
}

class _DiscountItemCard extends StatelessWidget {
  const _DiscountItemCard({
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  final _DiscountItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTypography.tag.copyWith(color: AppColors.warning),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Iconsax.trash, size: 16, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: item.productCtrl,
            onChanged: (_) => onChanged(),
            style: AppTypography.textTheme.bodyLarge,
            decoration: const InputDecoration(
              labelText: 'Producto',
              isDense: true,
              prefixIcon: Icon(Iconsax.box, size: 16),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.quantityCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  style: AppTypography.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: item.originalCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Valor original',
                    isDense: true,
                    prefixText: '\$ ',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: item.discountedCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Valor descontado',
                    isDense: true,
                    prefixText: '\$ ',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          TextFormField(
            controller: item.reasonCtrl,
            onChanged: (_) => onChanged(),
            style: AppTypography.textTheme.bodyLarge,
            decoration: const InputDecoration(
              labelText: 'Motivo del descuento',
              isDense: true,
              prefixIcon: Icon(Iconsax.message, size: 16),
            ),
          ),

          if (item.lineTotal > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Iconsax.discount_shape, size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  'Descuento línea: ${fmt.format(item.lineTotal)}',
                  style: AppTypography.caption.copyWith(color: AppColors.warningLight),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1);
  }
}

class _FinalAmountCard extends StatelessWidget {
  const _FinalAmountCard({
    required this.netAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.fmt,
  });
  final double netAmount;
  final double discountAmount;
  final double finalAmount;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGlowAmber,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _CalcRow(label: 'Valor neto', value: fmt.format(netAmount)),
          const SizedBox(height: 6),
          _CalcRow(
            label: 'Total descuento',
            value: '− ${fmt.format(discountAmount)}',
            valueColor: AppColors.error,
          ),
          const Divider(height: 16),
          _CalcRow(
            label: 'Valor final',
            value: fmt.format(finalAmount),
            bold: true,
            valueColor: finalAmount > 0 ? AppColors.textPrimary : AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  const _CalcRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.textTheme.bodyMedium),
        Text(
          value,
          style: AppTypography.textTheme.labelLarge?.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            fontSize: bold ? 15 : 13,
          ),
        ),
      ],
    );
  }
}

class _InitialPaymentSection extends StatelessWidget {
  const _InitialPaymentSection({
    required this.amountCtrl,
    required this.notesCtrl,
    required this.method,
    required this.paymentDate,
    required this.finalAmount,
    required this.fmt,
    required this.onMethodChanged,
    required this.onDatePicked,
    required this.onAmountChanged,
  });

  final TextEditingController amountCtrl;
  final TextEditingController notesCtrl;
  final PaymentMethod method;
  final DateTime paymentDate;
  final double finalAmount;
  final NumberFormat fmt;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final ValueChanged<DateTime> onDatePicked;
  final VoidCallback onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final paidAmount =
        double.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final balance = finalAmount - paidAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryMuted),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: amountCtrl,
            onChanged: (_) => onAmountChanged(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTypography.moneySmall,
            decoration: InputDecoration(
              labelText: 'Valor abonado',
              prefixText: '\$ ',
              prefixIcon: const Icon(Iconsax.dollar_circle, size: 18),
              helperText: finalAmount > 0
                  ? 'Valor final: ${fmt.format(finalAmount)}'
                  : null,
              helperStyle: AppTypography.caption,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final n = double.tryParse(v.replaceAll(',', ''));
              if (n != null && n > finalAmount) return 'Supera el valor final';
              return null;
            },
          ),

          const SizedBox(height: 12),

          _DateField(
            label: 'Fecha del abono',
            value: paymentDate,
            icon: Iconsax.calendar,
            onPick: onDatePicked,
          ),

          const SizedBox(height: 12),

          // Method chips (compact)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PaymentMethod.values.map((m) {
                final isSelected = m == method;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onMethodChanged(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryMuted : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        m.label,
                        style: AppTypography.tag.copyWith(
                          color:
                              isSelected ? AppColors.primaryLight : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: notesCtrl,
            style: AppTypography.textTheme.bodyLarge,
            decoration: const InputDecoration(
              labelText: 'Observación',
              prefixIcon: Icon(Iconsax.message, size: 18),
            ),
          ),

          if (paidAmount > 0 && finalAmount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(
                  label: 'Total pagado',
                  value: fmt.format(paidAmount),
                  color: AppColors.success,
                ),
                _MiniStat(
                  label: 'Saldo pendiente',
                  value: fmt.format(balance < 0 ? 0 : balance),
                  color: balance <= 0.01 ? AppColors.success : AppColors.warning,
                ),
                _MiniStat(
                  label: 'Estado inicial',
                  value: balance <= 0.01 ? 'Pagada' : 'Parcial',
                  color: balance <= 0.01 ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.textTheme.labelLarge?.copyWith(color: color, fontSize: 12)),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
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
                color: AppColors.purpleSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
              ),
              child: const Icon(Iconsax.document_upload, size: 36, color: AppColors.purple),
            )
                .animate()
                .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.easeOutBack)
                .fadeIn(),
            const SizedBox(height: 20),
            Text('¡Factura Registrada!', style: AppTypography.textTheme.headlineMedium)
                .animate()
                .fadeIn(delay: 150.ms),
            const SizedBox(height: 8),
            Text(
              'La factura fue guardada correctamente.',
              style: AppTypography.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

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

// ─── Reminder selector ────────────────────────────────────────────────────────

class _ReminderSelector extends StatelessWidget {
  const _ReminderSelector({required this.selected, required this.onChanged});
  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (5, '5 días'),
      (8, '8 días'),
      (15, '15 días'),
      (30, '30 días'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avisar antes del vencimiento',
          style: AppTypography.textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // No recordatorio
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected == null ? AppColors.textDisabled : AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected == null ? AppColors.textTertiary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      'Sin aviso',
                      style: AppTypography.textTheme.labelMedium?.copyWith(
                        color: selected == null
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
              ...options.map((entry) {
                final (days, label) = entry;
                final isSelected = selected == days;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(isSelected ? null : days),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryMuted : AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Icon(
                                Iconsax.notification5,
                                size: 13,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          Text(
                            label,
                            style: AppTypography.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : AppColors.textSecondary,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.notification5, size: 13, color: AppColors.primaryLight),
                const SizedBox(width: 6),
                Text(
                  'Se enviará un aviso $selected días antes del vencimiento',
                  style: AppTypography.caption.copyWith(color: AppColors.primaryLight),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Mora section ─────────────────────────────────────────────────────────────

class _MoraSection extends StatelessWidget {
  const _MoraSection({required this.ctrl});
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.warning_2, size: 15, color: AppColors.error),
              const SizedBox(width: 6),
              Text(
                'Configuración de mora',
                style: AppTypography.textTheme.titleMedium
                    ?.copyWith(color: AppColors.errorLight),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.moneySmall,
                  decoration: InputDecoration(
                    labelText: 'Porcentaje de mora',
                    labelStyle: AppTypography.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.errorLight),
                    suffixText: '%',
                    prefixIcon: const Icon(Iconsax.percentage_circle, size: 18,
                        color: AppColors.error),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el %';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0 || n > 100) return '0–100%';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aplica sobre', style: AppTypography.caption),
                      const SizedBox(height: 4),
                      Text(
                        'Saldo vencido',
                        style: AppTypography.textTheme.labelLarge
                            ?.copyWith(color: AppColors.errorLight, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'La mora se calculará sobre el saldo pendiente una vez vencida la factura.',
            style: AppTypography.caption.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

// ─── Date field ───────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: AppTypography.textTheme.bodyMedium),
            ),
            Text(fmt.format(value), style: AppTypography.textTheme.labelLarge?.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
