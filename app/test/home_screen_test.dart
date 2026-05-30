import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:form/core/auth/supabase_service.dart';
import 'package:form/features/auth/data/account_repository.dart';
import 'package:form/features/home/presentation/home_screen.dart';

Future<void> _pump(WidgetTester tester, {required List<Override> overrides}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
}

void main() {
  testWidgets('shows the signed-in email and a sign-out button', (
    tester,
  ) async {
    await _pump(
      tester,
      overrides: [
        currentEmailProvider.overrideWithValue('you@example.com'),
        provisionAccountProvider.overrideWith((ref) async => {'profile': null}),
      ],
    );
    await tester.pump(); // let the FutureProvider resolve

    expect(find.text('Signed in as'), findsOneWidget);
    expect(find.text('you@example.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('loading state shows the syncing badge', (tester) async {
    final completer = Completer<Map<String, dynamic>>();
    await _pump(
      tester,
      overrides: [
        currentEmailProvider.overrideWithValue('you@example.com'),
        provisionAccountProvider.overrideWith((ref) => completer.future),
      ],
    );
    await tester.pump();

    expect(find.text('syncing account…'), findsOneWidget);
    completer.complete({'profile': null});
  });

  testWidgets('account synced badge after POST /me succeeds', (tester) async {
    await _pump(
      tester,
      overrides: [
        currentEmailProvider.overrideWithValue('you@example.com'),
        provisionAccountProvider.overrideWith((ref) async => {'profile': null}),
      ],
    );
    await tester.pump();

    expect(find.text('account synced'), findsOneWidget);
  });

  testWidgets('backend unreachable badge when POST /me fails', (tester) async {
    await _pump(
      tester,
      overrides: [
        currentEmailProvider.overrideWithValue('you@example.com'),
        provisionAccountProvider.overrideWith(
          (ref) async => throw Exception('boom'),
        ),
      ],
    );
    await tester.pump();

    expect(find.text('backend unreachable'), findsOneWidget);
  });
}
