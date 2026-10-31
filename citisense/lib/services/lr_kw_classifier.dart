import 'dart:convert';
import 'dart:math' as math;

class LRKwPrediction {
  final String label;
  final List<double> probabilities;
  final double confidence;

  const LRKwPrediction({
    required this.label,
    required this.probabilities,
    required this.confidence,
  });
}

class LRKwClassifier {
  LRKwClassifier._();

  static LRKwClassifier? _sentimentInstance;
  static LRKwClassifier? _urgencyInstance;
  static LRKwClassifier? _categoryInstance;

  static LRKwClassifier? get sentimentInstance => _sentimentInstance;
  static LRKwClassifier? get urgencyInstance => _urgencyInstance;
  static LRKwClassifier? get categoryInstance => _categoryInstance;

  List<String> classes = const [];
  List<String> _vocab = const [];
  List<double> _idf = const [];
  List<List<double>> _tfidfCoef = const [];
  List<List<double>> _kwCoef = const [];
  List<double> _intercept = const [];
  Map<String, List<String>> _kwDict = const {};

  bool loaded = false;

  bool get available => loaded;

  static const String modelVersion = '2.0.0';
  static final RegExp _tokenRe = RegExp(r'[^a-z0-9]+');

  static Future<void> loadSentiment(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final classifier = LRKwClassifier._();
    classifier.classes = (data['classes'] as List).cast<String>();
    classifier._vocab = (data['vocab'] as List).cast<String>();
    classifier._idf = (data['idf'] as List).map((e) => (e as num).toDouble()).toList();
    classifier._tfidfCoef = (data['tfidf_coef'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
    classifier._kwCoef = (data['kw_coef'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
    classifier._intercept = (data['intercept'] as List).map((e) => (e as num).toDouble()).toList();
    classifier._kwDict = (data['kw_dict'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as List).cast<String>()));
    classifier.loaded = true;
    _sentimentInstance = classifier;
  }

  static Future<void> loadUrgency(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final classifier = LRKwClassifier._();
    classifier.classes = (data['classes'] as List).cast<String>();
    classifier._vocab = (data['vocab'] as List).cast<String>();
    classifier._idf = (data['idf'] as List).map((e) => (e as num).toDouble()).toList();
    classifier._tfidfCoef = (data['tfidf_coef'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
    classifier._kwCoef = (data['kw_coef'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
    classifier._intercept = (data['intercept'] as List).map((e) => (e as num).toDouble()).toList();
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

  LRKwPrediction predict(String text) {
    final logits = _logits(text);
    final probs = _softmax(logits);
    var best = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[best]) best = i;
    }
    return LRKwPrediction(
      label: classes[best],
      probabilities: probs,
      confidence: probs[best],
    );
  }

  static List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    var sumExp = 0.0;
    for (final v in logits) {
      sumExp += math.exp(v - maxLogit);
    }
    if (sumExp == 0.0) return List<double>.filled(logits.length, 0.0);
    return [for (final v in logits) math.exp(v - maxLogit) / sumExp];
  }

  List<double> _logits(String text) {
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
    for (var classIdx = 0; classIdx < _kwDict.length; classIdx++) {
      final className = _kwDict.keys.elementAt(classIdx);
      final keywords = _kwDict[className]!;
      var count = 0;
      final textLower = text.toLowerCase();
      for (final kw in keywords) {
        if (textLower.contains(kw)) count++;
      }
      if (count > 0) kwCounts[classIdx] = count;
    }

    // Compute logits for each class
    final logits = <double>[];
    for (var c = 0; c < classes.length; c++) {
      var sum = _intercept[c];
      
      // TF-IDF contribution
      tfidfScores.forEach((idx, v) {
        sum += v * inv * _tfidfCoef[c][idx];
      });
      
      // Keyword contribution
      kwCounts.forEach((kwIdx, count) {
        sum += count * _kwCoef[c][kwIdx];
      });
      
      logits.add(sum);
    }

    return logits;
  }
}