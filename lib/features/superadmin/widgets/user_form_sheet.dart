import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/profile_repository.dart';

class UserFormSheet extends StatefulWidget {
  const UserFormSheet({super.key, this.editing});

  final ProfileModel? editing;

  static Future<bool?> show(BuildContext context, {ProfileModel? editing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserFormSheet(editing: editing),
    );
  }

  @override
  State<UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<UserFormSheet> {
  final _repo = ProfileRepository();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;
  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameCtrl.text = widget.editing!.fullName;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    try {
      if (_isEditing) {
        final updated = widget.editing!.copyWith(
          fullName: _nameCtrl.text.trim(),
        );
        await _repo.update(updated);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final error = await _repo.createUser(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          fullName: _nameCtrl.text.trim(),
        );
        if (!mounted) return;
        if (error != null) {
          setState(() { _saving = false; _error = error; });
          return;
        }
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
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
                      child: Icon(
                        _isEditing ? Iconsax.edit_2 : Iconsax.user_add,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
                            style: AppTypography.textTheme.titleLarge,
                          ),
                          Text(
                            _isEditing
                                ? 'Modifica nombre y rol del usuario'
                                : 'Crea un acceso para la aplicación',
                            style: AppTypography.caption,
                          ),
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

              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.warning_2,
                                  size: 16, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: AppTypography.textTheme.bodySmall
                                      ?.copyWith(color: AppColors.errorLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Name
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Iconsax.user, size: 18),
                        ),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 14),

                      // Email + Password (create only)
                      if (!_isEditing) ...[
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Iconsax.sms, size: 18),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (!v.contains('@')) return 'Email inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Iconsax.lock, size: 18),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                              icon: Icon(
                                _obscurePass ? Iconsax.eye_slash : Iconsax.eye,
                                size: 18,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: const Icon(Iconsax.lock_1, size: 18),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(
                                _obscureConfirm ? Iconsax.eye_slash : Iconsax.eye,
                                size: 18,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passCtrl.text)
                              return 'Las contraseñas no coinciden';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(_isEditing ? 'Guardar Cambios' : 'Crear Usuario'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
