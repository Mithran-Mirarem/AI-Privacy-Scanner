import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_privacy_scanner_review2/main.dart';

void main() {
  testWidgets('AI Privacy Scanner app creates its root widget',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AiPrivacyScannerApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
