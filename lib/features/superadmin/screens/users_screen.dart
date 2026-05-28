import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/profile_repository.dart';
import '../widgets/user_form_sheet.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _repo = ProfileRepository();
  late Future<List<ProfileModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _repo.fetchAll();
  }

  void _refresh() => setState(() => _load());

  Future<void> _showCreateUser() async {
    final ok = await UserFormSheet.show(context);
    if (ok == true) _refresh();
  }

  Future<void> _showEditUser(ProfileModel profile) async {
    final ok = await UserFormSheet.show(context, editing: profile);
    if (ok == true) _refresh();
  }

  Future<void> _toggleActive(ProfileModel profile) async {
    try {
      await _repo.update(profile.copyWith(isActive: !profile.isActive));
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _confirmDeactivate(ProfileModel profile) async {
    final isActive = profile.isActive;
    final action = isActive ? 'desactivar' : 'activar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          '${isActive ? 'Desactivar' : 'Activar'} cuenta',
          style: AppTypography.textTheme.titleLarge,
        ),
        content: Text(
          isActive
              ? '¿Desactivar a "${profile.displayName}"? No podrá iniciar sesión hasta que sea reactivado.'
              : '¿Activar a "${profile.displayName}"? Podrá iniciar sesión nuevamente.',
          style: AppTypography.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isActive ? AppColors.error : AppColors.success,
            ),
            child: Text(isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _toggleActive(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.scaffold,
            pinned: true,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Usuarios', style: AppTypography.textTheme.headlineLarge),
                            Text('Gestión de accesos', style: AppTypography.caption),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _refresh,
                        icon: const Icon(Iconsax.refresh, size: 20),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: FutureBuilder<List<ProfileModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.warning_2, size: 40, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('Error cargando usuarios',
                            style: AppTypography.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _refresh, child: const Text('Reintentar')),
                      ],
                    ),
                  );
                }
                final users = snap.data ?? [];
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.people, size: 48, color: AppColors.textDisabled),
                        const SizedBox(height: 16),
                        Text('Sin usuarios', style: AppTypography.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Crea el primer acceso', style: AppTypography.textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _UserCard(
                    profile: users[i],
                    onEdit: users[i].isSuperadmin ? null : () => _showEditUser(users[i]),
                    onToggleActive: users[i].isSuperadmin ? null : () => _confirmDeactivate(users[i]),
                  ).animate().fadeIn(
                      delay: Duration(milliseconds: i * 50), duration: 300.ms),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_users',
        onPressed: _showCreateUser,
        icon: const Icon(Iconsax.user_add),
        label: const Text('Nuevo Usuario'),
      ).animate().fadeIn(delay: 400.ms),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.profile,
    this.onEdit,
    this.onToggleActive,
  });

  final ProfileModel profile;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;

  Color get _roleColor =>
      profile.isSuperadmin ? AppColors.primary : AppColors.textTertiary;

  String get _roleLabel =>
      profile.isSuperadmin ? 'Superadmin' : 'Usuario';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: profile.isActive
              ? AppColors.border
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: profile.isSuperadmin ? AppColors.primaryGradient : null,
                  color: profile.isSuperadmin ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: profile.isSuperadmin
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    profile.initials,
                    style: TextStyle(
                      color: profile.isSuperadmin
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: AppTypography.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.email,
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Edit button (non-superadmin only)
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Iconsax.edit_2, size: 18),
                  color: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          Row(
            children: [
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _roleLabel,
                  style: AppTypography.tag.copyWith(
                    color: _roleColor,
                    fontSize: 10,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Active badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (profile.isActive ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  profile.isActive ? 'Activo' : 'Inactivo',
                  style: AppTypography.tag.copyWith(
                    color: profile.isActive ? AppColors.success : AppColors.error,
                    fontSize: 10,
                  ),
                ),
              ),

              const Spacer(),

              // Toggle active (non-superadmin only)
              if (onToggleActive != null)
                TextButton.icon(
                  onPressed: onToggleActive,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        profile.isActive ? AppColors.error : AppColors.success,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(
                    profile.isActive ? Iconsax.slash : Iconsax.tick_circle,
                    size: 14,
                  ),
                  label: Text(
                    profile.isActive ? 'Desactivar' : 'Activar',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
