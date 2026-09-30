/// Heuristic detection of keyboard-mashing / meaningless input.
/// Returns true when [text] looks like gibberish (random characters,
/// letter runs, or repeated blocks) rather than a real description.
bool looksLikeGibberish(String raw) {
  final text = raw.toLowerCase();
  final letters = text.replaceAll(RegExp(r'[^a-zñ]'), '');
  if (text.length >= 10 && letters.isEmpty) return true;
  if (letters.length < 6) return false;

  if (RegExp(r'(.)\1{2}').hasMatch(letters)) return true;

  final repeat = RegExp(r'(.{4,}?)\1+').firstMatch(letters);
  if (repeat != null && repeat.group(0)!.length * 3 >= letters.length * 2) {
    return true;
  }

  if (letters.length >= 10) {
    final vowels = letters.replaceAll(RegExp('[^aeiou]'), '').length;
    if (vowels / letters.length < 0.12) return true;
    final bigrams = <String>[];
    for (var i = 0; i + 1 < letters.length; i++) {
      bigrams.add(letters.substring(i, i + 2));
    }
    if (bigrams.toSet().length / bigrams.length < 0.5) return true;
  }

  return false;
}