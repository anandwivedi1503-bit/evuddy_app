import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:evuddy_app/main.dart';

void main() {
  testWidgets('splash shows EVUDDY wordmark', (WidgetTester tester) async {
    await tester.pumpWidget(const EvuddyApp());
    expect(find.text('EVUDDY'), findsOneWidget);
    expect(find.text('Move\nelectric.'), findsOneWidget);
  });
}
