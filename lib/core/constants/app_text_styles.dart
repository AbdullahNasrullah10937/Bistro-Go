// lib/core/constants/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Bistro Go Typography Scale — loaded via google_fonts at runtime
/// Headlines: Sora (geometric sans, tight tracking)
/// Body & UI: Manrope (functional sans, high legibility)
abstract class AppTextStyles {
  // ── Headline Scale (Sora) ─────────────────────────────────────────────────
  static final TextStyle headlineXl = GoogleFonts.sora(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.8,
    color: AppColors.onSurface,
  );

  static final TextStyle headlineLg = GoogleFonts.sora(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.32,
    color: AppColors.onSurface,
  );

  static final TextStyle headlineLgMobile = GoogleFonts.sora(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.214,
    color: AppColors.onSurface,
  );

  static final TextStyle headlineMd = GoogleFonts.sora(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.333,
    color: AppColors.onSurface,
  );

  static final TextStyle headlineSm = GoogleFonts.sora(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.onSurface,
  );

  // ── Body Scale (Manrope) ──────────────────────────────────────────────────
  static final TextStyle bodyLg = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.556,
    color: AppColors.onSurface,
  );

  static final TextStyle bodyMd = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static final TextStyle bodySm = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.429,
    color: AppColors.onSurface,
  );

  // ── Label Scale (Manrope) ─────────────────────────────────────────────────
  static final TextStyle labelMd = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.429,
    letterSpacing: 0.7,
    color: AppColors.onSurface,
  );

  static final TextStyle labelSm = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.333,
    color: AppColors.onSurface,
  );

  static final TextStyle labelXs = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.273,
    color: AppColors.onSurfaceVariant,
  );

  // ── Price ─────────────────────────────────────────────────────────────────
  static final TextStyle price = GoogleFonts.sora(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
  );

  static final TextStyle priceLg = GoogleFonts.sora(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
  );
}
