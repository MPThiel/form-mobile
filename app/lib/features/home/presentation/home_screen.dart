import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/supabase_service.dart';
import '../../../core/theme/form_colors.dart';
import '../../../core/theme/form_typography.dart';
import '../../auth/data/account_repository.dart';
import '../../auth/providers.dart';

/// Phase 1 placeholder Home. Confirms the signed-in state end-to-end:
/// shows the email from the Supabase session, provisions the backend account
/// via `POST /me`, and offers sign-out. Replaced by the real Home tab in Phase 3.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(currentEmailProvider) ?? 'unknown';
    final account = ref.watch(provisionAccountProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'FORM',
                textAlign: TextAlign.center,
                style: FormTypography.data(
                  size: 56,
                  weight: FontWeight.w700,
                  color: FormColors.primary,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Signed in as',
                textAlign: TextAlign.center,
                style: FormTypography.prose(
                  size: 13,
                  color: FormColors.onSurfaceMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                textAlign: TextAlign.center,
                style: FormTypography.prose(size: 18, weight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Center(child: _AccountSyncBadge(account: account)),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: FormColors.border),
                  foregroundColor: FormColors.onSurface,
                ),
                child: Text(
                  'Sign out',
                  style: FormTypography.data(
                    size: 15,
                    weight: FontWeight.w600,
                    color: FormColors.onSurface,
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

/// Small status chip reflecting the `POST /me` provisioning call.
class _AccountSyncBadge extends StatelessWidget {
  const _AccountSyncBadge({required this.account});

  final AsyncValue<Map<String, dynamic>> account;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (account) {
      AsyncData() => ('account synced', FormColors.success),
      AsyncError() => ('backend unreachable', FormColors.warning),
      _ => ('syncing account…', FormColors.onSurfaceMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FormColors.border),
        color: FormColors.surface,
      ),
      child: Text(
        label,
        style: FormTypography.data(
          size: 11,
          weight: FontWeight.w600,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
