import 'dart:convert';
import 'dart:math' as math;

import '../models/enums.dart';

class NbKwPrediction {
  final Sentiment sentiment;
  final String label;
  final List<double> logProbas;
  final double confidence;

  const NbKwPrediction({
    required this.sentiment,
    required this.label,
    required this.logProbas,
    required this.confidence,
  });
}

class NbKwClassifier {
  NbKwClassifier._();

  static NbKwClassifier? _sentimentInstance;
  static NbKwClassifier? _urgencyInstance;

  static NbKwClassifier? get sentimentInstance => _sentimentInstance;
  static NbKwClassifier? get urgencyInstance => _urgencyInstance;

  List<String> classes = const [];
  List<String> _vocab = const [];
  List<double> _idf = const [];
  List<List<double>> _featureLogProbTfidf = const [];
  List<List<double>> _featureLogProbKw = const [];
  List<double> _classLogPrior = const [];
  Map<String, List<String>> _kwDict = const {};

  bool loaded = false;

  bool get available => loaded;

  static const String modelVersion = '1.1.0';
  static final RegExp _tokenRe = RegExp(r'[^a-z0-9]+');

  static Future<void> loadSentiment(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final classifier = NbKwClassifier._();
    classifier.classes = (data['classes'] as List).cast<String>();
    classifier._vocab = (data['vocab'] as List).cast<String>();
    classifier._idf = (data['idf'] as List).map((e) => (e as num).toDouble()).toList();
    classifier._featureLogProbTfidf = (data['feature_log_prob_tfidf'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
    classifier._featureLogProbKw = (data['feature_log_prob_kw'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
    classifier._classLogPrior = (data['class_log_prior'] as List)
        .map((e) => (e as num).toDouble()).toList();
    classifier._kwDict = (data['kw_dict'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as List).cast<String>()));
    classifier.loaded = true;
    _sentimentInstance = classifier;
  }

  static Future<void> loadUrgency(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final classifier = NbKwClassifier._();
    classifier.classes = (data['classes'] as List).cast<String>();
    classifier._vocab = (data['vocab'] as List).cast<String>();
    classifier._idf = (data['idf'] as List).map((e) => (e as num).toDouble()).toList();
    classifier._featureLogProbTfidf = (data['feature_log_prob_tfidf'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
    classifier._featureLogProbKw = (data['feature_log_prob_kw'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
    classifier._classLogPrior = (data['class_log_prior'] as List)
        .map((e) => (e as num).toDouble()).toList();
    classifier._kwDict = (data['kw_dict'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as List).cast<String>()));
    classifier.loaded = true;
    _urgencyInstance = classifier;
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

  NbKwPrediction predict(String text) {
    final logP = _logProbas(text);
    var best = 0;
    for (var i = 1; i < logP.length; i++) {
      if (logP[i] > logP[best]) best = i;
    }
    final label = classes[best];
    return NbKwPrediction(
      sentiment: SentimentX.fromString(label),
      label: label,
      logProbas: logP,
      confidence: _softmax(logP)[best],
    );
  }

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

    final vocabIndex = <String, int>{};
    for (var i = 0; i < _vocab.length; i++) {
      vocabIndex[_vocab[i]] = i;
    }

    // TF-IDF features
final tfidfScores = <int, double>{};
    for (final entry in counts.entries) {
      final g = entry.key;
      final c = entry.value;
      final idx = vocabIndex[g];
      if (idx != null) {
        tfidfScores[idx] = c * _idf[idx];
      }
    }

    // L2 normalize
    var norm2 = 0.0;
    tfidfScores.forEach((_, v) => norm2 += v * v);
    final inv = norm2 > 0 ? 1.0 / math.sqrt(norm2) : 0.0;

    // Keyword count features
    final kwCounts = <int, int>{};
    final classNames = _kwDict.keys.toList();
    for (var classIdx = 0; classIdx < classNames.length; classIdx++) {
      final className = classNames[classIdx];
      final keywords = _kwDict[className]!;
      var count = 0;
      final textLower = text.toLowerCase();
      for (final kw in keywords) {
        if (textLower.contains(kw)) count++;
      }
      if (count > 0) kwCounts[classIdx] = count;
    }

    // Compute log-probabilities for each class
    final jll = <double>[];
    for (var c = 0; c < classes.length; c++) {
      var sum = _classLogPrior[c];
      
      // TF-IDF contribution
      tfidfScores.forEach((idx, v) {
        sum += v * inv * _featureLogProbTfidf[c][idx];
      });
      
      // Keyword contribution
      kwCounts.forEach((kwIdx, count) {
        sum += count * _featureLogProbKw[c][kwIdx];
      });
      
      jll.add(sum);
    }

    // Normalize to log-probabilities
    final maxJll = jll.reduce((a, b) => a > b ? a : b);
    var sumExp = 0.0;
    for (final v in jll) {
      sumExp += math.exp(v - maxJll);
    }
    final logNorm = maxJll + math.log(sumExp);
    return [for (final v in jll) v - logNorm];
  }
}