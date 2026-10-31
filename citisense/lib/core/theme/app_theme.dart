import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

enum ThemeStyle { system, light, dark, highContrast }

class AppTheme {
  AppTheme._();

  static ThemeData themeFor({required bool dark, bool highContrast = false}) {
    final palette = AppPalette.paletteFor(isDark: dark, highContrast: highContrast);

    final scheme = dark
        ? ColorScheme.dark(
            primary: palette.primary,
            onPrimary: palette.onPrimary,
            primaryContainer: palette.primaryContainer,
            onPrimaryContainer: palette.onPrimaryContainer,
            secondary: palette.success,
            onSecondary: palette.onPrimary,
            surface: palette.surface,
            onSurface: palette.textPrimary,
            error: palette.danger,
            onError: palette.onPrimary,
            outline: palette.border,
          )
        : ColorScheme.light(
            primary: palette.primary,
            onPrimary: palette.onPrimary,
            primaryContainer: palette.primaryContainer,
            onPrimaryContainer: palette.onPrimaryContainer,
            secondary: palette.success,
            onSecondary: palette.onPrimary,
            surface: palette.surface,
            onSurface: palette.textPrimary,
            error: palette.danger,
            onError: palette.onPrimary,
            outline: palette.border,
          );

    return _build(scheme, palette);
  }

  static ThemeData light() => themeFor(dark: false);

  static ThemeData _build(ColorScheme scheme, AppPalette p) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
    );

    final textTheme = GoogleFonts.publicSansTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme
          .copyWith(
            displaySmall: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: p.textPrimary,
            ),
            headlineMedium: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: p.textPrimary,
            ),
            headlineSmall: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
            titleLarge: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
            titleMedium: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
            bodyLarge: textTheme.bodyLarge?.copyWith(
              color: p.textPrimary,
            ),
            bodyMedium: textTheme.bodyMedium?.copyWith(
              color: p.textSecondary,
            ),
            labelLarge: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          )
          .apply(
            bodyColor: p.textPrimary,
            displayColor: p.textPrimary,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: p.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.danger),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceMuted,
        selectedColor: p.primaryContainer,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: p.onPrimaryContainer,
        ),
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primaryContainer,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? p.primary
                : p.textMuted,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primaryContainer
              : p.surfaceMuted,
        ),
      ),
    );
  }
}
