import 'package:flutter/services.dart' show rootBundle;

import 'nb_tfidf_classifier.dart';

class CitiNlp {
  CitiNlp._();

  static Future<void> ensureLoaded() async {
    if (NbTfidfClassifier.instance?.available ?? false) return;
    try {
      final json = await rootBundle.loadString('assets/ml/sentiment_nb.json');
      await NbTfidfClassifier.loadFromString(json);
    } catch (_) {}
  }
}