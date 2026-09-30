import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citisense/models/app_user.dart';
import 'package:citisense/models/system_log.dart';
import 'package:citisense/services/mock_repository.dart';
import 'package:citisense/state/app_state.dart';

class _TrackingRepository extends MockRepository {
  int getUsersCalls = 0;
  int getLogsCalls = 0;

  @override
  Future<List<AppUser>> getUsers() {
    getUsersCalls++;
    return super.getUsers();
  }

  @override
  Future<List<SystemLog>> getLogs() {
    getLogsCalls++;
    return super.getLogs();
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
    expect(repository.getUsersCalls, 0);
    expect(repository.getLogsCalls, 0);
    expect(appState.users, isEmpty);
  });

  test('staff sessions still fetch users and logs', () async {
    SharedPreferences.setMockInitialValues({});

    final adminRepo = _TrackingRepository();
    final adminState = AppState(repository: adminRepo);
    await adminState.login('admin@citisense.com', 'password');
    expect(adminRepo.getUsersCalls, greaterThanOrEqualTo(1));
    expect(adminRepo.getLogsCalls, greaterThanOrEqualTo(1));
    expect(adminState.users, isNotEmpty);

    final officerRepo = _TrackingRepository();
    final officerState = AppState(repository: officerRepo);
    await officerState.login('officer@citisense.com', 'password');
    expect(officerRepo.getUsersCalls, greaterThanOrEqualTo(1));
    expect(officerRepo.getLogsCalls, greaterThanOrEqualTo(1));
  });
}
