import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/firebase_repository.dart';
import 'services/mock_repository.dart';

const bool useFirebase = bool.fromEnvironment('USE_FIREBASE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (useFirebase) {
    await Firebase.initializeApp();
    runApp(App(repository: FirebaseRepository()));
  } else {
    runApp(App(repository: MockRepository()));
  }
}
