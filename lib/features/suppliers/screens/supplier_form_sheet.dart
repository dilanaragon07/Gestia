import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../data/store/category_store.dart';

class SupplierFormSheet extends StatefulWidget {
  const SupplierFormSheet({super.key, this.editing});

  final SupplierModel? editing;

  static Future<bool?> show(BuildContext context, {SupplierModel? editing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SupplierFormSheet(editing: editing),
    );
  }

  @override
  State<SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<SupplierFormSheet> {
  final _repo = SupplierRepository();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  late final Set<String> _selectedTags;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _selectedTags = e != null ? Set<String>.from(e.tags) : {};
    if (e != null) {
      _nameCtrl.text = e.name;
      _contactCtrl.text = e.contactName;
      _emailCtrl.text = e.email;
      _phoneCtrl.text = e.phone;
      _taxIdCtrl.text = e.taxId;
      _addressCtrl.text = e.address ?? '';
      _websiteCtrl.text = e.website ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _taxIdCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final supplier = SupplierModel(
        id: widget.editing?.id ?? '',
        name: _nameCtrl.text.trim(),
        initials: '',
        contactName: _contactCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        taxId: _taxIdCtrl.text.trim(),
        totalInvoices: widget.editing?.totalInvoices ?? 0,
        totalAmount: widget.editing?.totalAmount ?? 0,
        pendingAmount: widget.editing?.pendingAmount ?? 0,
        isActive: widget.editing?.isActive ?? true,
        avatarColor: const Color(0xFF3B82F6),
        tags: _selectedTags.toList(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        website: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
      );

      if (_isEditing) {
        await _repo.update(widget.editing!.id, supplier);
      } else {
        await _repo.create(supplier);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryStore.instance.categories;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.building_4, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor', style: AppTypography.textTheme.titleLarge),
                        Text(_isEditing ? 'Actualiza los datos del proveedor' : 'Completa los datos del proveedor', style: AppTypography.caption),
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
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(_error!, style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.errorLight)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _label('Nombre *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Empresa SA de CV'),
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    // Tags / categories
                    _label('Etiquetas / Categorías'),
                    const SizedBox(height: 8),
                    if (categories.isEmpty)
                      Text(
                        'No hay categorías creadas. El administrador debe crearlas primero.',
                        style: AppTypography.caption,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final selected = _selectedTags.contains(cat.name);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (selected) {
                                _selectedTags.remove(cat.name);
                              } else {
                                _selectedTags.add(cat.name);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected
                                    ? cat.color.withValues(alpha: 0.2)
                                    : AppColors.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? cat.color : AppColors.border,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selected) ...[
                                    Icon(Icons.check, size: 12, color: cat.color),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    cat.name,
                                    style: AppTypography.textTheme.labelMedium?.copyWith(
                                      color: selected ? cat.color : AppColors.textSecondary,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),

                    _label('RFC / Tax ID'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _taxIdCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(hintText: 'ABC123456XY1'),
                    ),
                    const SizedBox(height: 16),
                    _label('Contacto'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contactCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Nombre del contacto'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Email'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(hintText: 'correo@empresa.com'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Teléfono'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(hintText: '+52 55 0000 0000'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label('Dirección'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(hintText: 'Calle, Ciudad'),
                    ),
                    const SizedBox(height: 16),
                    _label('Sitio web'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _websiteCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(hintText: 'empresa.com'),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(_isEditing ? 'Actualizar Proveedor' : 'Guardar Proveedor'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
      );
}
