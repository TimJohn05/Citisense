import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:citisense/app.dart';
import 'package:citisense/services/mock_repository.dart';

void main() {
  testWidgets('login with demo citizen account', (WidgetTester tester) async {
    await tester.pumpWidget(App(repository: MockRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Email address').first,
        'citizen@citisense.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password').first, 'password');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('logout asks for confirmation and cancels safely',
      (WidgetTester tester) async {
    await tester.pumpWidget(App(repository: MockRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Email address').first,
        'citizen@citisense.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password').first, 'password');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
