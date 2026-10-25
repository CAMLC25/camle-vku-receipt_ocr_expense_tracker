import 'package:intl/intl.dart';

/// Formatting and parsing utilities for Vietnamese Đồng (VND).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _vndFormat = NumberFormat('#,###', 'vi_VN');

  /// Format an integer amount into Vietnamese currency string (e.g. 150.000 ₫)
  static String formatVND(int amount, {bool includeSymbol = true}) {
    final formatted = _vndFormat.format(amount);
    return includeSymbol ? '$formatted ₫' : formatted;
  }

  /// Normalizes and parses raw OCR text or user input into integer VND.
  /// Handles: "150.000 đ", "150,000 VND", "150000", "125.00", "89.500"
  static int? parseVND(String? raw) {
    if (raw == null) return null;
    var cleaned = raw.trim();
    if (cleaned.isEmpty) return null;

    // Remove currency labels
    cleaned = cleaned
        .replaceAll(RegExp(r'[đdD]|vnd|vnđ|\$|EUR', caseSensitive: false), '')
        .trim();

    // Check for dot vs comma patterns
    // Case 1: Standard Vietnamese format: 150.000 or 1.250.000 (dots as thousand separators)
    if (RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(cleaned)) {
      final digits = cleaned.replaceAll('.', '');
      return int.tryParse(digits);
    }

    // Case 2: Comma as thousand separator: 150,000 or 1,250,000
    if (RegExp(r'^\d{1,3}(?:,\d{3})+$').hasMatch(cleaned)) {
      final digits = cleaned.replaceAll(',', '');
      return int.tryParse(digits);
    }

    // Case 3: International format with cents: 125.00 or 1,250.00
    if (RegExp(r'^\d+(?:,\d{3})*\.\d{2}$').hasMatch(cleaned)) {
      final withoutThousands = cleaned.replaceAll(',', '');
      final doubleVal = double.tryParse(withoutThousands);
      return doubleVal?.round();
    }

    // Case 4: Plain integer: 150000
    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      return int.tryParse(cleaned);
    }

    // Fallback: extract all digits if only spaces / dots separated
    final onlyDigits = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(onlyDigits);
  }
}
