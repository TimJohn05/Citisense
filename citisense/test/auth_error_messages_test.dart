import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:citisense/services/auth_error_messages.dart';

void main() {
  const rawCredential =
      'The supplied auth credential is incorrect, malformed or has expired.';

  test('maps invalid-credential to a friendly sign-in message', () {
    final error =
        FirebaseAuthException(code: 'invalid-credential', message: rawCredential);
    expect(friendlyAuthMessage(error), 'Incorrect email or password. '
        'Check for typos and try again.');
  });

  test('never leaks the raw Firebase message', () {
    final error =
        FirebaseAuthException(code: 'invalid-credential', message: rawCredential);
    final message = friendlyAuthMessage(error);
    expect(message, isNot(contains('supplied')));
    expect(message, isNot(contains('malformed')));
    expect(message, isNot(contains('expired')));
  });

  test('email-already-in-use suggests signing in instead', () {
    final error = FirebaseAuthException(code: 'email-already-in-use');
    expect(friendlyAuthMessage(error), 'That email is already registered. '
        'Try signing in instead.');
  });

  test('weak-password explains the minimum length', () {
    final error = FirebaseAuthException(code: 'weak-password');
    expect(friendlyAuthMessage(error, signingUp: true),
        contains('at least 6 characters'));
  });

  test('network failure points at connectivity', () {
    final error = FirebaseAuthException(code: 'network-request-failed');
    expect(friendlyAuthMessage(error), contains('No internet connection'));
  });

  test('unmapped and non-Firebase errors fall back to a generic message', () {
    expect(friendlyAuthMessage(Exception('boom')),
        'Sign in failed. Please try again.');
    expect(friendlyAuthMessage(Exception('boom'), signingUp: true),
        'Sign up failed. Please try again.');
    expect(
        friendlyAuthMessage(FirebaseAuthException(code: 'unknown-code')),
        'Sign in failed. Please try again.');
  });
}