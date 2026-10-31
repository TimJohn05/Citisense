import 'package:flutter/services.dart' show rootBundle;

import '../models/enums.dart';
import 'nb_kw_classifier.dart';

class SentimentResult {
  final Sentiment sentiment;
  final String recommendation;

  const SentimentResult({required this.sentiment, required this.recommendation});
}

class UrgencyResult {
  final Urgency urgency;
  final String label;

  const UrgencyResult({required this.urgency, required this.label});
}

class SentimentEngine {
  static const double _minConfidence = 0.60;

  static const Set<String> _stopWords = {
    'ang', 'ng', 'nga', 'na', 'pa', 'po', 'opo', 'naman', 'namang', 'kasi',
    'kase', 'din', 'dinaman', 'rin', 'daw', 'raw', 'mga', 'lang', 'lamang',
    'eh', 'ay', 'ba', 'bang', 'nang', 'pang', 'yung', 'ung', 'yun', 'yan',
    'yang', 'ito', 'itong', 'iyan', 'doon', 'dun', 'dito', 'ko', 'mo',
    'kami', 'namin', 'natin', 'nila', 'sila', 'ako', 'ikaw', 'kayo', 'niyo',
    'ninyo', 'sa', 'si', 'sina', 'kanina', 'ngayon', 'dahil', 'para', 'pero',
    'meron', 'may', 'mayroon', 'kaya', 'kung', 'sana', 'tapos', 'pagkatapos',
    'nag', 'naka', 'maka', 'makapag', 'nagmula',
    'the', 'a', 'an', 'and', 'or', 'but', 'for', 'to', 'of', 'in', 'on',
    'at', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'i', 'you',
    'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them',
    'my', 'your', 'his', 'its', 'our', 'their', 'this', 'that', 'these',
    'those', 'some', 'any', 'all', 'each', 'every', 'with', 'without',
    'from', 'by', 'about', 'as', 'so', 'if', 'then', 'than', 'when',
    'where', 'which', 'who', 'whom', 'there', 'here', 'now', 'just',
    'very', 'too', 'also', 'more', 'most', 'only', 'since', 'until',
    'still', 'always', 'can', 'could', 'would', 'should', 'will', 'shall',
    'have', 'has', 'had', 'does', 'did', 'do', 'hasn',
  };

  static const Set<String> _negations = {
    'hindi', 'walang', 'wala', 'di', 'not', 'no', 'never', 'cannot',
    "can't", 'cant', 'dont', "don't", 'didnt', "didn't", 'isnt', "isn't",
    'wasnt', "wasn't", 'wont', "won't", 'neither', 'nor', "ain't", 'aint',
    'ayaw', 'ayaw ko', 'ayoko',
  };

  static const Set<String> _negationFillers = {
    'talaga', 'masyado', 'sobra', 'lang', 'po', 'nga', 'pa', 'na', 'ba',
    'naman', 'eh', 'ay', 'kasi', 'kase', 'din', 'rin', 'daw', 'raw',
    'sana', 'kaya', 'pala', 'yata',
  };

  static const List<String> _negativePhrases = [
    'walang ilaw', 'sira ang ilaw', 'sirang ilaw', 'walang kuryente',
    'no power', 'no electricity', 'no lights', 'light out', 'lights out',
    'walang signal', 'no signal', 'walang internet', 'no internet',
    'walang wifi', 'no wifi', 'walang tubig', 'wala pa ring', 'wala ring',
    'wala pang', 'no water', 'walang supply', 'no supply', 'sira ang',
    'sirang', 'sira na', 'nasira ang', 'butas ang', 'barado ang',
    'putol ang', 'putol na', 'baha sa', 'baha dito', 'bumaha', 'binaha',
    'hindi madaan', 'di madaan', 'hindi madadaan', 'di madadaan',
    'hindi madadaanan', 'di madadaanan', 'hindi madaraanan', 'hindi maka',
    'di maka', 'hindi na maka', 'cannot pass', "can't pass", 'brownout',
    'brown out', 'ang ingay', 'ingay sa', 'ingay ng', 'basura sa',
    'tambak ang', 'tambak ng', 'nakaharang', 'harang sa', 'muntik na',
    'muntikan', 'not cleaned', 'not collected', 'uncollected', 'overflowing',
    'sobra ang', 'kulang ang', 'kulang pa', 'walang budget', 'no budget',
    'hindi gumagana', 'di gumagana', 'hindi umiikot', 'di umiikot',
    'napupuyat', 'hindi matulog', 'masakit ulo', 'masakit ang ulo',
    'nakakastress', 'nakakairita', 'nakakabadtrip', 'sayang pera',
    'sayang oras', 'wala silang ginagawa', 'walang ginagawa', 'tamad ang',
    'lento ang', 'mabagal na', 'di na maayos', 'hindi na maayos',
    'pabayaan na', 'pabaya na', 'walang aksyon', 'walang kilos',
    'di naaksyunan', 'di naaksyunan', 'hindi naaksyunan',
  ];

  static const List<String> _positivePhrases = [
    'ayos na', 'ayos na ang', 'naayos na', 'naayos ang', 'nakaayos na',
    'gumana na', 'gumagana na', 'bumalik na', 'bumalik ang', 'may ilaw na',
    'may tubig na', 'malinis na', 'malinis na ang', 'luminis na',
    'maraming salamat', 'salamat po', 'salamat sa', 'thank you',
    'thank you sa', 'thanks sa', 'mabait ang', 'mababait ang',
    'nakatulong', 'tumulong', 'magaling ang', 'ang galing', 'mahusay ang',
    'mabilis ang', 'mabilis na', 'fast response', 'mabilis ang response',
    'maayos ang', 'maayos na', 'maganda ang', 'maliwanag na',
    'maliwanag ang', 'maaliwalas na', 'tahimik na', 'well done',
    'great job', 'good job', 'nice job', 'good work', 'nice work',
    'great work', 'okay na', 'ok na', 'sobrang galing', 'ang galing ng',
    'ang galing nila', 'mahusay sila', 'magaling sila', 'abtik sila',
    'mabilis sila', 'responsive sila', 'thank you sa barangay',
    'salamat sa barangay', 'thank you sa brgy', 'salamat sa brgy',
    'may action na', 'nakita ko na', 'naaksyunan na', 'naayos agad',
    'mabilis naaksyunan', 'agad naaksyunan', 'agad na-aksyunan',
  ];

  static const List<String> _negativeWords = [
    'bad', 'issue', 'problem', 'problems', 'broken', 'dirty', 'waste',
    'pothole', 'potholes', 'leak', 'leaking', 'smell', 'smelly', 'stinks',
    'garbage', 'trash', 'danger', 'dangerous', 'unsafe', 'clogged', 'dark',
    'accident', 'slow', 'noisy', 'rude', 'poor', 'fail', 'failed', 'error',
    'wrong', 'damage', 'damaged', 'hazard', 'flood', 'flooded', 'blocked',
    'cracked', 'crack', 'hole', 'holes', 'overflows', 'busted', 'flickering',
    'outage', 'outages', 'delay', 'delayed', 'late', 'neglect', 'neglected',
    'stagnant', 'foul', 'odor', 'pollution', 'contaminated', 'sewage',
    'sewer', 'drain', 'mess', 'obstructing', 'obstruction', 'vandalized',
    'graffiti', 'illegal', 'unclean', 'unpleasant', 'smoke', 'smoggy',
    'mosquito', 'mosquitoes', 'rats', 'pest', 'overgrown', 'weeds',
    'muddy', 'slippery', 'uneven', 'annoying', 'irritating', 'inconvenient',
    'traffic', 'congested', 'basura', 'sira', 'sirang', 'siraan', 'nasira',
    'nasiraan', 'butas', 'barado', 'bara', 'mabaho', 'mabantot', 'baho',
    'maingay', 'ingay', 'delikado', 'baha', 'binaha', 'bumaha', 'marumi',
    'dumi', 'madilim', 'dilim', 'pangit', 'panget', 'mali', 'kulang',
    'mabagal', 'putol', 'naputol', 'problema', 'makalat', 'kalat', 'maputik',
    'putik', 'madulas', 'trap', 'muntik', 'aksidente', 'sagabal', 'harang',
    'tambak', 'usok', 'mausok', 'masikip', 'siksikan', 'sakit', 'lamok',
    'dengue', 'hirap', 'nahihirapan', 'sobra', 'mabigat', 'galing',
    'loko', 'lokohin', 'linlang', 'linlangin', 'madaya', 'mandaraya',
    'panget', 'hindi maganda', 'di maganda', 'hindi mabuti', 'di mabuti',
    'wala', 'wlang', 'hindi meron', 'di meron', 'empty', 'zero', 'zeroed',
  ];

  static const List<String> _positiveWords = [
    'good', 'great', 'thanks', 'thank', 'thankful', 'grateful', 'appreciate',
    'appreciated', 'resolved', 'fixed', 'working', 'functional', 'restored',
    'improved', 'improvement', 'better', 'best', 'clean', 'cleaner', 'safe',
    'safer', 'fast', 'faster', 'prompt', 'quick', 'quickly', 'responsive',
    'helpful', 'polite', 'friendly', 'professional', 'efficient', 'excellent',
    'wonderful', 'amazing', 'awesome', 'nice', 'beautiful', 'bright', 'clear',
    'love', 'perfect', 'smooth', 'convenient', 'tidy', 'neat', 'organized',
    'okay', 'ok', 'ayos', 'maayos', 'naayos', 'nakaayos', 'maganda', 'magaling',
    'mabuti', 'mabait', 'mababait', 'mahusay', 'galing', 'salamat', 'malinis',
    'linis', 'luminis', 'maliwanag', 'mabilis', 'mabango', 'maaliwalas',
    'tahimik', 'tulong', 'tumulong', 'nakatulong', 'gumana', 'gumagana',
    'bumalik', 'naibalik', 'husay', 'ganda', 'kalma', 'masaya', 'natutuwa',
    'abtik', 'mabilis', 'responsive', 'reliable', 'trustworthy', 'legit',
    'recommend', 'recommended', 'refer', 'referred', 'support', 'supported',
  ];

  static const Map<ComplaintCategory, Set<String>> _categoryBoost = {
    ComplaintCategory.waste: {
      'basura', 'trash', 'garbage', 'tambak', 'dump', 'collection', 'collect',
      'hauler', 'truck', 'segregate', 'biodegradable', 'nonbiodegradable',
      'recyclable', 'compost', 'kitchen waste', 'yard waste',
    },
    ComplaintCategory.road: {
      'kalsada', 'daanan', 'road', 'street', 'asphalt', 'concrete', 'pothole',
      'crack', 'patching', 'repave', 'shoulder', 'gutter', 'curbside',
    },
    ComplaintCategory.water: {
      'tubig', 'water', 'faucet', 'gripo', 'pipe', 'pipa', 'leak', 'leaking',
      'supply', 'pressure', 'contaminated', 'potable', 'drinking',
      'meter', 'billing', 'bill', 'disconnection', 'reconnection',
    },
    ComplaintCategory.lighting: {
      'ilaw', 'light', 'lamp', 'poste', 'streetlight', 'bulb', 'fixture',
      'circuit', 'wiring', 'transformer', 'meralco', 'electric', 'power',
      'outage', 'brownout', 'blackout', 'flicker', 'flickering', 'dim',
    },
    ComplaintCategory.peaceOrder: {
      'tambay', 'istambay', 'noise', 'ingay', 'karaoke', 'videoke', 'party',
      'drinking', 'inuman', 'trouble', 'away', 'commotion', 'gulo', 'rido',
      'tanod', 'patrol', 'curfew', 'minors', 'batang', 'bata',
    },
    ComplaintCategory.trafficObstruction: {
      'parking', 'park', 'sasakyan', 'kotse', 'tricycle', 'trisikad',
      'sidewalk', 'pedestrian', 'crosswalk', 'loading', 'unloading',
      'terminal', 'pila', 'queue', 'traffic', 'congestion', 'jam',
    },
    ComplaintCategory.floodDrainage: {
      'baha', 'flood', 'drainage', 'kanal', 'ester', 'creek', 'river',
      'ilog', 'sapa', 'declog', 'declogging', 'desilt', 'desilting',
      'pump', 'pumping', 'waterway', 'water way', 'culvert', 'box culvert',
    },
    ComplaintCategory.healthSanitation: {
      'dengue', 'mosquito', 'lamok', 'fogging', 'spray', 'spraying',
      'sanitation', 'sanitary', 'toilet', 'cr', 'comfort room', 'septic',
      'tank', 'garbage', 'waste', 'medical', 'health', 'clinic',
      'vaccination', 'vaccine', 'immunization',
    },
    ComplaintCategory.electricalHazard: {
      'meralco', 'electric', 'electrical', 'wire', 'wiring', 'cable',
      'poste', 'transformer', 'meter', 'illegal', 'connection', 'jumper',
      'hook', 'hooking', 'tapping', 'live wire', 'exposed', 'spark',
      'short circuit', 'ground fault', 'electrocution', 'shock',
    },
    ComplaintCategory.publicFacilities: {
      'plaza', 'park', 'court', 'basketball', 'covered court', 'multi',
      'purpose', 'hall', 'building', 'office', 'center',
      'libreng', 'free', 'amenity', 'facility', 'equipment', 'playground',
      'slide', 'swing', 'monkey bars', 'gazebo', 'waiting shed',
    },
    ComplaintCategory.generalInquiry: {
      'tanong', 'question', 'inquire', 'inquiry', 'info', 'information',
      'requirement', 'requirements', 'document', 'documents', 'paper',
      'papers', 'clearance', 'permit', 'license', 'id', 'identification',
      'certificate', 'certification', 'schedule', 'time', 'hours', 'open',
      'close', 'holiday', 'weekend',
    },
  };

  static Future<void> initialize() async {
    await NbKwClassifier.loadSentiment(
      await rootBundle.loadString('assets/ml/sentiment_nb_kw.json'),
    );
    await NbKwClassifier.loadUrgency(
      await rootBundle.loadString('assets/ml/urgency_nb_kw.json'),
    );
  }

  static SentimentResult analyze(String message, ComplaintCategory category) {
    final classifier = NbKwClassifier.sentimentInstance;
    if (classifier != null && classifier.available) {
      final prediction = classifier.predict(message);
      if (prediction.confidence >= _minConfidence) {
        return SentimentResult(
          sentiment: SentimentX.fromString(prediction.label),
          recommendation: _recommendation(SentimentX.fromString(prediction.label), category),
        );
      }
    }
    return _lexiconAnalyze(message, category);
  }

  static UrgencyResult analyzeUrgency(String message) {
    final classifier = NbKwClassifier.urgencyInstance;
    if (classifier != null && classifier.available) {
      final prediction = classifier.predict(message);
      return UrgencyResult(
        urgency: UrgencyX.fromString(prediction.label),
        label: prediction.label,
      );
    }
    return UrgencyResult(urgency: Urgency.moderate, label: 'moderate');
  }

  static String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'(.)\1{2,}'), r'$1$1')
        .replaceAll(RegExp(r'\bwlang\b'), 'walang')
        .replaceAll(RegExp(r'\bwla\b'), 'wala')
        .replaceAll(RegExp(r'\bd2\b'), 'dito')
        .replaceAll(RegExp(r'\bu\b'), 'you')
        .replaceAll(RegExp(r'\bq\b'), 'ako')
        .replaceAll(RegExp(r'\bqo\b'), 'ako')
        .replaceAll(RegExp(r'\bpq\b'), 'po')
        .replaceAll(RegExp(r'\bnmn\b'), 'naman')
        .replaceAll(RegExp(r'\btlaga\b'), 'talaga')
        .replaceAll(RegExp(r'\bsra\b'), 'sira')
        .replaceAll(RegExp(r'\bngng\b'), 'ng');
  }

  static bool _isNegated(List<String> tokens, int i) {
    if (i == 0) return false;
    if (_negations.contains(tokens[i - 1])) return true;
    if (i >= 2 &&
        _negationFillers.contains(tokens[i - 1]) &&
        _negations.contains(tokens[i - 2])) {
      return true;
    }
    return false;
  }

  static List<String> _extractNgrams(List<String> tokens, int n) {
    if (tokens.length < n) return [];
    final ngrams = <String>[];
    for (var i = 0; i <= tokens.length - n; i++) {
      ngrams.add(tokens.sublist(i, i + n).join(' '));
    }
    return ngrams;
  }

  static SentimentResult _lexiconAnalyze(String message, ComplaintCategory category) {
    final msg = _normalize(message.toLowerCase());
    var negative = 0;
    var positive = 0;
    var negativePhraseHits = 0;
    var positivePhraseHits = 0;

    for (final phrase in _negativePhrases) {
      if (msg.contains(phrase)) {
        negative += 2;
        negativePhraseHits++;
      }
    }
    for (final phrase in _positivePhrases) {
      if (msg.contains(phrase)) {
        positive += 2;
        positivePhraseHits++;
      }
    }

    final tokens = msg
        .split(RegExp(r"[^a-z0-9']+"))
        .where((t) => t.isNotEmpty && !_stopWords.contains(t))
        .toList();

    final bigrams = _extractNgrams(tokens, 2);
    final trigrams = _extractNgrams(tokens, 3);

    final boostWords = _categoryBoost[category] ?? {};
    var categoryBoostScore = 0;
    for (final word in tokens) {
      if (boostWords.contains(word)) categoryBoostScore++;
    }
    for (final bg in bigrams) {
      if (boostWords.contains(bg)) categoryBoostScore += 2;
    }
    for (final tg in trigrams) {
      if (boostWords.contains(tg)) categoryBoostScore += 3;
    }

    if (categoryBoostScore >= 3) {
      negative += (categoryBoostScore / 2).floor();
    }

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final negated = _isNegated(tokens, i);
      if (_negativeWords.contains(token)) {
        if (negated) {
          positive++;
        } else {
          negative++;
        }
      } else if (_positiveWords.contains(token)) {
        if (negated) {
          negative++;
        } else {
          positive++;
        }
      }
    }

    for (final bg in bigrams) {
      if (_negativePhrases.any((p) => p == bg)) {
        negative += 2;
        negativePhraseHits++;
      } else if (_positivePhrases.any((p) => p == bg)) {
        positive += 2;
        positivePhraseHits++;
      }
    }
    for (final tg in trigrams) {
      if (_negativePhrases.any((p) => p == tg)) {
        negative += 3;
        negativePhraseHits++;
      } else if (_positivePhrases.any((p) => p == tg)) {
        positive += 3;
        positivePhraseHits++;
      }
    }

    final sentiment = _decide(negative, positive, negativePhraseHits, positivePhraseHits);
    return SentimentResult(sentiment: sentiment, recommendation: _recommendation(sentiment, category));
  }

  static Sentiment _decide(int negative, int positive, int negPhrases, int posPhrases) {
    if (negative > positive) return Sentiment.negative;
    if (positive > negative) return Sentiment.positive;
    if (negPhrases > 0) return Sentiment.negative;
    if (posPhrases > 0) return Sentiment.positive;
    return Sentiment.neutral;
  }

  static String _recommendation(Sentiment sentiment, ComplaintCategory category) {
    if (sentiment == Sentiment.negative) {
      switch (category) {
        case ComplaintCategory.waste: return 'Schedule a cleanup operation for the reported area';
        case ComplaintCategory.road: return 'Dispatch the maintenance crew for immediate repair';
        case ComplaintCategory.water: return 'Check for pipe leaks or water contamination';
        case ComplaintCategory.lighting: return 'Inspect and repair the street lighting circuit';
        case ComplaintCategory.peaceOrder: return 'Deploy tanod patrol to address the disturbance';
        case ComplaintCategory.trafficObstruction: return 'Clear the obstruction and issue a violation notice';
        case ComplaintCategory.floodDrainage: return 'Inspect and declog the drainage system in the area';
        case ComplaintCategory.healthSanitation: return 'Coordinate with health workers for sanitation response';
        case ComplaintCategory.electricalHazard: return 'Cordon the area and report to Meralco immediately';
        case ComplaintCategory.publicFacilities: return 'Schedule facility repair and post safety notice';
        case ComplaintCategory.generalInquiry: return 'Investigate the reported community concern';
      }
    }
    if (sentiment == Sentiment.positive) {
      switch (category) {
        case ComplaintCategory.waste: return 'Commend the sanitation team for the effort';
        case ComplaintCategory.road: return 'Document the successful maintenance for records';
        case ComplaintCategory.water: return 'Acknowledge the stable water service';
        case ComplaintCategory.lighting: return 'Acknowledge the restored lighting service';
        case ComplaintCategory.peaceOrder: return 'Commend the tanod team for restoring peace';
        case ComplaintCategory.trafficObstruction: return 'Acknowledge the successful road clearing operation';
        case ComplaintCategory.floodDrainage: return 'Document the drainage improvement for records';
        case ComplaintCategory.healthSanitation: return 'Commend the health workers for their response';
        case ComplaintCategory.electricalHazard: return 'Acknowledge the swift hazard resolution';
        case ComplaintCategory.publicFacilities: return 'Document the facility improvement for records';
        case ComplaintCategory.generalInquiry: return 'Thank the citizen for their positive feedback';
      }
    }
    return 'Monitor the situation for any changes';
  }
}