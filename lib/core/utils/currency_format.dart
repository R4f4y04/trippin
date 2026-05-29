/// Formats a [double] amount as Pakistani Rupees with comma separators.
///
/// Examples:
///   formatPKR(1200)    → "₨ 1,200"
///   formatPKR(-500)    → "-₨ 500"
///   formatPKR(0)       → "₨ 0"
///   formatPKR(1200.5)  → "₨ 1,201"  (rounded)
String formatPKR(double amount) {
  final isNegative = amount < 0;
  final absolute = amount.abs().round();
  final formatted = _addCommas(absolute);
  return isNegative ? '-₨ $formatted' : '₨ $formatted';
}

/// Adds comma separators to an integer (e.g. 12450 → "12,450").
String _addCommas(int value) {
  final str = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}

/// Returns a short relative timestamp string.
///
/// Examples:
///   "just now", "2m ago", "1h ago", "3d ago"
String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  final month = _monthName(dateTime.month);
  return '$month ${dateTime.day}';
}

String _monthName(int month) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[month];
}
