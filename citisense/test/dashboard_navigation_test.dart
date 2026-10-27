import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citisense/core/date_preset.dart';
import 'package:citisense/models/complaint.dart';
import 'package:citisense/models/enums.dart';
import 'package:citisense/screens/officer/officer_shell.dart';
import 'package:citisense/services/mock_repository.dart';
import 'package:citisense/state/app_state.dart';

Complaint _complaint({
  ComplaintCategory category = ComplaintCategory.electricalHazard,
  ComplaintStatus status = ComplaintStatus.pending,
  DateTime? createdAt,
}) {
  return Complaint(
    id: 'c1',
    citizenId: 'u1',
    citizenName: 'Juan Dela Cruz',
    category: category,
    description: 'Exposed electrical wire near the barangay hall.',
    sentiment: Sentiment.negative,
    recommendation: 'Send a certified electrician.',
    status: status,
    createdAt: createdAt ?? DateTime.now(),
  );
}

void main() {
  test('date presets only match dates inside their window', () {
    final now = DateTime.now();
    expect(DatePreset.allTime.matches(DateTime(2020)), isTrue);
    expect(DatePreset.today.matches(now), isTrue);
    expect(
      DatePreset.today.matches(now.subtract(const Duration(days: 2))),
      isFalse,
    );
    expect(
      DatePreset.last7Days.matches(now.subtract(const Duration(days: 3))),
      isTrue,
    );
    expect(
      DatePreset.last7Days.matches(now.subtract(const Duration(days: 10))),
      isFalse,
    );
    expect(
      DatePreset.last30Days.matches(now.subtract(const Duration(days: 20))),
      isTrue,
    );
    expect(
      DatePreset.last30Days.matches(now.subtract(const Duration(days: 40))),
      isFalse,
    );
  });

  test('high-risk open complaints need attention until resolved', () {
    final highRisk = _complaint();
    expect(highRisk.needsAttention, isTrue);
    expect(
      highRisk.copyWith(status: ComplaintStatus.resolved).needsAttention,
      isFalse,
    );
  });

  test('old open complaints need attention even in low-risk categories', () {
    final stale = _complaint(
      category: ComplaintCategory.waste,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    );
    final fresh = _complaint(category: ComplaintCategory.waste);
    expect(stale.needsAttention, isTrue);
    expect(fresh.needsAttention, isFalse);
  });

  testWidgets('officer dashboard stat cards open the filtered complaints view',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState(repository: MockRepository());
    await tester.runAsync(
      () => appState.login('officer@citisense.com', 'password'),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: OfficerShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total reports'), findsOneWidget);
    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();

    expect(find.text('Any category'), findsOneWidget);
    expect(find.text('${appState.pendingCount} shown'), findsOneWidget);
  });
}
