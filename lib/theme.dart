import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 
class AppColors {
  AppColors._();
 
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF262626);
  static const Color outline = Color(0xFF40343D);
 
  static const Color accentPink = Color(0xFFFF2D95);
  static const Color accentPurple = Color(0xFFB026FF);
  static const Color accentRed = Color(0xFFC0392B);
 
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9E9E9E);
 
  static const Color chromeStart = Color(0xFF8E8E8E);
  static const Color chromeEnd = Color(0xFF3A3A3A);
 
  /// Gradient chrome dùng cho nút bấm / viền nổi bật
  static const LinearGradient chromeGradient = LinearGradient(
    colors: [chromeStart, Color(0xFFEDEDED), chromeEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
 
  static const LinearGradient neonGradient = LinearGradient(
    colors: [accentPink, accentPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
 
class AppTheme {
  AppTheme._();
 
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
 
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accentPink,
        secondary: AppColors.accentPurple,
        surface: AppColors.surface,
        error: AppColors.accentRed,
      ),
 
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.pressStart2p(
          color: AppColors.textPrimary,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.accentPink),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AppColors.accentPink, width: 2),
        ),
      ),
 
      textTheme: base.textTheme.copyWith(
  
        headlineLarge: GoogleFonts.pressStart2p(
          color: AppColors.textPrimary,
          fontSize: 20,
        ),

        headlineMedium: GoogleFonts.vt323(
          color: AppColors.textPrimary,
          fontSize: 30,
        ),

        titleMedium: GoogleFonts.vt323(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 19,
        ),
        bodyLarge: GoogleFonts.chakraPetch(color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.chakraPetch(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        labelLarge: GoogleFonts.vt323(
          color: AppColors.accentPink,
          fontWeight: FontWeight.bold,
          fontSize: 19,
          letterSpacing: 0.5,
        ),
      ),
 
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.chakraPetch(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.chakraPetch(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.accentPink, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.accentRed),
        ),
      ),
 
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accentPink,
        selectionColor: AppColors.accentPurple,
        selectionHandleColor: AppColors.accentPink,
      ),
 
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceLight,
          foregroundColor: AppColors.accentPink,
          side: const BorderSide(color: AppColors.accentPink, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold),
        ),
      ),
 
      iconTheme: const IconThemeData(color: AppColors.accentPink),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: GoogleFonts.chakraPetch(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AppColors.accentPurple),
        ),
      ),
 
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentPink,
      ),
    );
  }
}
