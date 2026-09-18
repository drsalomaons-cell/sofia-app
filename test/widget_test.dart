import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia/core/main.dart';

void main() {
  testWidgets('SOFIA app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SofiaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}