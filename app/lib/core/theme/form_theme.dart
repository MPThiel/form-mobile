import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form_colors.dart';
import 'form_typography.dart';

/// Dark-mode ThemeData for FORM. Wired into [MaterialApp] in app.dart.
abstract final class FormTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: FormColors.primary,
      onPrimary: Colors.black,
      secondary: FormColors.secondary,
      onSecondary: Colors.black,
      surface: FormColors.surface,
      onSurface: FormColors.onSurface,
      surfaceContainerHighest: FormColors.surfaceHigh,
      outline: FormColors.border,
      error: FormColors.danger,
      onError: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: FormColors.bg,
      canvasColor: FormColors.bg,
      textTheme: FormTypography.textTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: FormColors.bg,
        foregroundColor: FormColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: FormColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: FormColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FormColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: FormTypography.prose(
            size: 16,
            weight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FormColors.onSurface,
          side: const BorderSide(color: FormColors.border, width: 1),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FormColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FormColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FormColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FormColors.primary, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FormColors.surface,
        selectedItemColor: FormColors.primary,
        unselectedItemColor: FormColors.onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(color: FormColors.border, thickness: 1),
    );
  }
}
