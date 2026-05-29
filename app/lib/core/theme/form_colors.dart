import 'package:flutter/material.dart';

/// FORM colour tokens. Mirrors the palette in CLAUDE.md and DESIGN.md.
/// Never hardcode hex values in widgets — reference these constants.
abstract final class FormColors {
  static const bg = Color(0xFF131313);
  static const surface = Color(0xFF1C1B1B);
  static const surfaceHigh = Color(0xFF2A2A2A);
  static const border = Color(0xFF353534);

  static const primary = Color(0xFFFF6B00); // electric orange
  static const secondary = Color(0xFF00EEFC); // cyber cyan

  static const onSurface = Color(0xFFE5E2E1);
  static const onSurfaceVariant = Color(0xFFE2BFB0);
  static const onSurfaceMuted = Color(0xFF8A8786);

  static const success = Color(0xFF52E89A);
  static const warning = Color(0xFFFFD166);
  static const danger = Color(0xFFF87171);

  // Macro colour coding — keep consistent across the app.
  static const macroCalories = primary; // orange
  static const macroProtein = secondary; // cyan
  static const macroCarbs = warning; // yellow
  static const macroFat = success; // green
}
