import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citisense/app.dart';
import 'package:citisense/models/app_user.dart';
import 'package:citisense/models/user_role.dart';
import 'package:citisense/services/mock_repository.dart';

AppUser _citizen() => AppUser(
      id: 'u1',
      fullName: 'Juan Dela Cruz',
      email: 'citizen@citisense.com',
      password: 'password',
      role: UserRole.citizen,
      createdAt: DateTime(2026, 1, 5),
    );

void main() {
  testWidgets('fresh session (recent savedAt) restores to the shell',
      (WidgetTester tester) async {
    final user = _citizen();
    final data = user.toMap()..['password'] = '';
    SharedPreferences.setMockInitialValues({
      'session.user': jsonEncode(data),
      'session.saved_at':
          DateTime.now().millisecondsSinceEpoch - Duration(minutes: 30).inMilliseconds,
    });
    await tester.pumpWidget(App(repository: MockRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('stale session (older than 2h) is dropped, lands on login',
      (WidgetTester tester) async {
    final user = _citizen();
    final data = user.toMap()..['password'] = '';
    SharedPreferences.setMockInitialValues({
      'session.user': jsonEncode(data),
      'session.saved_at':
          DateTime.now().millisecondsSinceEpoch - Duration(hours: 30).inMilliseconds,
    });
    await tester.pumpWidget(App(repository: MockRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('session without saved_at is treated as expired',
      (WidgetTester tester) async {
    final user = _citizen();
    final data = user.toMap()..['password'] = '';
    SharedPreferences.setMockInitialValues({
      'session.user': jsonEncode(data),
    });
    await tester.pumpWidget(App(repository: MockRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
  });
}