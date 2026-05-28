import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size, this.showGlow = true});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF1EAAFF).withValues(alpha: 0.28),
                  blurRadius: size * 0.7,
                  spreadRadius: size * 0.02,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
