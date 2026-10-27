import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citisense/models/app_user.dart';
import 'package:citisense/models/system_log.dart';
import 'package:citisense/services/mock_repository.dart';
import 'package:citisense/state/app_state.dart';

class _TrackingRepository extends MockRepository {
  int watchUsersCalls = 0;
  int watchLogsCalls = 0;

  @override
  Stream<List<AppUser>> watchUsers() {
    watchUsersCalls++;
    return super.watchUsers();
  }

  @override
  Stream<List<SystemLog>> watchLogs() {
    watchLogsCalls++;
    return super.watchLogs();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a citizen session does not fetch the staff-only collections', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = _TrackingRepository();
    final appState = AppState(repository: repository);

    await appState.login('citizen@citisense.com', 'password');

    expect(appState.isLoggedIn, isTrue);
    expect(appState.complaints, isNotEmpty);
    expect(repository.watchUsersCalls, 0);
    expect(repository.watchLogsCalls, 0);
    expect(appState.users, isEmpty);
  });

  test('staff sessions still fetch users and logs', () async {
    SharedPreferences.setMockInitialValues({});

    final adminRepo = _TrackingRepository();
    final adminState = AppState(repository: adminRepo);
    await adminState.login('admin@citisense.com', 'password');
    expect(adminRepo.watchUsersCalls, greaterThanOrEqualTo(1));
    expect(adminRepo.watchLogsCalls, greaterThanOrEqualTo(1));
    expect(adminState.users, isNotEmpty);

    final officerRepo = _TrackingRepository();
    final officerState = AppState(repository: officerRepo);
    await officerState.login('officer@citisense.com', 'password');
    expect(officerRepo.watchUsersCalls, greaterThanOrEqualTo(1));
    expect(officerRepo.watchLogsCalls, 0);
    expect(officerState.users, isNotEmpty);
  });
}
