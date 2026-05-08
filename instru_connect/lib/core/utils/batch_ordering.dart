class BatchOrdering {
  static const List<String> _orderedLabels = [
    'FY',
    'SY',
    'TY',
    'Fourth Year',
    'Alumni',
  ];

  static int rankForName(String name) {
    final normalized = name.trim().toLowerCase();

    if (normalized.contains('alumni')) return 4;
    if (normalized.contains('fourth') ||
        normalized.contains('4th') ||
        normalized == 'be' ||
        normalized.contains('final year')) {
      return 3;
    }
    if (normalized.startsWith('ty') || normalized.contains('third')) return 2;
    if (normalized.startsWith('sy') || normalized.contains('second')) return 1;
    if (normalized.startsWith('fy') || normalized.contains('first')) return 0;

    return _orderedLabels.length;
  }

  static List<String> sortBatchNames(Iterable<String> names) {
    final sorted = names.toList();
    sorted.sort((a, b) {
      final rankCompare = rankForName(a).compareTo(rankForName(b));
      if (rankCompare != 0) return rankCompare;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return sorted;
  }
}
