import 'package:flutter/material.dart';
import '../../../core/theme/form_colors.dart';
import '../../../core/theme/form_typography.dart';

/// Phase 0 placeholder. Replaced in Phase 3 by the real Home tab.
/// Exists so we can confirm the theme + fonts render on a real device.
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FORM',
                style: FormTypography.data(
                  size: 96,
                  weight: FontWeight.w700,
                  color: FormColors.primary,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'adaptive fitness companion',
                style: FormTypography.prose(
                  size: 14,
                  color: FormColors.onSurfaceMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: FormColors.border),
                  color: FormColors.surface,
                ),
                child: Text(
                  'phase 0 · skeleton',
                  style: FormTypography.data(
                    size: 11,
                    weight: FontWeight.w600,
                    color: FormColors.secondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
