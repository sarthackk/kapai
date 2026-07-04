import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.sairaSemiCondensed(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.sairaSemiCondensed(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
        height: 1.15,
      );

  static TextStyle get displaySmall => GoogleFonts.sairaSemiCondensed(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
        height: 1.2,
      );

  static TextStyle get titleLarge => GoogleFonts.sairaSemiCondensed(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
        height: 1.3,
      );

  static TextStyle get titleMedium => GoogleFonts.sairaSemiCondensed(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
        height: 1.3,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.charcoal,
        height: 1.5,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.charcoal,
        height: 1.5,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMid,
        height: 1.5,
      );

  static TextStyle get labelLarge => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMid,
        letterSpacing: 0.3,
      );
}
