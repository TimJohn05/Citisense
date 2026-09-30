import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.neutral,
    required this.officer,
    required this.admin,
    required this.mapTile,
    required this.markerColor,
  });

  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color neutral;
  final Color officer;
  final Color admin;
  final Color mapTile;
  final Color markerColor;

  static AppPalette paletteFor({required bool isDark, bool highContrast = false}) {
    if (isDark && highContrast) return darkHighContrast;
    if (isDark) return dark;
    if (highContrast) return lightHighContrast;
    return light;
  }

  static const AppPalette light = AppPalette(
    primary: Color(0xFF0C5396),
    primaryDark: Color(0xFF083F78),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD9E8F7),
    onPrimaryContainer: Color(0xFF093B64),
    background: Color(0xFFF6F8FB),
    surface: Colors.white,
    surfaceMuted: Color(0xFFEEF1F6),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF475467),
    textMuted: Color(0xFF667085),
    border: Color(0xFFE4E7EC),
    success: Color(0xFF0F6B4D),
    successContainer: Color(0xFFD7F0E6),
    warning: Color(0xFF99540E),
    warningContainer: Color(0xFFFCE7C8),
    danger: Color(0xFFC2261A),
    dangerContainer: Color(0xFFFDE2E0),
    neutral: Color(0xFF667085),
    officer: Color(0xFF0F766E),
    admin: Color(0xFF6D28D9),
    mapTile: Color(0xFFE8EDF3),
    markerColor: Color(0xFFD92D20),
  );

  static const AppPalette lightHighContrast = AppPalette(
    primary: Color(0xFF073C72),
    primaryDark: Color(0xFF052B52),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFB9D3F2),
    onPrimaryContainer: Color(0xFF052B52),
    background: Colors.white,
    surface: Colors.white,
    surfaceMuted: Color(0xFFDDE3EC),
    textPrimary: Colors.black,
    textSecondary: Color(0xFF1F2937),
    textMuted: Color(0xFF3F4A5C),
    border: Color(0xFF3F4A5C),
    success: Color(0xFF0A5C3E),
    successContainer: Color(0xFFBCE8D5),
    warning: Color(0xFF6B4200),
    warningContainer: Color(0xFFF8DCAB),
    danger: Color(0xFFA81B11),
    dangerContainer: Color(0xFFF9C7C2),
    neutral: Color(0xFF374151),
    officer: Color(0xFF0A5A53),
    admin: Color(0xFF4A1D96),
    mapTile: Color(0xFFDDE3EC),
    markerColor: Color(0xFFA81B11),
  );

  static const AppPalette dark = AppPalette(
    primary: Color(0xFF6FA8E8),
    primaryDark: Color(0xFF8FBCF0),
    onPrimary: Color(0xFF0A2948),
    primaryContainer: Color(0xFF1E3A5F),
    onPrimaryContainer: Color(0xFFCFE3F8),
    background: Color(0xFF0F1115),
    surface: Color(0xFF171A21),
    surfaceMuted: Color(0xFF232833),
    textPrimary: Color(0xFFF2F5F9),
    textSecondary: Color(0xFFC2C9D6),
    textMuted: Color(0xFF8A93A6),
    border: Color(0xFF303846),
    success: Color(0xFF3DD68C),
    successContainer: Color(0xFF13372A),
    warning: Color(0xFFF0B35B),
    warningContainer: Color(0xFF3A2E12),
    danger: Color(0xFFF2695C),
    dangerContainer: Color(0xFF4E2019),
    neutral: Color(0xFF9AA4B2),
    officer: Color(0xFF4FD1C5),
    admin: Color(0xFFB79AF7),
    mapTile: Color(0xFF1C212B),
    markerColor: Color(0xFFF2695C),
  );

  static const AppPalette darkHighContrast = AppPalette(
    primary: Color(0xFF9CC7F5),
    primaryDark: Color(0xFFBBD9FA),
    onPrimary: Color(0xFF001A33),
    primaryContainer: Color(0xFF23487A),
    onPrimaryContainer: Colors.white,
    background: Colors.black,
    surface: Color(0xFF0B0D10),
    surfaceMuted: Color(0xFF1A1E25),
    textPrimary: Colors.white,
    textSecondary: Color(0xFFE6E9EF),
    textMuted: Color(0xFFB3BBC8),
    border: Color(0xFF8A93A6),
    success: Color(0xFF4EE6A0),
    successContainer: Color(0xFF144029),
    warning: Color(0xFFF8C063),
    warningContainer: Color(0xFF4A3A12),
    danger: Color(0xFFFF6F61),
    dangerContainer: Color(0xFF5E221B),
    neutral: Color(0xFFB3BBC8),
    officer: Color(0xFF5FE3D7),
    admin: Color(0xFFC7B0FA),
    mapTile: Color(0xFF12151B),
    markerColor: Color(0xFFFF6F61),
  );
}

class AppColors {
  AppColors._();

  static AppPalette _current = AppPalette.light;

  static void apply(AppPalette palette) {
    _current = palette;
  }

  static Color get primary => _current.primary;
  static Color get primaryDark => _current.primaryDark;
  static Color get onPrimary => _current.onPrimary;
  static Color get primaryContainer => _current.primaryContainer;
  static Color get onPrimaryContainer => _current.onPrimaryContainer;
  static Color get background => _current.background;
  static Color get surface => _current.surface;
  static Color get surfaceMuted => _current.surfaceMuted;
  static Color get textPrimary => _current.textPrimary;
  static Color get textSecondary => _current.textSecondary;
  static Color get textMuted => _current.textMuted;
  static Color get border => _current.border;
  static Color get success => _current.success;
  static Color get successContainer => _current.successContainer;
  static Color get warning => _current.warning;
  static Color get warningContainer => _current.warningContainer;
  static Color get danger => _current.danger;
  static Color get dangerContainer => _current.dangerContainer;
  static Color get neutral => _current.neutral;
  static Color get officer => _current.officer;
  static Color get admin => _current.admin;
  static Color get mapTile => _current.mapTile;
  static Color get markerColor => _current.markerColor;
}
