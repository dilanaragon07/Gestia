import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/store/invoice_store.dart';
import '../../../data/store/category_store.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSupplierId;
  String? _selectedCategory;
  DateTime? _issueDate;
  DateTime? _dueDate;
  bool _saving = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Iconsax.close_circle),
        ),
        title: const Text('Nueva Factura'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FormSection(title: 'Proveedor')
                  .animate()
                  .fadeIn(duration: 300.ms),

              // Supplier picker
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSupplierId,
                    isExpanded: true,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Seleccionar proveedor',
                        style: AppTypography.textTheme.bodyMedium,
                      ),
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
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: s.avatarColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    s.initials,
                                    style: TextStyle(
                                      color: s.avatarColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(s.name, style: AppTypography.textTheme.titleMedium),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedSupplierId = v),
                  ),
                ),
              ).animate().fadeIn(delay: 60.ms, duration: 300.ms),

              const SizedBox(height: 20),
              _FormSection(title: 'Información de Factura')
                  .animate()
                  .fadeIn(delay: 100.ms),
              const SizedBox(height: 12),

              // Invoice number
              TextFormField(
                style: AppTypography.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Número de factura',
                  prefixIcon: Icon(Iconsax.document_text, size: 18),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
              ).animate().fadeIn(delay: 120.ms),

              const SizedBox(height: 14),

              // Category
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Categoría',
                        style: AppTypography.textTheme.bodyMedium,
                      ),
                    ),
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Iconsax.arrow_down, size: 18, color: AppColors.textTertiary),
                    ),
                    dropdownColor: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(12),
                    items: CategoryStore.instance.categories
                        .map((cat) => DropdownMenuItem(
                              value: cat.name,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(cat.name, style: AppTypography.textTheme.bodyLarge),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
              ).animate().fadeIn(delay: 140.ms),

              const SizedBox(height: 20),
              _FormSection(title: 'Montos').animate().fadeIn(delay: 160.ms),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      style: AppTypography.textTheme.bodyLarge,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Subtotal',
                        prefixIcon: Icon(Iconsax.dollar_circle, size: 18),
                        prefixText: '\$ ',
                      ),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      style: AppTypography.textTheme.bodyLarge,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'IVA (16%)',
                        prefixIcon: Icon(Iconsax.percentage_circle, size: 18),
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 180.ms),

              const SizedBox(height: 20),
              _FormSection(title: 'Fechas').animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _DatePicker(
                      label: 'Fecha emisión',
                      value: _issueDate,
                      icon: Iconsax.calendar,
                      onPick: (d) => setState(() => _issueDate = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePicker(
                      label: 'Vencimiento',
                      value: _dueDate,
                      icon: Iconsax.timer,
                      onPick: (d) => setState(() => _dueDate = d),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 220.ms),

              const SizedBox(height: 20),
              _FormSection(title: 'Notas (opcional)')
                  .animate()
                  .fadeIn(delay: 240.ms),
              const SizedBox(height: 12),

              TextFormField(
                style: AppTypography.textTheme.bodyLarge,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Observaciones, referencias, etc...',
                  alignLabelWithHint: true,
                ),
              ).animate().fadeIn(delay: 260.ms),

              const SizedBox(height: 32),

              // Attachment
              _AttachmentButton()
                  .animate()
                  .fadeIn(delay: 280.ms),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Registrar Factura'),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura registrada correctamente')),
      );
    }
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.tag.copyWith(letterSpacing: 1.2),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPick,
  });
  final String label;
  final DateTime? value;
  final IconData icon;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme,
            ),
            child: child!,
          ),
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
              child: Text(
                value != null
                    ? '${value!.day}/${value!.month}/${value!.year}'
                    : label,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: value != null ? AppColors.textPrimary : AppColors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.document_upload, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Text(
            'Adjuntar XML / PDF',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
