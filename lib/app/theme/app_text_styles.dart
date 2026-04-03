import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sosigi/app/theme/app_colors.dart';

class AppTextStyles {
  static TextStyle get brand => GoogleFonts.notoSansKr(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: AppColors.primaryText,
      );

  static TextStyle get pageTitle => GoogleFonts.notoSansKr(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppColors.primaryText,
      );

  static TextStyle get sectionTitle => GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: AppColors.primaryText,
      );

  static TextStyle get sectionBody => GoogleFonts.notoSansKr(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryText,
        height: 1.4,
      );

  static TextStyle get cardTitle => GoogleFonts.notoSansKr(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: AppColors.primaryText,
        height: 1.35,
      );

  static TextStyle get body => GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      );

  static TextStyle get caption => GoogleFonts.notoSansKr(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryText,
      );

  static TextStyle get chip => GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w900,
      );

  static TextStyle get button => GoogleFonts.notoSansKr(
        fontSize: 15,
        fontWeight: FontWeight.w900,
      );

  static TextStyle get largeEmptyTitle => GoogleFonts.notoSansKr(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.primaryText,
        height: 1.35,
      );

  static TextStyle get largeEmptyBody => GoogleFonts.notoSansKr(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryText,
        height: 1.7,
      );
}