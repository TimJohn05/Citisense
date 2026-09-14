import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citisense/app.dart';
import 'package:citisense/services/mock_repository.dart';

void main() {
  Future<void> loginAsCitizen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(App(repository: MockRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Email address').first,
        'citizen@citisense.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password').first, 'password');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }

  testWidgets('citizen can submit a report and see the result screen',
      (WidgetTester tester) async {
    await loginAsCitizen(tester);
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Report an issue'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Sobrang baho ng basura sa may kalsada, ang dami na!');
    await tester.dragUntilVisible(
      find.text('Analyze & Submit Report'),
      find.byType(ListView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analyze & Submit Report'));
    await tester.pumpAndSettle();

    expect(find.text('Report Submitted'), findsOneWidget);
    expect(find.text('Report received'), findsOneWidget);

    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}