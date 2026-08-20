import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF6200EE),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      cardColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6200EE),
        primary: const Color(0xFF6200EE),
        secondary: const Color(0xFF03DAC6),
        tertiary: const Color(0xFFFF0266),
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme)
          .copyWith(
            displayLarge: GoogleFonts.cairo(
              textStyle: Theme.of(context).textTheme.displayLarge,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF311B92),
            ),
            displayMedium: GoogleFonts.cairo(
              textStyle: Theme.of(context).textTheme.displayMedium,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF311B92),
            ),
            titleLarge: GoogleFonts.cairo(
              textStyle: Theme.of(context).textTheme.titleLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFBB86FC),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFBB86FC),
        primary: const Color(0xFFBB86FC),
        secondary: const Color(0xFF03DAC6),
        tertiary: const Color(0xFFFF4081),
        surface: const Color(0xFF1E1E1E),
        brightness: Brightness.dark,
      ),
      textTheme:
          GoogleFonts.montserratTextTheme(
            Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ).copyWith(
            displayLarge: GoogleFonts.cairo(
              textStyle: Theme.of(context).textTheme.displayLarge,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFBB86FC),
            ),
            displayMedium: GoogleFonts.cairo(
              textStyle: Theme.of(context).textTheme.displayMedium,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFBB86FC),
            ),
            titleLarge: GoogleFonts.cairo(
              textStyle: Theme.of(context).textTheme.titleLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
    );
  }

  static Gradient primaryGradient(BuildContext context) {
    return const LinearGradient(
      colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Gradient accentGradient(BuildContext context) {
    return const LinearGradient(
      colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  static BoxDecoration glassDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    );
  }
}
