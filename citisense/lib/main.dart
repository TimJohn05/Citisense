import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'firebase_options.dart';
import 'services/citisense_nlp.dart';
import 'services/firebase_repository.dart';
import 'services/mock_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  CitiNlp.ensureLoaded();

  if (useFirebase) {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }
    runApp(App(repository: FirebaseRepository()));
  } else {
    runApp(App(repository: MockRepository()));
  }
}
