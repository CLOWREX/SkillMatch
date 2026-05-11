import 'package:flutter/material.dart';

class AppColors {
  // Base backgrounds
  static const background     = Color(0xFF0F0F13);
  static const surface        = Color(0xFF16161E);
  static const card           = Color(0xFF1E1E2A);
  static const border         = Color(0xFF252535);

  // Neon accents
  static const primary        = Color(0xFFA78BFA); // purple
  static const secondary      = Color(0xFF22D3EE); // cyan
  static const success        = Color(0xFF34D399); // green
  static const error          = Color(0xFFF87171); // red
  static const warning        = Color(0xFFFBBF24); // amber
  static const pink           = Color(0xFFF472B6);

  // Light variants (untuk background chip/badge)
  static const primaryLight   = Color(0x1AA78BFA); // purple 10%
  static const secondaryLight = Color(0x1522D3EE); // cyan 8%
  static const successLight   = Color(0x1534D399); // green 8%
  static const errorLight     = Color(0x15F87171); // red 8%

  // Text
  static const textPrimary    = Color(0xFFE2E8F0);
  static const textSecondary  = Color(0xFF9CA3AF);
  static const textHint       = Color(0xFF4B5563);

  // Gradient utama (purple → cyan)
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData appTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    useMaterial3: true,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
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
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
    color: AppColors.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
  ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.card,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}