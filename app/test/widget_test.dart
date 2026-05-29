import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:form/app.dart';
import 'package:form/core/theme/form_colors.dart';

void main() {
  testWidgets('placeholder home renders FORM wordmark in primary colour',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FormApp()));
    await tester.pump();

    final wordmark = find.text('FORM');
    expect(wordmark, findsOneWidget);

    final textWidget = tester.widget<Text>(wordmark);
    expect(textWidget.style?.color, FormColors.primary);
  });
}
