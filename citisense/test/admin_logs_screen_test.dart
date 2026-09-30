import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citisense/screens/admin/admin_logs_screen.dart';
import 'package:citisense/services/mock_repository.dart';
import 'package:citisense/state/app_state.dart';

void main() {
  Future<AppState> seed(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState(repository: MockRepository());
    await tester.runAsync(() => appState.refresh());
    return appState;
  }

  Widget wrap(AppState appState) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: const MaterialApp(home: AdminLogsScreen()),
    );
  }

  testWidgets('logs are grouped by category with headers and counts',
      (WidgetTester tester) async {
    final appState = await seed(tester);
    await tester.pumpWidget(wrap(appState));
    await tester.pumpAndSettle();

    expect(find.text('Audit Logs'), findsOneWidget);

    for (final chip in ['All', 'Logins', 'Logouts', 'Signups', 'Reports']) {
      expect(find.text(chip), findsWidgets, reason: 'chip "$chip" missing');
    }

    expect(find.text('System'), findsWidgets);
    expect(find.text('Logins'), findsWidgets);
    expect(find.text('Reports'), findsWidgets);
  });

  testWidgets('filtering by a group shows only that group', (
      WidgetTester tester) async {
    final appState = await seed(tester);
    await tester.pumpWidget(wrap(appState));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Logins'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Complaint Filed'), findsNothing);
    expect(find.text('System Init'), findsNothing);
  });

  testWidgets('sort toggle flips between newest and oldest first',
      (WidgetTester tester) async {
    final appState = await seed(tester);
    await tester.pumpWidget(wrap(appState));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_downward));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });
}