import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citisense/screens/admin/admin_logs_screen.dart';
import 'package:citisense/services/mock_repository.dart';
import 'package:citisense/state/app_state.dart';

final _stampFormat = DateFormat('MMM d, h:mm a');

List<DateTime> _visibleTimestamps(WidgetTester tester) {
  final located = <(double, DateTime)>[];
  for (final element in find.byType(Text).evaluate()) {
    final data = (element.widget as Text).data;
    if (data == null) continue;
    DateTime? parsed;
    try {
      parsed = _stampFormat.parse(data);
    } catch (_) {
      continue;
    }
    final box = element.renderObject! as RenderBox;
    located.add((box.localToGlobal(Offset.zero).dy, parsed));
  }
  located.sort((a, b) => a.$1.compareTo(b.$1));
  return located.map((e) => e.$2).toList();
}

void main() {
  Future<AppState> seed(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState(repository: MockRepository());
    await tester.runAsync(
      () => appState.login('admin@citisense.com', 'password'),
    );
    return appState;
  }

  Widget wrap(AppState appState) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: const MaterialApp(home: AdminLogsScreen()),
    );
  }

  testWidgets('the All view lists every log in date order without group headers',
      (WidgetTester tester) async {
    final appState = await seed(tester);
    await tester.pumpWidget(wrap(appState));
    await tester.pumpAndSettle();

    expect(find.text('Audit Logs'), findsOneWidget);

    for (final chip in ['All', 'Logins', 'Logouts', 'Signups', 'Reports']) {
      expect(find.text(chip), findsWidgets, reason: 'chip "$chip" missing');
    }

    final stamps = _visibleTimestamps(tester);
    expect(stamps.length, greaterThan(1));
    for (var i = 1; i < stamps.length; i++) {
      expect(
        stamps[i].isAfter(stamps[i - 1]),
        isFalse,
        reason: 'log ${stamps[i]} is older than the log above it ${stamps[i - 1]}',
      );
    }
  });

  testWidgets('filtering by a group shows only that group', (
      WidgetTester tester) async {
    final appState = await seed(tester);
    await tester.pumpWidget(wrap(appState));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Logins'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
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