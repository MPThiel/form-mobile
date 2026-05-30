import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../auth/supabase_service.dart';

abstract final class Routes {
  static const signIn = '/sign-in';
  static const home = '/home';
}

/// Bridges the Supabase auth stream to go_router's `refreshListenable`, so the
/// router re-evaluates `redirect` the moment the session appears (magic-link
/// deep link completes) or disappears (sign-out).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<AuthState> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  final refresh = _AuthRefreshNotifier(supabase.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = supabase.currentSession != null;
      final atSignIn = state.matchedLocation == Routes.signIn;

      if (!signedIn) return atSignIn ? null : Routes.signIn;
      if (atSignIn) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
    ],
  );
});
