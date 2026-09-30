import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citisense/app.dart';
import 'package:citisense/services/mock_repository.dart';

class _ThrowingSignOutRepository extends MockRepository {
  @override
  Future<void> signOut() async => throw Exception('signOut failed');
}

void main() {
  testWidgets(
      'logout returns to login even when repository.signOut throws',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(App(repository: _ThrowingSignOutRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Email address').first,
        'citizen@citisense.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password').first, 'password');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}