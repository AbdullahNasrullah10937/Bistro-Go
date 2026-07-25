// lib/core/constants/app_shadows.dart
import 'package:flutter/material.dart';

/// Bistro Go Elevation System — Tonal Layers with Soft Shadows
/// Level 1: Y:4, Blur:12, Opacity:5%, Color:#1B2A4A
abstract class AppShadows {
  /// Level 1 — Cards, containers
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D1B2A4A), // #1B2A4A at 5%
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Level 2 — Modals, bottom sheets (slightly more depth)
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x1A1B2A4A), // #1B2A4A at 10%
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  /// Sticky elements (cart bar, FAB)
  static const List<BoxShadow> sticky = [
    BoxShadow(
      color: Color(0x261B2A4A), // #1B2A4A at 15%
      blurRadius: 20,
      offset: Offset(0, -4),
      spreadRadius: 0,
    ),
  ];

  /// Buttons
  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x33E8622C), // primary at 20%
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
}
