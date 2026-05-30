import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/form_theme.dart';
import 'core/theme/form_colors.dart';
import 'core/theme/form_typography.dart';

class FormApp extends ConsumerWidget {
  const FormApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.isConfigured) {
      return MaterialApp(
        title: 'FORM',
        debugShowCheckedModeBanner: false,
        theme: FormTheme.dark(),
        darkTheme: FormTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const _MisconfiguredScreen(),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FORM',
      debugShowCheckedModeBanner: false,
      theme: FormTheme.dark(),
      darkTheme: FormTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}

/// Shown when the app is launched without Supabase credentials. Surfaces the
/// exact `--dart-define` flags rather than failing silently.
class _MisconfiguredScreen extends StatelessWidget {
  const _MisconfiguredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.settings_suggest_outlined,
                  color: FormColors.warning,
                  size: 48,
                ),
                const SizedBox(height: 20),
                Text(
                  'Supabase not configured',
                  textAlign: TextAlign.center,
                  style: FormTypography.prose(
                    size: 20,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Launch with:\n'
                  '--dart-define=SUPABASE_URL=…\n'
                  '--dart-define=SUPABASE_PUBLISHABLE_KEY=…',
                  textAlign: TextAlign.center,
                  style: FormTypography.data(
                    size: 13,
                    color: FormColors.onSurfaceMuted,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
