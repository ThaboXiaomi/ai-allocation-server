import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lecture_room_allocator/main.dart';

void main() {
  testWidgets('FirebaseErrorScreen renders error details', (WidgetTester tester) async {
    const message = 'network init failed';

    await tester.pumpWidget(const FirebaseErrorScreen(error: message));

    expect(find.textContaining('Application Error'), findsOneWidget);
    expect(find.textContaining(message), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('FirebaseErrorScreen uses red text for failure message', (WidgetTester tester) async {
    await tester.pumpWidget(const FirebaseErrorScreen(error: 'any'));

    final textWidget = tester.widget<Text>(find.textContaining('Application Error'));
    expect(textWidget.style?.color, Colors.red);
  });
}
