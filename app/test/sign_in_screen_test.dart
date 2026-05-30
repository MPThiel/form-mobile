import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:form/features/auth/presentation/sign_in_screen.dart';
import 'package:form/features/auth/providers.dart';

/// AuthController stub that builds to a fixed state, so we can render each UI
/// state without touching Supabase.
class _StateController extends AuthController {
  _StateController(this._initial);
  final AuthFlowState _initial;
  @override
  AuthFlowState build() => _initial;
}

Future<void> _pump(WidgetTester tester, {List<Override> overrides = const []}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: SignInScreen()),
    ),
  );
}

void main() {
  testWidgets(
    'empty state renders wordmark, email field and magic-link button',
    (tester) async {
      await _pump(tester);

      expect(find.text('FORM'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Send magic link'), findsOneWidget);

      // Google is a disabled placeholder; Apple is intentionally absent.
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.textContaining('Apple'), findsNothing);
    },
  );

  testWidgets('loading state shows a spinner and no button label', (
    tester,
  ) async {
    await _pump(
      tester,
      overrides: [
        authControllerProvider.overrideWith(
          () => _StateController(const AuthSendingLink()),
        ),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Send magic link'), findsNothing);
  });

  testWidgets('link-sent state shows the check-inbox confirmation', (
    tester,
  ) async {
    await _pump(
      tester,
      overrides: [
        authControllerProvider.overrideWith(
          () => _StateController(const AuthLinkSent('you@example.com')),
        ),
      ],
    );

    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.textContaining('you@example.com'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}
