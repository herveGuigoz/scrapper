extension StringExt on String {
  String allAfter(Pattern pattern) {
    ArgumentError.checkNotNull(pattern, 'pattern');
    final matchIterator = pattern.allMatches(this).iterator;
    if (matchIterator.moveNext()) {
      final match = matchIterator.current;
      final length = match.end - match.start;
      return substring(match.start + length);
    }
    return '';
  }

  String allBefore(Pattern pattern) {
    ArgumentError.checkNotNull(pattern, 'pattern');
    final matchIterator = pattern.allMatches(this).iterator;
    Match match;
    while (matchIterator.moveNext()) {
      match = matchIterator.current;
    }
    if (match != null) {
      return substring(0, match.start);
    }
    return '';
  }

  String allBetween(Pattern startPattern, Pattern endPattern) {
    return allAfter(startPattern).allBefore(endPattern);
  }
}
