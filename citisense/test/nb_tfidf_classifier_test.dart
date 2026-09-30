import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:citisense/models/enums.dart';
import 'package:citisense/services/nb_tfidf_classifier.dart';
import 'package:citisense/services/sentiment_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NbTfidfClassifier parity vs trained sklearn model', () {
    late List<Map<String, dynamic>> fixtures;

    setUpAll(() async {
      final modelJson =
          await rootBundle.loadString('assets/ml/sentiment_nb.json');
      await NbTfidfClassifier.loadFromString(modelJson);
      final fixturesJson =
          await rootBundle.loadString('assets/ml/parity_fixtures.json');
      fixtures = (jsonDecode(fixturesJson) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    });

    test('loads the exported model', () {
      expect(NbTfidfClassifier.instance, isNotNull);
      expect(NbTfidfClassifier.instance!.available, isTrue);
      expect(NbTfidfClassifier.instance!.classes,
          containsAll(['negative', 'neutral', 'positive']));
    });

    test('reproduces sklearn log-probabilities for all fixtures to 1e-6',
        () {
      final classifier = NbTfidfClassifier.instance!;
      for (final fixture in fixtures) {
        final prediction = classifier.predict(fixture['text'] as String);
        final expected = (fixture['log_proba'] as List)
            .map((e) => (e as num).toDouble())
            .toList();

        expect(prediction.logProbas.length, expected.length,
            reason: 'fixture: ${fixture['text']}');
        for (var i = 0; i < expected.length; i++) {
          expect(
            prediction.logProbas[i],
            closeTo(expected[i], 1e-6),
            reason: 'log-proba mismatch for fixture: ${fixture['text']}',
          );
        }
        expect(prediction.label, fixture['predicted'],
            reason: 'predicted label mismatch for fixture: ${fixture['text']}');
      }
    });

    test('matches the sklearn predicted label for every fixture', () {
      final classifier = NbTfidfClassifier.instance!;
      for (final fixture in fixtures) {
        expect(classifier.predict(fixture['text'] as String).label,
            fixture['predicted'],
            reason: 'classifier label for: ${fixture['text']}');
      }
    });
  test('SentimentEngine uses the NB classifier when loaded', () {
      final result = SentimentEngine.analyze(
        'Walang tubig po dito sa amin for three days na, hirap na kami',
        ComplaintCategory.water,
      );
      expect(result.sentiment, Sentiment.negative);
      expect(result.recommendation, isNotEmpty);
    });

  test('low-confidence NB defers to lexicon for OOV English complaints', () {
      const text = 'uncollected garbage on the corner near the market';
      final raw = NbTfidfClassifier.instance!.predict(text);
      expect(raw.confidence, lessThan(0.60),
          reason: 'precondition: the model is unsure on this text');
      final result = SentimentEngine.analyze(text, ComplaintCategory.waste);
      expect(result.sentiment, Sentiment.negative);
      expect(result.recommendation, contains('cleanup'));
    });
  });
}