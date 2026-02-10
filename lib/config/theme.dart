import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    cardColor: const Color(0xFF161B22),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF58A6FF),
      secondary: Color(0xFF50C878),
      error: Color(0xFFE5534B),
      surface: Color(0xFF161B22),
      onSurface: Color(0xFFC9D1D9),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardThemeData(
      color: const Color(0xFF161B22),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D), width: 1),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF161B22),
      indicatorColor: Color(0xFF1F2937),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D1117),
      elevation: 0,
    ),
  );

  // Version-specific colors
  static const versionColors = {
    'v5.4.2': Color(0xFF4A90D9), // blue
    'v5.4.3': Color(0xFFE8833A), // orange
    'v5.4.4': Color(0xFF50C878), // green
  };

  // PnL colors
  static const profit = Color(0xFF50C878);
  static const loss = Color(0xFFE5534B);
  static const neutral = Color(0xFF8B949E);

  // Zone colors
  static const zoneColors = [
    Color(0xFF00E676), // Strong Bull
    Color(0xFF66BB6A), // Moderate Bull
    Color(0xFFA5D6A7), // Bull Full
    Color(0xFFFFD54F), // Bull Half
    Color(0xFFFF9800), // Iron Condor
    Color(0xFFEF5350), // No Trade
  ];

  static Color pnlColor(double? value) {
    if (value == null || value == 0) return neutral;
    return value > 0 ? profit : loss;
  }

  static Color versionColor(String version) {
    return versionColors[version] ?? const Color(0xFF8B949E);
  }
}
