import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class DateFormatter {
  // Format date as timeago (e.g., "2 hours ago")
  static String formatTimeAgo(DateTime dateTime) {
    return timeago.format(dateTime);
  }

  // Format date as "MMM dd, yyyy" (e.g., "Jan 01, 2023")
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  // Format date as "MMM dd, yyyy • hh:mm a" (e.g., "Jan 01, 2023 • 12:00 PM")
  static String formatDateWithTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  // Format time as "hh:mm a" (e.g., "12:00 PM")
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  // Format date for chat messages
  static String formatChatMessageTime(DateTime dateTime) {
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(days: 1));

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      // Today: format as "hh:mm a"
      return DateFormat('hh:mm a').format(dateTime);
    } else if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      // Yesterday: format as "Yesterday, hh:mm a"
      return 'Yesterday, ${DateFormat('hh:mm a').format(dateTime)}';
    } else if (dateTime.year == now.year) {
      // This year: format as "MMM dd, hh:mm a"
      return DateFormat('MMM dd, hh:mm a').format(dateTime);
    } else {
      // Different year: format as "MMM dd, yyyy, hh:mm a"
      return DateFormat('MMM dd, yyyy, hh:mm a').format(dateTime);
    }
  }

  // Format date range for events
  static String formatEventDateRange(DateTime startTime, DateTime endTime) {
    bool sameDay = startTime.year == endTime.year &&
        startTime.month == endTime.month &&
        startTime.day == endTime.day;

    if (sameDay) {
      return '${DateFormat('MMM dd, yyyy').format(startTime)} • ${DateFormat('hh:mm a').format(startTime)} - ${DateFormat('hh:mm a').format(endTime)}';
    } else {
      return '${DateFormat('MMM dd, yyyy • hh:mm a').format(startTime)} - ${DateFormat('MMM dd, yyyy • hh:mm a').format(endTime)}';
    }
  }
}