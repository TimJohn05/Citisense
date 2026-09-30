import '../models/enums.dart';
import 'nb_tfidf_classifier.dart';

class SentimentResult {
  final Sentiment sentiment;
  final String recommendation;

  const SentimentResult({required this.sentiment, required this.recommendation});
}

class SentimentEngine {
  // Tagalog/English particles, enclitics and filler words stripped before
  // keyword scoring so mixed Taglish sentences score on meaningful words only.
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
  };

  static const List<String> _negativePhrases = [
    'walang ilaw',
    'sira ang ilaw',
    'sirang ilaw',
    'walang kuryente',
    'no power',
    'no electricity',
    'no lights',
    'light out',
    'lights out',
    'walang signal',
    'no signal',
    'walang internet',
    'no internet',
    'walang wifi',
    'no wifi',
    'walang tubig',
    'wala pa ring',
    'wala ring',
    'wala pang',
    'no water',
    'walang supply',
    'no supply',
    'sira ang',
    'sirang',
    'sira na',
    'nasira ang',
    'butas ang',
    'barado ang',
    'putol ang',
    'putol na',
    'baha sa',
    'baha dito',
    'bumaha',
    'binaha',
    'hindi madaan',
    'di madaan',
    'hindi madadaan',
    'di madadaan',
    'hindi madadaanan',
    'di madadaanan',
    'hindi madaraanan',
    'hindi maka',
    'di maka',
    'hindi na maka',
    'cannot pass',
    "can't pass",
    'brownout',
    'brown out',
    'ang ingay',
    'ingay sa',
    'ingay ng',
    'basura sa',
    'tambak ang',
    'tambak ng',
    'nakaharang',
    'harang sa',
    'muntik na',
    'muntikan',
    'not cleaned',
    'not collected',
    'uncollected',
    'overflowing',
    'sobra ang',
    'kulang ang',
    'kulang pa',
    'walang budget',
    'no budget',
  ];

  static const List<String> _positivePhrases = [
    'ayos na',
    'ayos na ang',
    'naayos na',
    'naayos ang',
    'nakaayos na',
    'gumana na',
    'gumagana na',
    'bumalik na',
    'bumalik ang',
    'may ilaw na',
    'may tubig na',
    'malinis na',
    'malinis na ang',
    'luminis na',
    'maraming salamat',
    'salamat po',
    'salamat sa',
    'thank you',
    'thank you sa',
    'thanks sa',
    'mabait ang',
    'mababait ang',
    'nakatulong',
    'tumulong',
    'magaling ang',
    'ang galing',
    'mahusay ang',
    'mabilis ang',
    'mabilis na',
    'fast response',
    'mabilis ang response',
    'maayos ang',
    'maayos na',
    'maganda ang',
    'maliwanag na',
    'maliwanag ang',
    'maaliwalas na',
    'tahimik na',
    'well done',
    'great job',
    'good job',
    'nice job',
    'good work',
    'nice work',
    'great work',
    'okay na',
    'ok na',
  ];

  static const List<String> _negativeWords = [
    'bad',
    'issue',
    'problem',
    'problems',
    'broken',
    'dirty',
    'waste',
    'pothole',
    'potholes',
    'leak',
    'leaking',
    'smell',
    'smelly',
    'stinks',
    'garbage',
    'trash',
    'danger',
    'dangerous',
    'unsafe',
    'clogged',
    'dark',
    'accident',
    'slow',
    'noisy',
    'rude',
    'poor',
    'fail',
    'failed',
    'error',
    'wrong',
    'damage',
    'damaged',
    'hazard',
    'flood',
    'flooded',
    'blocked',
    'cracked',
    'crack',
    'hole',
    'holes',
    'overflows',
    'busted',
    'flickering',
    'outage',
    'outages',
    'delay',
    'delayed',
    'late',
    'neglect',
    'neglected',
    'stagnant',
    'foul',
    'odor',
    'pollution',
    'contaminated',
    'sewage',
    'sewer',
    'drain',
    'mess',
    'obstructing',
    'obstruction',
    'vandalized',
    'graffiti',
    'illegal',
    'unclean',
    'unpleasant',
    'smoke',
    'smoggy',
    'mosquito',
    'mosquitoes',
    'rats',
    'pest',
    'overgrown',
    'weeds',
    'muddy',
    'slippery',
    'uneven',
    'annoying',
    'irritating',
    'inconvenient',
    'traffic',
    'congested',
    'basura',
    'sira',
    'sirang',
    'siraan',
    'nasira',
    'nasiraan',
    'butas',
    'barado',
    'bara',
    'mabaho',
    'mabantot',
    'baho',
    'maingay',
    'ingay',
    'delikado',
    'baha',
    'binaha',
    'bumaha',
    'marumi',
    'dumi',
    'madilim',
    'dilim',
    'pangit',
    'panget',
    'mali',
    'kulang',
    'mabagal',
    'putol',
    'naputol',
    'problema',
    'makalat',
    'kalat',
    'maputik',
    'putik',
    'madulas',
    'trap',
    'muntik',
    'aksidente',
    'sagabal',
    'harang',
    'tambak',
    'usok',
    'mausok',
    'masikip',
    'siksikan',
    'sakit',
    'lamok',
    'dengue',
    'hirap',
    'nahihirapan',
    'sobra',
    'mabigat',
  ];

  static const List<String> _positiveWords = [
    'good',
    'great',
    'thanks',
    'thank',
    'thankful',
    'grateful',
    'appreciate',
    'appreciated',
    'resolved',
    'fixed',
    'working',
    'functional',
    'restored',
    'improved',
    'improvement',
    'better',
    'best',
    'clean',
    'cleaner',
    'safe',
    'safer',
    'fast',
    'faster',
    'prompt',
    'quick',
    'quickly',
    'responsive',
    'helpful',
    'polite',
    'friendly',
    'professional',
    'efficient',
    'excellent',
    'wonderful',
    'amazing',
    'awesome',
    'nice',
    'beautiful',
    'bright',
    'clear',
    'love',
    'perfect',
    'smooth',
    'convenient',
    'tidy',
    'neat',
    'organized',
    'okay',
    'ok',
    'ayos',
    'maayos',
    'naayos',
    'nakaayos',
    'maganda',
    'magaling',
    'mabuti',
    'mabait',
    'mababait',
    'mahusay',
    'galing',
    'salamat',
    'malinis',
    'linis',
    'luminis',
    'maliwanag',
    'mabilis',
    'mabango',
    'maaliwalas',
    'tahimik',
    'tulong',
    'tumulong',
    'nakatulong',
    'gumana',
    'gumagana',
    'bumalik',
    'naibalik',
    'husay',
    'ganda',
    'kalma',
    'masaya',
    'natutuwa',
  ];

  static const double _minNbConfidence = 0.60;

  static SentimentResult analyze(String message, ComplaintCategory category) {
    final nb = NbTfidfClassifier.instance;
    if (nb != null && nb.available) {
      final prediction = nb.predict(message);
      if (prediction.confidence < _minNbConfidence) {
        final lexicon = _lexiconAnalyze(message, category);
        if (lexicon.sentiment != Sentiment.neutral) {
          return lexicon;
        }
      }
      return SentimentResult(
        sentiment: prediction.sentiment,
        recommendation: _recommendation(prediction.sentiment, category),
      );
    }
    return _lexiconAnalyze(message, category);
  }

  static SentimentResult _lexiconAnalyze(
      String message, ComplaintCategory category) {
    final msg = message.toLowerCase();

    var negative = 0;
    var positive = 0;
    var negativePhraseHits = 0;
    var positivePhraseHits = 0;

    for (final phrase in _negativePhrases) {
      if (msg.contains(phrase)) {
        negative++;
        negativePhraseHits++;
      }
    }
    for (final phrase in _positivePhrases) {
      if (msg.contains(phrase)) {
        positive++;
        positivePhraseHits++;
      }
    }

    final tokens = msg
        .split(RegExp(r"[^a-z0-9']+"))
        .where((t) => t.isNotEmpty && !_stopWords.contains(t))
        .toList();

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final negated = i > 0 && _negations.contains(tokens[i - 1]);
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

    final sentiment = _decide(
      negative,
      positive,
      negativePhraseHits,
      positivePhraseHits,
    );

    return SentimentResult(
      sentiment: sentiment,
      recommendation: _recommendation(sentiment, category),
    );
  }

  static Sentiment _decide(
    int negative,
    int positive,
    int negativePhraseHits,
    int positivePhraseHits,
  ) {
    if (negative > positive) return Sentiment.negative;
    if (positive > negative) return Sentiment.positive;
    if (negativePhraseHits > 0) return Sentiment.negative;
    if (positivePhraseHits > 0) return Sentiment.positive;
    return Sentiment.neutral;
  }

  static String _recommendation(Sentiment sentiment, ComplaintCategory category) {
    if (sentiment == Sentiment.negative) {
      switch (category) {
        case ComplaintCategory.waste:
          return 'Schedule a cleanup operation for the reported area';
        case ComplaintCategory.road:
          return 'Dispatch the maintenance crew for immediate repair';
        case ComplaintCategory.water:
          return 'Check for pipe leaks or water contamination';
        case ComplaintCategory.lighting:
          return 'Inspect and repair the street lighting circuit';
        case ComplaintCategory.peaceOrder:
          return 'Deploy tanod patrol to address the disturbance';
        case ComplaintCategory.trafficObstruction:
          return 'Clear the obstruction and issue a violation notice';
        case ComplaintCategory.floodDrainage:
          return 'Inspect and declog the drainage system in the area';
        case ComplaintCategory.healthSanitation:
          return 'Coordinate with health workers for sanitation response';
        case ComplaintCategory.electricalHazard:
          return 'Cordon the area and report to Meralco immediately';
        case ComplaintCategory.publicFacilities:
          return 'Schedule facility repair and post safety notice';
        case ComplaintCategory.generalInquiry:
          return 'Investigate the reported community concern';
      }
    }
    if (sentiment == Sentiment.positive) {
      switch (category) {
        case ComplaintCategory.waste:
          return 'Commend the sanitation team for the effort';
        case ComplaintCategory.road:
          return 'Document the successful maintenance for records';
        case ComplaintCategory.water:
          return 'Acknowledge the stable water service';
        case ComplaintCategory.lighting:
          return 'Acknowledge the restored lighting service';
        case ComplaintCategory.peaceOrder:
          return 'Commend the tanod team for restoring peace';
        case ComplaintCategory.trafficObstruction:
          return 'Acknowledge the successful road clearing operation';
        case ComplaintCategory.floodDrainage:
          return 'Document the drainage improvement for records';
        case ComplaintCategory.healthSanitation:
          return 'Commend the health workers for their response';
        case ComplaintCategory.electricalHazard:
          return 'Acknowledge the swift hazard resolution';
        case ComplaintCategory.publicFacilities:
          return 'Document the facility improvement for records';
        case ComplaintCategory.generalInquiry:
          return 'Thank the citizen for their positive feedback';
      }
    }
    return 'Monitor the situation for any changes';
  }
}
