import 'package:flutter_test/flutter_test.dart';

/// Simulates the Firestore security rules from firestore.rules as pure Dart
/// functions so the enforcement logic can be unit-tested without the Firebase
/// emulator. Mirrors the CEL rules line-for-line.
class FirestoreRules {
  static bool signedIn(bool authNotNull) => authNotNull;

  /// match /users/{userId}
  static bool usersRead(bool authNotNull) => signedIn(authNotNull);

  static bool usersCreate({
    required bool authNotNull,
    required String? authUid,
    required String userId,
    required String newRole,
    required bool passwordEmpty,
  }) =>
      signedIn(authNotNull) &&
      authUid == userId &&
      newRole == 'citizen' &&
      passwordEmpty;

  static bool usersUpdate({
    required bool authNotNull,
    required String? authUid,
    required String userId,
    required bool roleUnchanged,
  }) =>
      signedIn(authNotNull) &&
      authUid == userId &&
      roleUnchanged;

  static bool usersDelete() => false;

  /// match /complaints/{complaintId}
  static bool complaintsRead(bool authNotNull) => signedIn(authNotNull);

  static bool complaintsCreate({
    required bool authNotNull,
    required String? authUid,
    required String citizenId,
    required String status,
  }) =>
      signedIn(authNotNull) &&
      citizenId == authUid &&
      status == 'pending';

  static bool complaintsUpdate(bool authNotNull) => signedIn(authNotNull);

  static bool complaintsDelete() => false;

  /// match /logs/{logId}
  static bool logsRead(bool authNotNull) => signedIn(authNotNull);

  static bool logsCreate(bool authNotNull) => signedIn(authNotNull);

  static bool logsUpdate() => false;

  static bool logsDelete() => false;

  /// match /{document=**} catch-all
  static bool catchAll() => false;
}

void main() {
  group('Firestore rules — users collection', () {
    test('signed-in user can read any user profile', () {
      expect(FirestoreRules.usersRead(true), isTrue);
    });

    test('unauthenticated user cannot read user profiles', () {
      expect(FirestoreRules.usersRead(false), isFalse);
    });

    test('citizen can create their own profile with empty password', () {
      expect(
        FirestoreRules.usersCreate(
          authNotNull: true,
          authUid: 'u1',
          userId: 'u1',
          newRole: 'citizen',
          passwordEmpty: true,
        ),
        isTrue,
      );
    });

    test('cannot create profile for another user', () {
      expect(
        FirestoreRules.usersCreate(
          authNotNull: true,
          authUid: 'u1',
          userId: 'u2',
          newRole: 'citizen',
          passwordEmpty: true,
        ),
        isFalse,
      );
    });

    test('cannot create profile with non-citizen role', () {
      expect(
        FirestoreRules.usersCreate(
          authNotNull: true,
          authUid: 'u1',
          userId: 'u1',
          newRole: 'officer',
          passwordEmpty: true,
        ),
        isFalse,
      );
    });

    test('cannot create profile with non-empty password', () {
      expect(
        FirestoreRules.usersCreate(
          authNotNull: true,
          authUid: 'u1',
          userId: 'u1',
          newRole: 'citizen',
          passwordEmpty: false,
        ),
        isFalse,
      );
    });

    test('unauthenticated cannot create user profile', () {
      expect(
        FirestoreRules.usersCreate(
          authNotNull: false,
          authUid: null,
          userId: 'u1',
          newRole: 'citizen',
          passwordEmpty: true,
        ),
        isFalse,
      );
    });

    test('owner can update own profile without changing role', () {
      expect(
        FirestoreRules.usersUpdate(
          authNotNull: true,
          authUid: 'u1',
          userId: 'u1',
          roleUnchanged: true,
        ),
        isTrue,
      );
    });

    test('cannot change role on update', () {
      expect(
        FirestoreRules.usersUpdate(
          authNotNull: true,
          authUid: 'u1',
          userId: 'u1',
          roleUnchanged: false,
        ),
        isFalse,
      );
    });

    test('delete is never allowed on users', () {
      expect(FirestoreRules.usersDelete(), isFalse);
    });
  });

  group('Firestore rules — complaints collection', () {
    test('signed-in user can read any complaint', () {
      expect(FirestoreRules.complaintsRead(true), isTrue);
    });

    test('unauthenticated cannot read complaints', () {
      expect(FirestoreRules.complaintsRead(false), isFalse);
    });

    test('citizen can create own pending complaint', () {
      expect(
        FirestoreRules.complaintsCreate(
          authNotNull: true,
          authUid: 'u1',
          citizenId: 'u1',
          status: 'pending',
        ),
        isTrue,
      );
    });

    test('citizen cannot create complaint for another user', () {
      expect(
        FirestoreRules.complaintsCreate(
          authNotNull: true,
          authUid: 'u1',
          citizenId: 'u2',
          status: 'pending',
        ),
        isFalse,
      );
    });

    test('citizen cannot create complaint with non-pending status', () {
      expect(
        FirestoreRules.complaintsCreate(
          authNotNull: true,
          authUid: 'u1',
          citizenId: 'u1',
          status: 'resolved',
        ),
        isFalse,
      );
    });

    test('unauthenticated cannot create complaint', () {
      expect(
        FirestoreRules.complaintsCreate(
          authNotNull: false,
          authUid: null,
          citizenId: 'u1',
          status: 'pending',
        ),
        isFalse,
      );
    });

    test('any signed-in user can update any complaint', () {
      expect(FirestoreRules.complaintsUpdate(true), isTrue);
    });

    test('unauthenticated cannot update complaint', () {
      expect(FirestoreRules.complaintsUpdate(false), isFalse);
    });

    test('delete is never allowed on complaints', () {
      expect(FirestoreRules.complaintsDelete(), isFalse);
    });
  });

  group('Firestore rules — logs collection', () {
    test('signed-in user can read logs', () {
      expect(FirestoreRules.logsRead(true), isTrue);
    });

    test('unauthenticated cannot read logs', () {
      expect(FirestoreRules.logsRead(false), isFalse);
    });

    test('signed-in user can create logs', () {
      expect(FirestoreRules.logsCreate(true), isTrue);
    });

    test('unauthenticated cannot create logs', () {
      expect(FirestoreRules.logsCreate(false), isFalse);
    });

    test('update and delete are never allowed on logs', () {
      expect(FirestoreRules.logsUpdate(), isFalse);
      expect(FirestoreRules.logsDelete(), isFalse);
    });
  });

  group('Firestore rules — catch-all', () {
    test('any document not matched above is denied read and write', () {
      expect(FirestoreRules.catchAll(), isFalse);
    });
  });
}
