import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citisense/app.dart';
import 'package:citisense/services/mock_repository.dart';

void main() {
  testWidgets(
      'signup shows success indicator and returns to sign-in, no auto-login',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(App(repository: MockRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Full name'), 'Maria Santos');
    await tester.enterText(
        find.widgetWithText(TextField, 'Email address'), 'maria@santos.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password'), 'secret123');
    await tester.enterText(
        find.widgetWithText(TextField, 'Confirm password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();

    // Back on the sign-in screen, with a success indicator.
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Account created. Sign in to continue.'), findsOneWidget);

    // Not logged in: no citizen shell.
    expect(find.text('Welcome back'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });
}