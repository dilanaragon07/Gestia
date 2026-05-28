import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    required this.onRegisterPayment,
    required this.onRegisterInvoice,
  });

  final VoidCallback onRegisterPayment;
  final VoidCallback onRegisterInvoice;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  OverlayEntry? _overlayEntry;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotate = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _removeOverlay();
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    if (_open) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    setState(() => _open = true);
    _ctrl.forward();
    _insertOverlay();
  }

  void _closeMenu() {
    _ctrl.reverse().whenComplete(() {
      if (mounted) setState(() => _open = false);
    });
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _insertOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).padding.bottom;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (ctx, child) {
            return Stack(
              children: [
                // ── Fondo oscuro ───────────────────────────
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _fade.value < 0.01,
                    child: GestureDetector(
                      onTap: _closeMenu,
                      child: Container(
                        color: Colors.black.withValues(
                          alpha: 0.6 * _fade.value,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Mini FABs (encima del backdrop) ────────
                Positioned(
                  right: 16,
                  bottom: bottom + 80, // encima del main FAB
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MiniActionButton(
                        icon: Iconsax.document_text1,
                        label: 'Registrar Factura',
                        color: AppColors.purple,
                        delay: 0.0,
                        controller: _ctrl,
                        onTap: () {
                          _closeMenu();
                          Future.delayed(
                            const Duration(milliseconds: 120),
                            widget.onRegisterInvoice,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _MiniActionButton(
                        icon: Iconsax.money_send,
                        label: 'Registrar Pago',
                        color: AppColors.success,
                        delay: 0.08,
                        controller: _ctrl,
                        onTap: () {
                          _closeMenu();
                          Future.delayed(
                            const Duration(milliseconds: 120),
                            widget.onRegisterPayment,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotate,
      builder: (context, child) {
        return FloatingActionButton.extended(
          heroTag: 'fab_expandable',
          onPressed: _toggle,
          backgroundColor: _open ? AppColors.cardElevated : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          icon: Transform.rotate(
            angle: _rotate.value * 2 * 3.14159265,
            child: Icon(_open ? Icons.close_rounded : Icons.add_rounded, size: 22),
          ),
          label: AnimatedCrossFade(
            firstChild: Text(
              'Nueva Factura',
              style: AppTypography.textTheme.labelLarge
                  ?.copyWith(color: Colors.white),
            ),
            secondChild: Text(
              'Cerrar',
              style: AppTypography.textTheme.labelLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            crossFadeState:
                _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: _open
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        );
      },
    );
  }
}

// ─── Mini action button ───────────────────────────────────────────────────────

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.delay,
    required this.scale,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double delay;
  final AnimationController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final staggered = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, 1.0, curve: Curves.easeOutBack),
    );

    return ScaleTransition(
      scale: staggered,
      alignment: Alignment.bottomRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label chip
          Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            elevation: 0,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: AppTypography.textTheme.labelLarge,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Icon button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 22, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
