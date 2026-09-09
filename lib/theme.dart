import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 
/// Bảng màu chủ đạo Emo x Y2K
/// - Nền tối, accent neon, chi tiết chrome/metallic
class AppColors {
  AppColors._();
 
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF262626);
 
  static const Color accentPink = Color(0xFFFF2D95);
  static const Color accentPurple = Color(0xFFB026FF);
  static const Color accentRed = Color(0xFFC0392B); // dùng cho giá quốc tế/cảnh báo
 
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
 
  /// Gradient neon dùng cho CTA chính (nút mua, giá)
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
 
      // AppBar tối, chữ heading font gothic
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.metalMania(
          color: AppColors.textPrimary,
          fontSize: 22,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.accentPink),
      ),
 
      // Card sản phẩm: nền surface, viền mảnh, bo góc nhẹ kiểu "sticker rách"
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 6,
        shadowColor: AppColors.accentPurple.withOpacity(0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.accentPink.withOpacity(0.25)),
        ),
      ),
 
      // Typography: heading dùng Metal Mania, body dùng Chakra Petch
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.metalMania(
          color: AppColors.textPrimary,
          fontSize: 32,
        ),
        headlineMedium: GoogleFonts.metalMania(
          color: AppColors.textPrimary,
          fontSize: 24,
        ),
        titleMedium: GoogleFonts.chakraPetch(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.chakraPetch(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        labelLarge: GoogleFonts.chakraPetch(
          color: AppColors.accentPink,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
 
      // Nút bấm: viền neon glow, nền surface
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceLight,
          foregroundColor: AppColors.accentPink,
          side: const BorderSide(color: AppColors.accentPink, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.accentPurple),
        ),
      ),
 
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentPink,
      ),
    );
  }
}