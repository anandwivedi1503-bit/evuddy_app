import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:evuddy_app/main.dart';

void main() {
  testWidgets('splash shows brand logo', (WidgetTester tester) async {
    await tester.pumpWidget(const EvuddyApp());
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Smart electric mobility'), findsOneWidget);
    expect(find.text('23 Sep 2026 · Catalog v6'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2400));
  });
}
