import 'package:flutter_test/flutter_test.dart';

import 'package:citisense/models/complaint.dart';
import 'package:citisense/models/enums.dart';
import 'package:citisense/state/app_state.dart';
import 'package:citisense/services/mock_repository.dart';

void main() {
  testWidgets(
      'resolveComplaint throws ArgumentError when proof is empty',
      (WidgetTester tester) async {
    final appState = AppState(repository: MockRepository());
    final complaint = Complaint(
      id: 'c-test',
      citizenId: 'u1',
      citizenName: 'Test Citizen',
      category: ComplaintCategory.waste,
      description: 'Test complaint',
      sentiment: Sentiment.negative,
      recommendation: 'Test recommendation',
      status: ComplaintStatus.pending,
      latitude: 14.2,
      longitude: 121.15,
      createdAt: DateTime(2026, 7, 3, 9, 15),
    );

    // resolveComplaint should throw ArgumentError when proof is empty
    expect(
      () => appState.resolveComplaint(
        complaint,
        notes: 'Test resolution',
        proof: const [],
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
