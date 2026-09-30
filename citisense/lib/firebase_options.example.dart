import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for CitiSense.
///
/// Web builds MUST pass explicit options to [Firebase.initializeApp] (the
/// native platforms read them from google-services.json instead).
///
/// This file is generated per Firebase project. Copy
/// `firebase_options.example.dart` to `lib/firebase_options.dart` and replace
/// every `REPLACE_WITH_...` value with the values Firebase Console prints for
/// your own project. `lib/firebase_options.dart` is git-ignored on purpose.
class DefaultFirebaseOptions {
  static const FirebaseOptions _web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: 'REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: 'REPLACE_WITH_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    authDomain: 'REPLACE_WITH_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _web;
    // Native platforms load their config from google-services.json, so an
    // explicit options object is only required on the web.
    throw UnsupportedError(
      'DefaultFirebaseOptions.currentPlatform should only be read on the web; '
      'mobile initializes Firebase without options (google-services.json).',
    );
  }
}
