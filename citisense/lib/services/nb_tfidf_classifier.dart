import 'dart:convert';
import 'dart:math' as math;

import '../models/enums.dart';

class NbPrediction {
  final Sentiment sentiment;
  final String label;
  final List<double> logProbas;
  final double confidence;

  const NbPrediction({
    required this.sentiment,
    required this.label,
    required this.logProbas,
    required this.confidence,
  });
}

class NbTfidfClassifier {
  NbTfidfClassifier._();

  static NbTfidfClassifier? _instance;
  static NbTfidfClassifier? get instance => _instance;

  List<String> classes = const [];
  List<String> _vocab = const [];
  List<double> _idf = const [];
  List<List<double>>? _featureLogProb;
  List<double> _classLogPrior = const [];

  bool loaded = false;

  bool get available => loaded;

  /// Model version — bump when retraining so logs/telemetry can distinguish
  /// which model produced a prediction.
  static const String modelVersion = '1.0.0';

  static final RegExp _tokenRe = RegExp(r'[^a-z0-9]+');

  static Future<void> loadFromString(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final classifier = NbTfidfClassifier._();
    classifier.classes = (data['classes'] as List).cast<String>();
    classifier._vocab = (data['vocab'] as List).cast<String>();
    classifier._idf =
        (data['idf'] as List).map((e) => (e as num).toDouble()).toList();
    classifier._featureLogProb = (data['feature_log_prob'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
    classifier._classLogPrior = (data['class_log_prior'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    classifier.loaded = true;
    _instance = classifier;
  }

  List<String> tokenize(String text) {
    return text
        .toLowerCase()
        .split(_tokenRe)
        .where((t) => t.isNotEmpty)
        .toList();
  }

  List<String> ngrams(List<String> tokens) {
    final grams = List<String>.of(tokens);
    for (var i = 0; i < tokens.length - 1; i++) {
      grams.add('${tokens[i]}_${tokens[i + 1]}');
    }
    return grams;
  }

  NbPrediction predict(String text) {
    final logP = _logProbas(text);
    var best = 0;
    for (var i = 1; i < logP.length; i++) {
      if (logP[i] > logP[best]) best = i;
    }
    final label = classes[best];
    return NbPrediction(
      sentiment: SentimentX.fromString(label),
      label: label,
      logProbas: logP,
      confidence: _softmax(logP)[best],
    );
  }

  /// Numerically stable softmax.  The log-probabilities returned by
  /// [_logProbas] are already normalised, but routing through the max-
  /// subtraction trick guards against underflow on very negative values.
  static List<double> _softmax(List<double> logP) {
    final maxLogP = logP.reduce(math.max);
    var sumExp = 0.0;
    for (final v in logP) {
      sumExp += math.exp(v - maxLogP);
    }
    if (sumExp == 0.0) return List<double>.filled(logP.length, 0.0);
    return [for (final v in logP) math.exp(v - maxLogP) / sumExp];
  }

  List<double> _logProbas(String text) {
    final grams = ngrams(tokenize(text));
    final counts = <String, int>{};
    for (final g in grams) {
      counts[g] = (counts[g] ?? 0) + 1;
    }

    final index = <String, int>{};
    for (var i = 0; i < _vocab.length; i++) {
      index[_vocab[i]] = i;
    }

    final raw = <int, double>{};
    counts.forEach((g, c) {
      final idx = index[g];
      if (idx != null) {
        raw[idx] = c * _idf[idx];
      }
    });

    var norm2 = 0.0;
    raw.forEach((_, v) {
      norm2 += v * v;
    });
    final inv = norm2 > 0 ? 1.0 / math.sqrt(norm2) : 0.0;

    final jll = <double>[];
    for (var c = 0; c < classes.length; c++) {
      var sum = 0.0;
      raw.forEach((idx, v) {
        sum += v * inv * _featureLogProb![c][idx];
      });
      jll.add(sum + _classLogPrior[c]);
    }

    final maxJll = jll.reduce((a, b) => a > b ? a : b);
    var sumExp = 0.0;
    for (final v in jll) {
      sumExp += math.exp(v - maxJll);
    }
    final logNorm = maxJll + math.log(sumExp);
    return [for (final v in jll) v - logNorm];
  }
}