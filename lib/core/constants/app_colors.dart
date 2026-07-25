// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// Bistro Go Design System — Culinary Minimalist palette
/// Primary: #E8622C (Terracotta)
/// Background: #F4F1EC (Warm Cream)
/// On-Surface: #1B2A4A (Deep Navy)
abstract class AppColors {
  // Primary — Terracotta
  static const Color primary = Color(0xFFE8622C);
  static const Color primaryDark = Color(0xFFC94C16);
  static const Color primaryLight = Color(0xFFFFB59B);
  static const Color primaryFixed = Color(0xFFFFDBCF);

  // Background / Surface
  static const Color background = Color(0xFFF4F1EC);
  static const Color surface = Color(0xFFFBF9F9);
  static const Color surfaceContainer = Color(0xFFEFEDED);
  static const Color surfaceContainerLow = Color(0xFFF5F3F3);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E7);
  static const Color surfaceContainerHighest = Color(0xFFE4E2E2);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFDBDAD9);

  // On-Surface — Deep Navy
  static const Color onSurface = Color(0xFF1B2A4A);
  static const Color onSurfaceVariant = Color(0xFF594139);
  static const Color inverseOnSurface = Color(0xFFF2F0F0);
  static const Color inverseSurface = Color(0xFF303031);

  // Outline
  static const Color outline = Color(0xFF8C7168);
  static const Color outlineVariant = Color(0xFFE0BFB5);

  // Secondary
  static const Color secondary = Color(0xFF5F5E5B);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE5E2DD);

  // Tertiary (Navy accent)
  static const Color tertiary = Color(0xFF4D5B7E);
  static const Color onTertiary = Color(0xFFFFFFFF);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Success (Muted Sage)
  static const Color success = Color(0xFF4A7C59);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFCCEBD6);

  // Semantic helpers
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Card shadow color
  static const Color shadowColor = Color(0xFF1B2A4A);

  // Order status colors
  static const Color statusPlaced = Color(0xFF4D5B7E);
  static const Color statusConfirmed = Color(0xFFE8622C);
  static const Color statusPreparing = Color(0xFFCA8A04);
  static const Color statusReady = Color(0xFF4A7C59);
  static const Color statusCompleted = Color(0xFF4A7C59);
  static const Color statusCancelled = Color(0xFFBA1A1A);

  // Inverse primary (used by ColorScheme)
  static const Color inversePrimary = Color(0xFFFFB59B);
}
