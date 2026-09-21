import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:evuddy_app/main.dart';

void main() {
  testWidgets('splash shows EVUDDY welcome rule', (WidgetTester tester) async {
    await tester.pumpWidget(const EvuddyApp());
    expect(find.text('WELCOME TO EVUDDY'), findsOneWidget);
    expect(find.text('Electric mobility for India'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Confirm your\nmobile number'), findsOneWidget);
  });
}
