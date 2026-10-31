import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'services/firebase_repository.dart';
import 'services/mock_repository.dart';
import 'services/sentiment_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentimentEngine.initialize();

  if (useFirebase) {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }
    // Enable offline persistence so the app works without internet
    // and loads cached data instantly on startup.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    // Initialize FCM for push notifications
    await FcmService.instance.initialize();
    runApp(App(repository: FirebaseRepository()));
  } else {
    runApp(App(repository: MockRepository()));
  }
}
