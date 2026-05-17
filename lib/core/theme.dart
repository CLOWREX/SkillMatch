import 'package:flutter/material.dart';

// ── DARK COLORS ──────────────────────────────────────────
class DarkColors {
  static const background    = Color(0xFF0F0F13);
  static const surface       = Color(0xFF16161E);
  static const card          = Color(0xFF1E1E2A);
  static const border        = Color(0xFF252535);
  static const textPrimary   = Color(0xFFE2E8F0);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textHint      = Color(0xFF4B5563);
}

// ── LIGHT COLORS ─────────────────────────────────────────
class LightColors {
  static const background    = Color(0xFFF5F5F7);
  static const surface       = Color(0xFFFFFFFF);
  static const card          = Color(0xFFF0F0F5);
  static const border        = Color(0xFFE2E2EA);
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint      = Color(0xFF9CA3AF);
}

// ── APP COLORS ────────────────────────────────────────────
class AppColors {
  // Warna tetap (sama di dark & light)
  static const primary        = Color(0xFFA78BFA);
  static const secondary      = Color(0xFF22D3EE);
  static const success        = Color(0xFF34D399);
  static const error          = Color(0xFFF87171);
  static const warning        = Color(0xFFFBBF24);
  static const pink           = Color(0xFFF472B6);

  static const primaryLight   = Color(0x1AA78BFA);
  static const secondaryLight = Color(0x1522D3EE);
  static const successLight   = Color(0x1534D399);
  static const errorLight     = Color(0x15F87171);

  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Static const alias (default dark) ──────────────────
  // Untuk backward-compat di widget yang pakai AppColors.background, dll.
  // Widget yang mau ikut tema: gunakan context.bg, context.cardColor, dst.
  static const background    = DarkColors.background;
  static const surface       = DarkColors.surface;
  static const card          = DarkColors.card;
  static const border        = DarkColors.border;
  static const textPrimary   = DarkColors.textPrimary;
  static const textSecondary = DarkColors.textSecondary;
  static const textHint      = DarkColors.textHint;
}

// ── EXTENSION: Warna dinamis lewat BuildContext ───────────
// Pakai: context.bg | context.cardColor | context.textPrimary | dst.
extension AppTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg             => isDark ? DarkColors.background    : LightColors.background;
  Color get surfaceColor   => isDark ? DarkColors.surface       : LightColors.surface;
  Color get cardColor      => isDark ? DarkColors.card          : LightColors.card;
  Color get borderColor    => isDark ? DarkColors.border        : LightColors.border;
  Color get textPrimary    => isDark ? DarkColors.textPrimary   : LightColors.textPrimary;
  Color get textSecondary  => isDark ? DarkColors.textSecondary : LightColors.textSecondary;
  Color get textHint       => isDark ? DarkColors.textHint      : LightColors.textHint;
}

// ── DARK THEME ────────────────────────────────────────────
ThemeData darkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DarkColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: DarkColors.surface,
      error: AppColors.error,
    ),
    useMaterial3: true,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: DarkColors.surface,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: DarkColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      iconTheme: IconThemeData(color: DarkColors.textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: DarkColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: DarkColors.textHint,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DarkColors.card,
      hintStyle: const TextStyle(color: DarkColors.textHint, fontSize: 14),
      labelStyle: const TextStyle(color: DarkColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: DarkColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: DarkColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DarkColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: DarkColors.border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: DarkColors.card,
      contentTextStyle: const TextStyle(color: DarkColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ── LIGHT THEME ───────────────────────────────────────────
ThemeData lightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: LightColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: LightColors.surface,
      error: AppColors.error,
    ),
    useMaterial3: true,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: LightColors.surface,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: LightColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      iconTheme: IconThemeData(color: LightColors.textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: LightColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: LightColors.textHint,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LightColors.card,
      hintStyle: const TextStyle(color: LightColors.textHint, fontSize: 14),
      labelStyle: const TextStyle(color: LightColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LightColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LightColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: LightColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LightColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: LightColors.border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LightColors.surface,
      contentTextStyle: const TextStyle(color: LightColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}