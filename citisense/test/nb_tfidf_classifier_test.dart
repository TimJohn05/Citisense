

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:citisense/models/enums.dart';
import 'package:citisense/services/nb_kw_classifier.dart';
import 'package:citisense/services/sentiment_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NbKwClassifier sentiment model', () {
    late NbKwClassifier classifier;

    setUpAll(() async {
      final modelJson =
          await rootBundle.loadString('assets/ml/sentiment_nb_kw.json');
      await NbKwClassifier.loadSentiment(modelJson);
      classifier = NbKwClassifier.sentimentInstance!;
    });

    test('loads the exported NB+KW model', () {
      expect(classifier, isNotNull);
      expect(classifier.available, isTrue);
      expect(classifier.classes, containsAll(['negative', 'neutral', 'positive']));
    });

    test('predicts sentiment for common Taglish complaints', () {
      // Negative
      expect(classifier.predict('Walang tubig po dito sa amin').label, 'negative');
      expect(classifier.predict('Sirang ilaw sa kalsada').label, 'negative');
      expect(classifier.predict('Basura tambak sa kanto').label, 'negative');
      
      // Positive
      expect(classifier.predict('Salamat po sa mabilis na aksyon').label, 'positive');
      expect(classifier.predict('Ayos na ang ilaw').label, 'positive');
      expect(classifier.predict('Malinis na ang kalsada').label, 'positive');
      
      // Neutral (queries)
      expect(classifier.predict('Ano schedule ng garbage collection').label, 'neutral');
      expect(classifier.predict('Pwede magtanong kung bakit walang tubig').label, 'negative'); // contains "walang tubig"
    });
  });

  group('NbKwClassifier urgency model', () {
    late NbKwClassifier classifier;

    setUpAll(() async {
      final modelJson =
          await rootBundle.loadString('assets/ml/urgency_nb_kw.json');
      await NbKwClassifier.loadUrgency(modelJson);
      classifier = NbKwClassifier.urgencyInstance!;
    });

    test('loads the exported NB+KW urgency model', () {
      expect(classifier, isNotNull);
      expect(classifier.available, isTrue);
      expect(classifier.classes, containsAll(['emergency', 'low', 'moderate']));
    });

    test('predicts urgency for common scenarios', () {
      // Emergency
      expect(classifier.predict('Flash flood lagpas tuhod rescue needed').label, 'emergency');
      expect(classifier.predict('Live wire nakalantad electrocution').label, 'emergency');
      
      // Moderate
      expect(classifier.predict('Walang tubig dalawang araw na').label, 'moderate');
      expect(classifier.predict('Sirang kalsada pothole malaki').label, 'moderate');
      expect(classifier.predict('Baha sa kalsada konting ulan').label, 'moderate');
      
      // Low
      expect(classifier.predict('Ano schedule ng collection').label, 'low');
      expect(classifier.predict('Thank you po sa mabilis na action').label, 'low');
    });
  });

  group('SentimentEngine with NB+KW classifier', () {
    setUpAll(() async {
      await SentimentEngine.initialize();
    });

    test('uses the NB+KW classifier when loaded', () {
      final result = SentimentEngine.analyze(
        'Walang tubig po dito sa amin for three days na, hirap na kami',
        ComplaintCategory.water,
      );
      expect(result.sentiment, Sentiment.negative);
      expect(result.recommendation, isNotEmpty);
    });

    test('low-confidence NB defers to lexicon for OOV text', () {
      const oovText = 'xyzzy foobar baz quux gibberish nonsense';
      final classifier = NbKwClassifier.sentimentInstance!;
      final raw = classifier.predict(oovText);
      // NB confidence is ~0.45 < 0.60, so it defers to lexicon
      expect(raw.confidence, lessThan(0.60),
          reason: 'precondition: the model is unsure on truly OOV text');
      final result = SentimentEngine.analyze(oovText, ComplaintCategory.waste);
      // Lexicon fallback: OOV text has no matching words -> neutral
      expect(result.sentiment, Sentiment.neutral);
    });
  });
}