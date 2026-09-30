import 'package:flutter_test/flutter_test.dart';

import 'package:citisense/models/enums.dart';
import 'package:citisense/services/sentiment_engine.dart';

void main() {
  group('SentimentEngine Taglish', () {
    SentimentResult analyze(String text) =>
        SentimentEngine.analyze(text, ComplaintCategory.generalInquiry);

    test('negative Taglish: street light', () {
      final r = analyze(
          'Walang ilaw sa kalye, delikado para sa mga bata, paki ayos naman po.');
      expect(r.sentiment, Sentiment.negative);
    });

    test('negative Taglish: no water supply', () {
      final r = analyze(
          'Wala pa ring tubig dito since Monday, hindi maka-ligo ang family ko.');
      expect(r.sentiment, Sentiment.negative);
    });

    test('negative mixed English', () {
      final r = analyze('The street is dark and unsafe for kids.');
      expect(r.sentiment, Sentiment.negative);
    });

    test('negative Taglish: uncollected trash', () {
      final r = analyze('Puro basura sa kalsada, hindi nila nililinis, ang baho!');
      expect(r.sentiment, Sentiment.negative);
    });

    test('negative English: uncollected garbage', () {
      final r = analyze('Uncollected garbage on the corner near the market.');
      expect(r.sentiment, Sentiment.negative);
    });

    test('negative Taglish: construction noise', () {
      final r = analyze(
          'Ang ingay ng construction dito, hindi na kami maka-tulog sa gabi.');
      expect(r.sentiment, Sentiment.negative);
    });

    test('positive Taglish: thanks and fixed lights', () {
      final r = analyze('Salamat po, naayos na ang ilaw at malinis na ang daan.');
      expect(r.sentiment, Sentiment.positive);
    });

    test('positive Taglish: fixed and fast action', () {
      final r = analyze('Ayos na ang ilaw, maraming salamat sa mabilis na action ninyo!');
      expect(r.sentiment, Sentiment.positive);
    });

    test('negation flips a negative word', () {
      final r = analyze('Hindi naman mabaho ang daan, maayos naman.');
      expect(r.sentiment, Sentiment.positive);
    });

    test('walang problema is positive', () {
      final r = analyze('Wala namang problema, okay na po.');
      expect(r.sentiment, Sentiment.positive);
    });

    test('genuinely neutral stays neutral', () {
      final r = analyze('The barangay held a meeting today.');
      expect(r.sentiment, Sentiment.neutral);
    });
  });
}
