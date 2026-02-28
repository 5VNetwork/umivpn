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
  // Background color (very dark blue - app-specific, since background is deprecated)
  Color get bgColor => const Color(0xFF0F172A);
  
  // Secondary background color (slate)
  Color get bgSecondary => surface;

  // Inactive/secondary color (for inactive states - app-specific)
  Color get inactiveColor => const Color(0xFF334155);

  // Window button colors (for desktop - app-specific)
  Color get borderColor => const Color(0xFF805306);
  Color get sidebarColor => const Color(0xFFF6A00C);
  Color get backgroundStartColor => const Color(0xFFFFD500);
  Color get backgroundEndColor => const Color(0xFFF6A00C);

  // Surface overlays with opacity (for cards, containers)
  Color get surfaceOverlay => onSurface.withOpacity(0.05);
  Color get surfaceOverlayLight => onSurface.withOpacity(0.08);
  Color get surfaceOverlayLighter => onSurface.withOpacity(0.1);

  // Border colors (using onSurface opacity)
  Color get borderLight => onSurface.withOpacity(0.1);
  Color get borderMedium => onSurface.withOpacity(0.24);

  // Shadow colors
  Color get shadowDark => Colors.black.withOpacity(0.54);
  Color get shadowLight => Colors.black.withOpacity(0.26);
}

// Light theme - removed, always use dark theme
@Deprecated('Use darkTheme instead')
ThemeData lightTheme(Locale? locale) => darkTheme(locale);

// Dark theme
ThemeData darkTheme(Locale? locale) {
  final colorScheme = ColorScheme.dark(
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

  final textTheme = getTextTheme(locale, isDark: true);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme ??
        ThemeData.dark().textTheme.copyWith(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
              bodySmall: TextStyle(color: Colors.white.withOpacity(0.87)),
              titleLarge: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white),
              titleSmall: TextStyle(color: Colors.white),
            ),
    scaffoldBackgroundColor: colorScheme.bgColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: colorScheme.onSurface.withOpacity(0.87)),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
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
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 1,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
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
