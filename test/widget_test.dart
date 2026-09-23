import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:evuddy_app/main.dart';

void main() {
  testWidgets('splash shows brand logo', (WidgetTester tester) async {
    await tester.pumpWidget(const EvuddyApp());
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    expect(find.text('23 Sep 2026 · Home v7'), findsNothing);
    expect(find.text('Smart electric mobility'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1600));
  });
}
