enum DatePreset {
  allTime('All time'),
  today('Today'),
  last7Days('Last 7 days'),
  last30Days('Last 30 days');

  const DatePreset(this.label);

  final String label;

  bool matches(DateTime date) {
    final now = DateTime.now();
    switch (this) {
      case DatePreset.allTime:
        return true;
      case DatePreset.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case DatePreset.last7Days:
        return now.difference(date) <= const Duration(days: 7);
      case DatePreset.last30Days:
        return now.difference(date) <= const Duration(days: 30);
    }
  }
}
