import 'package:flutter_test/flutter_test.dart';

import 'package:citisense/utils/text_validators.dart';

void main() {
  group('looksLikeGibberish', () {
    test('real descriptions pass (Tagalog + English)', () {
      const legit = [
        'Sobrang baho ng basura sa may kalsada, ang dami na!',
        'Malaking bato at mga gulong ang humaharang sa kalsada malapit sa palengke',
        'Maraming basura dito sa brgy looc',
        'uncollected garbage on the corner near the market',
        'Kailangan na ng pickup ng basura, ang dami na nga ng basura na naiipon sa amin.',
        'Hindi na po dumadaan ang truck ng basura dito sa lugar namin simula noong nakaraang linggo.',
      ];
      for (final s in legit) {
        expect(looksLikeGibberish(s), isFalse, reason: 'should accept: "$s"');
      }
    });

    test('keyboard mashing and scribbles fail', () {
      const gibberish = [
        'asdfghjklasdfghjkl',
        'qweqweqweqweqweqwe',
        'zxcvbnmzxcvbnm',
        'aaaaaa',
        'hghghghghg',
        'akjdakjdakjdk',
        'jajajajaja',
        'dsd dsd dsd dsd dsd',
        '1234567890123456',
        'sdfsdfsdfsdf',
        'ngngngngngng',
      ];
      for (final s in gibberish) {
        expect(looksLikeGibberish(s), isTrue, reason: 'should reject: "$s"');
      }
    });

    test('real complaints found in Firestore that were gibberish', () {
      const gibberish = [
        'hehehehehehehehehehe',
        'hsjajajahshshshhahahahajajshsbsbsbsbebehe',
        '12345678910@#\$_&-+()/*"\'vbmkakakkakakak12345678910@#\$_&-+()/*"\'vbmkakaka',
      ];
      for (final s in gibberish) {
        expect(looksLikeGibberish(s), isTrue, reason: 'should reject: "$s"');
      }
    });

    test('short or empty input is left to other validators', () {
      expect(looksLikeGibberish(''), isFalse);
      expect(looksLikeGibberish('  '), isFalse);
      expect(looksLikeGibberish('abc'), isFalse);
      expect(looksLikeGibberish('Sira na'), isFalse);
    });
  });
}