import 'package:firebase_auth/firebase_auth.dart';

/// Maps a thrown auth error to a clear, user-facing message.
///
/// The raw [FirebaseAuthException] text (e.g. the "supplied auth credential"
/// wording) leaks implementation detail to the user and differs by provider,
/// so every known code is translated here. Anything unrecognized falls back
/// to a generic message.
String friendlyAuthMessage(Object error, {bool signingUp = false}) {
  if (error is! FirebaseAuthException) {
    return signingUp
        ? 'Sign up failed. Please try again.'
        : 'Sign in failed. Please try again.';
  }
  switch (error.code) {
    case 'email-already-in-use':
      return 'That email is already registered. Try signing in instead.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      if (signingUp) return 'Sign up failed. Please try again.';
      return 'Incorrect email or password. Check for typos and try again.';
    case 'network-request-failed':
      return 'No internet connection. Check your network and try again.';
    case 'too-many-requests':
      return 'Too many attempts. Wait a moment and try again.';
    case 'user-disabled':
      return 'This account has been disabled. Contact the administrator.';
    case 'operation-not-allowed':
      return 'Email and password sign-in is not available right now.';
    default:
      return signingUp
          ? 'Sign up failed. Please try again.'
          : 'Sign in failed. Please try again.';
  }
}