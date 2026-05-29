import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'form_colors.dart';

/// FORM typography. Two families:
///  - Montserrat for prose / body / titles
///  - Space Grotesk for numeric data, labels, small caps elements
///
/// Build text styles via these helpers rather than calling `GoogleFonts.*`
/// directly in widgets so font choice can be swapped in one place.
abstract final class FormTypography {
  static TextStyle prose({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = FormColors.onSurface,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.montserrat(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle data({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color color = FormColors.onSurface,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextTheme textTheme() {
    return TextTheme(
      displayLarge: data(size: 64, weight: FontWeight.w600, letterSpacing: -1.0),
      displayMedium: data(size: 48, weight: FontWeight.w600, letterSpacing: -0.5),
      displaySmall: data(size: 36, weight: FontWeight.w600),
      headlineLarge: prose(size: 32, weight: FontWeight.w700),
      headlineMedium: prose(size: 28, weight: FontWeight.w700),
      headlineSmall: prose(size: 22, weight: FontWeight.w700),
      titleLarge: prose(size: 20, weight: FontWeight.w600),
      titleMedium: prose(size: 16, weight: FontWeight.w600),
      titleSmall: prose(size: 14, weight: FontWeight.w600),
      bodyLarge: prose(size: 16, height: 1.45),
      bodyMedium: prose(size: 14, height: 1.45),
      bodySmall: prose(size: 12, color: FormColors.onSurfaceMuted, height: 1.4),
      labelLarge: data(size: 14, weight: FontWeight.w600, letterSpacing: 0.8),
      labelMedium: data(size: 12, weight: FontWeight.w600, letterSpacing: 0.8),
      labelSmall: data(
        size: 10,
        weight: FontWeight.w600,
        letterSpacing: 1.2,
        color: FormColors.onSurfaceMuted,
      ),
    );
  }
}
