import 'package:intl/intl.dart';

/// Mirrors TimeFormatter.kt — formats a millisecond timestamp into a concise
/// relative string for inbox row timestamps.
class TimeFormatter {
  TimeFormatter._();

  static String format(int timestampMs) {
    if (timestampMs == 0) return '';

    final msg = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();

    final sameDay = msg.year == now.year &&
        msg.month == now.month &&
        msg.day == now.day;

    if (sameDay) {
      // e.g. "3:42 PM"
      return DateFormat.jm().format(msg);
    }

    if (msg.year == now.year) {
      // e.g. "Mar 5"
      return DateFormat('MMM d').format(msg);
    }

    // e.g. "Mar 5, 24"
    return DateFormat('MMM d, yy').format(msg);
  }
}
