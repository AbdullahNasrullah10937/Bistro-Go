// lib/core/constants/app_radius.dart
import 'package:flutter/material.dart';

/// Bistro Go Shape Language — "Friendly Geometry"
/// Large: 16px  |  Medium: 14px  |  Small: 8px  |  Chip: full pill
abstract class AppRadius {
  /// Cards, bottom sheets, modals
  static const double card = 16.0;
  static final BorderRadius cardRadius = BorderRadius.circular(card);

  /// Buttons, inputs, dialogs
  static const double button = 14.0;
  static final BorderRadius buttonRadius = BorderRadius.circular(button);

  /// Image thumbnails, avatars
  static const double image = 12.0;
  static final BorderRadius imageRadius = BorderRadius.circular(image);

  /// Small containers
  static const double sm = 8.0;
  static final BorderRadius smRadius = BorderRadius.circular(sm);

  /// Chips, badges, tags — full pill
  static const double chip = 100.0;
  static final BorderRadius chipRadius = BorderRadius.circular(chip);

  /// Rounded bottom-sheet top corners only
  static final BorderRadius bottomSheet = const BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
  );
}
