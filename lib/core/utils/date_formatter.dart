import 'package:intl/intl.dart';

/// Date formatting and parsing helpers for ISO 8601 and Vietnamese display.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _vnDisplayDateFormat = DateFormat('dd/MM/yyyy');

  /// Convert DateTime to ISO 8601 string: YYYY-MM-DD
  static String toIsoDate(DateTime date) {
    return _isoDateFormat.format(date);
  }

  /// Format ISO date string (YYYY-MM-DD) to Vietnamese display (dd/MM/yyyy)
  static String formatForDisplay(String isoDate) {
    try {
      final parsed = _isoDateFormat.parse(isoDate);
      return _vnDisplayDateFormat.format(parsed);
    } catch (_) {
      return isoDate;
    }
  }

  /// Format ISO date with time to display
  static String formatFullDisplay(String isoDate, String? time) {
    final dateStr = formatForDisplay(isoDate);
    if (time != null && time.isNotEmpty) {
      return '$dateStr $time';
    }
    return dateStr;
  }

  /// Parses date string into ISO date format: YYYY-MM-DD
  /// Supports: dd/MM/yyyy, dd-MM-yyyy, dd.MM.yyyy, yyyy-MM-dd
  static String? normalizeToIsoDate(String rawDate) {
    final cleaned = rawDate.trim();
    if (cleaned.isEmpty) return null;

    final formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd.MM.yyyy',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'd/M/yyyy',
      'd-M-yyyy',
    ];

    for (final pattern in formats) {
      try {
        final parser = DateFormat(pattern);
        final parsed = parser.parseStrict(cleaned);
        // Sanity check year between 2000 and 2100
        if (parsed.year >= 2000 && parsed.year <= 2100) {
          return _isoDateFormat.format(parsed);
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
