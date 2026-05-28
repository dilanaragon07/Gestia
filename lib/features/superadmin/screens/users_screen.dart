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

  Future<void> _toggleActive(ProfileModel profile) async {
    final updated = profile.copyWith(isActive: !profile.isActive);
    await _repo.update(updated);
    _refresh();
  }

  Future<void> _showCreateUser() async {
    final created = await UserFormSheet.show(context);
    if (created == true) _refresh();
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
            title: Text('Usuarios', style: AppTypography.textTheme.headlineLarge),
            actions: [
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Iconsax.refresh, size: 20),
                color: AppColors.textSecondary,
              ),
            ],
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
                        Text('Error cargando usuarios', style: AppTypography.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _refresh, child: const Text('Reintentar')),
                      ],
                    ),
                  );
                }
                final users = snap.data ?? [];
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _UserCard(
                    profile: users[i],
                    onToggle: () => _toggleActive(users[i]),
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 50), duration: 300.ms),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUser,
        icon: const Icon(Iconsax.user_add),
        label: const Text('Nuevo Usuario'),
      ).animate().fadeIn(delay: 400.ms),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.profile, required this.onToggle});
  final ProfileModel profile;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isSuperadmin = profile.isSuperadmin;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: profile.isActive ? AppColors.border : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isSuperadmin ? AppColors.primaryGradient : null,
              color: isSuperadmin ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: isSuperadmin ? null : Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                profile.initials,
                style: TextStyle(
                  color: isSuperadmin ? Colors.white : AppColors.textSecondary,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.displayName,
                        style: AppTypography.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSuperadmin)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Superadmin',
                          style: AppTypography.tag.copyWith(color: AppColors.primaryLight, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(profile.email, style: AppTypography.caption, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Toggle switch (only for non-superadmin users)
          if (!isSuperadmin)
            Switch(
              value: profile.isActive,
              onChanged: (_) => onToggle(),
              activeThumbColor: AppColors.success,
              inactiveThumbColor: AppColors.error,
              inactiveTrackColor: AppColors.error.withValues(alpha: 0.2),
            ),
        ],
      ),
    );
  }
}
