import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme? getTextTheme(Locale? locale, {bool isDark = false}) {
  if (locale?.languageCode == 'zh' &&
      (Platform.isWindows || Platform.isLinux)) {
    return GoogleFonts.notoSansScTextTheme(
      ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
      ).textTheme,
    );
  }
  return null;
}

// Custom color extensions for app-specific needs only
// All standard colors should use ColorScheme properties directly:
// - primary, secondary, tertiary
// - surface, background
// - onPrimary, onSecondary, onSurface, onBackground
// - outline, outlineVariant
extension AppColors on ColorScheme {
  Color get bgColor => brightness == Brightness.dark
      ? const Color(0xFF0F172A)
      : const Color(0xFFF8FAFC);

  Color get bgSecondary => surface;

  Color get inactiveColor => brightness == Brightness.dark
      ? const Color(0xFF334155)
      : const Color(0xFFCBD5E1);

  Color get borderColor => const Color(0xFF805306);
  Color get sidebarColor => const Color(0xFFF6A00C);
  Color get backgroundStartColor => const Color(0xFFFFD500);
  Color get backgroundEndColor => const Color(0xFFF6A00C);

  Color get surfaceOverlay => onSurface.withOpacity(0.05);
  Color get surfaceOverlayLight => onSurface.withOpacity(0.08);
  Color get surfaceOverlayLighter => onSurface.withOpacity(0.1);

  Color get borderLight => onSurface.withOpacity(0.1);
  Color get borderMedium => onSurface.withOpacity(0.24);

  Color get shadowDark => brightness == Brightness.dark
      ? Colors.black.withOpacity(0.54)
      : Colors.black.withOpacity(0.12);
  Color get shadowLight => brightness == Brightness.dark
      ? Colors.black.withOpacity(0.26)
      : onSurface.withOpacity(0.06);

  // Home connect button — light mode uses a dedicated pair of palettes;
  // dark mode keeps the existing primary-gradient / inactive-slate look.

  /// Disconnected (VPN off)
  Color get connectButtonDisconnectedOuter => brightness == Brightness.dark
      ? shadowLight
      : const Color(0xFFFFFFFF);

  Color get connectButtonDisconnectedBorder => brightness == Brightness.dark
      ? borderLight
      : const Color(0xFFE2E8F0);

  Color get connectButtonDisconnectedFill => brightness == Brightness.dark
      ? inactiveColor
      : const Color(0xFFF1F5F9);

  Color get connectButtonDisconnectedIcon => brightness == Brightness.dark
      ? onSurface.withOpacity(0.70)
      : const Color(0xFF94A3B8);

  /// Connected (VPN on)
  Color get connectButtonConnectedOuter => brightness == Brightness.dark
      ? primary.withOpacity(0.1)
      : const Color(0xFFECFDF5);

  Color get connectButtonConnectedBorder => brightness == Brightness.dark
      ? primary
      : const Color(0xFF14B8A6);

  Color get connectButtonConnectedGlow => brightness == Brightness.dark
      ? primary.withOpacity(0.4)
      : const Color(0xFF14B8A6).withOpacity(0.22);

  Color get connectButtonConnectedFillStart => brightness == Brightness.dark
      ? primary
      : const Color(0xFF5EEAD4);

  Color get connectButtonConnectedFillEnd => brightness == Brightness.dark
      ? secondary
      : const Color(0xFF0D9488);

  Color get connectButtonConnectedIcon => brightness == Brightness.dark
      ? onPrimary
      : Colors.white;

  Color get connectButtonConnectedInnerShadow => brightness == Brightness.dark
      ? shadowDark
      : const Color(0xFF0D9488).withOpacity(0.18);
}

ThemeData lightTheme(Locale? locale) =>
    _buildTheme(_lightColorScheme, locale, isDark: false);

ThemeData darkTheme(Locale? locale) =>
    _buildTheme(_darkColorScheme, locale, isDark: true);

final _lightColorScheme = ColorScheme.light(
  primary: const Color(0xFF00A896),
  secondary: const Color(0xFF00BFA6),
  tertiary: const Color(0xFFE2E8F0),
  surface: const Color(0xFFF1F5F9),
  background: const Color(0xFFF8FAFC),
  error: Colors.red,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onTertiary: const Color(0xFF0F172A),
  onSurface: const Color(0xFF0F172A),
  onBackground: const Color(0xFF0F172A),
  onError: Colors.white,
  secondaryContainer: const Color(0xFFD1FAF5),
  onSecondaryContainer: const Color(0xFF006B5E),
);

final _darkColorScheme = ColorScheme.dark(
  primary: const Color(0xFF00FFCB),
  secondary: const Color(0xFF00BFA6),
  tertiary: const Color(0xFF1E293B),
  surface: const Color(0xFF1E293B),
  background: const Color(0xFF0F172A),
  error: Colors.red,
  onPrimary: Colors.black87,
  onSecondary: Colors.white,
  onTertiary: Colors.white,
  onSurface: Colors.white,
  onBackground: Colors.white,
  onError: Colors.white,
  secondaryContainer: const Color(0xFF1E3A3A),
  onSecondaryContainer: const Color(0xFF00FFCB),
);

ThemeData _buildTheme(
  ColorScheme colorScheme,
  Locale? locale, {
  required bool isDark,
}) {
  final textTheme = getTextTheme(locale, isDark: isDark);
  final onSurface = colorScheme.onSurface;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme ??
        (isDark ? ThemeData.dark() : ThemeData.light()).textTheme.copyWith(
              bodyLarge: TextStyle(color: onSurface),
              bodyMedium: TextStyle(color: onSurface),
              bodySmall: TextStyle(color: onSurface.withOpacity(0.87)),
              titleLarge: TextStyle(color: onSurface),
              titleMedium: TextStyle(color: onSurface),
              titleSmall: TextStyle(color: onSurface),
            ),
    scaffoldBackgroundColor: colorScheme.bgColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: onSurface.withOpacity(0.87)),
      titleTextStyle: TextStyle(
        color: onSurface,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceOverlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: colorScheme.surfaceOverlay,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.borderMedium,
      thickness: 1,
    ),
  );
}
