import 'package:timeago/timeago.dart' as timeago;

class TimeManager {
  /// Converts a server timestamp string into a relative human-readable string.
  /// Handles nulls and parsing errors gracefully.
  static String formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return "Date unknown";
    }

    try {
      // 1. Parse the ISO 8601 string from Django
      DateTime utcTime = DateTime.parse(timestamp);

      // 2. Convert to the device's local time (Pakistan Time)
      DateTime localTime = utcTime.toLocal();

      // 3. Generate the relative time (e.g., "Just now", "2 hours ago")
      return timeago.format(localTime);
    } catch (e) {
      // If the string is not a valid date, return a fallback
      return "Just now";
    }
  }
}