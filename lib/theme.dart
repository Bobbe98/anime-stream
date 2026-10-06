import 'package:flutter/material.dart';

class AppColors {
  static const accent = Color(0xFF8B5CF6);
  static const accent2 = Color(0xFFEC4899);
  static const bg = Color(0xFF0B0B12);
  static const surface = Color(0xFF16161F);
  static const surfaceHigh = Color(0xFF22222E);
  static const textMuted = Color(0xFFA1A1B5);
  static const premium = Color(0xFFFBBF24);

  static const brandGradient = LinearGradient(
    colors: [accent, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.accent,
        secondary: AppColors.accent2,
        surface: AppColors.surface,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent.withValues(alpha: 0.25),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.surfaceHigh,
      selectedColor: AppColors.accent,
      side: BorderSide.none,
      labelStyle: TextStyle(color: Colors.white),
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: AppColors.accent,
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.textMuted,
      dividerColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
