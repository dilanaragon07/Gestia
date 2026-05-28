import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.scaffold,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.purple,
          onSecondary: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
          onError: Colors.white,
          outline: AppColors.border,
          surfaceContainerHighest: AppColors.cardElevated,
        ),
        textTheme: AppTypography.textTheme,
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.scaffold,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.surface,
          ),
          titleTextStyle: AppTypography.textTheme.headlineMedium,
          iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
          actionsIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryMuted,
          iconTheme: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primaryLight, size: 22);
            }
            return const IconThemeData(color: AppColors.textTertiary, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.selected)) {
              return AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              );
            }
            return AppTypography.textTheme.labelSmall;
          }),
          elevation: 0,
          height: 68,
          surfaceTintColor: Colors.transparent,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.surface,
          elevation: 0,
          width: 300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: AppTypography.textTheme.bodyMedium,
          labelStyle: AppTypography.textTheme.titleSmall,
          floatingLabelStyle: AppTypography.textTheme.titleSmall?.copyWith(
            color: AppColors.primary,
          ),
          prefixIconColor: AppColors.textTertiary,
          suffixIconColor: AppColors.textTertiary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: AppTypography.textTheme.labelLarge?.copyWith(fontSize: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            textStyle: AppTypography.textTheme.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: AppTypography.textTheme.labelLarge,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.card,
          selectedColor: AppColors.primaryMuted,
          disabledColor: AppColors.card,
          labelStyle: AppTypography.textTheme.labelMedium,
          secondaryLabelStyle: AppTypography.textTheme.labelMedium?.copyWith(
            color: AppColors.primaryLight,
          ),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          modalBackgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          iconColor: AppColors.textTertiary,
          textColor: AppColors.textPrimary,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.cardElevated,
          contentTextStyle: AppTypography.textTheme.bodyMedium,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: AppTypography.textTheme.headlineMedium,
          contentTextStyle: AppTypography.textTheme.bodyMedium,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.cardElevated,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          textStyle: AppTypography.textTheme.bodyMedium,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.border,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: AppTypography.textTheme.labelLarge,
          unselectedLabelStyle: AppTypography.textTheme.labelLarge?.copyWith(
            color: AppColors.textTertiary,
          ),
          dividerColor: AppColors.border,
        ),
      );
}
