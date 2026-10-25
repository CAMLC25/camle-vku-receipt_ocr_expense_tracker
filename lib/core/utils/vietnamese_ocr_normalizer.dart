/// Utility class inspired by Vietnamese OCR preprocessing & post-processing pipelines
/// (such as PaddleOCR + VietOCR). Normalizes diacritics, repairs typical OCR character
/// confusions (e.g., 'O' vs '0', 'l' vs '1', 'd' vs 'đ'), and standardizes invoice tokens.
class VietnameseOcrNormalizer {
  VietnameseOcrNormalizer._();

  static const _vietnameseMap = {
    'a': 'áàảãạăắằẳẵặâấầẩẫậ',
    'A': 'ÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬ',
    'd': 'đ',
    'D': 'Đ',
    'e': 'éèẻẽẹêếềểễệ',
    'E': 'ÉÈẺẼẸÊẾỀỂỄỆ',
    'i': 'íìỉĩị',
    'I': 'ÍÌỈĨỊ',
    'o': 'óòỏõọôốồổỗộơớờởỡợ',
    'O': 'ÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢ',
    'u': 'úùủũụưứừửữự',
    'U': 'ÚÙỦŨỤƯỨỪỬỮỰ',
    'y': 'ýỳỷỹỵ',
    'Y': 'ÝỲỶỸỴ',
  };

  /// Strips Vietnamese diacritic marks to produce lowercase ASCII representation.
  /// Example: "TỔNG CỘNG: 89.000 đ" -> "tong cong: 89.000 d"
  static String removeDiacritics(String text) {
    var result = text;
    for (final entry in _vietnameseMap.entries) {
      final ascii = entry.key;
      for (final char in entry.value.split('')) {
        result = result.replaceAll(char, ascii);
      }
    }
    return result;
  }

  /// Normalizes common OCR character recognition mistakes on invoices and receipts:
  /// 1. Repairs capital 'O' or 'o' recognized instead of '0' in amounts (e.g. "1OO.OOO" -> "100.000")
  /// 2. Repairs lowercase 'l' or 'I' recognized instead of '1' in numbers (e.g. "l50.000" -> "150.000")
  /// 3. Normalizes currency marks (e.g. "89.000 d", "89.000D" -> "89.000 đ")
  /// 4. Removes spurious spaces around dots/commas in monetary numbers (e.g. "120 .000" -> "120.000")
  static String normalizeOcrLine(String line) {
    if (line.trim().isEmpty) return line;

    var normalized = line;

    // 1. Repair spaces around dots or commas in numbers: "89 .000" -> "89.000"
    normalized = normalized.replaceAllMapped(
      RegExp(r'([0-9oOlI]+)\s*([.,])\s*([0-9oOlI]{3})'),
      (m) => '${m[1]}${m[2]}${m[3]}',
    );

    // 2. Fix 'O'/'o' mistaken for '0' in numeric amounts (e.g. "1OO.OOO" -> "100.000")
    normalized = normalized.replaceAllMapped(
      RegExp(r'\b([0-9][0-9oO]*)[.,]([0-9oO]{3})\b'),
      (m) {
        final prefix = m[1]!.replaceAll(RegExp(r'[oO]'), '0');
        final suffix = m[2]!.replaceAll(RegExp(r'[oO]'), '0');
        return '$prefix.$suffix';
      },
    );

    // 3. Fix 'l' or 'I' as leading digit before dot: "l50.000" -> "150.000"
    normalized = normalized.replaceAllMapped(
      RegExp(r'\b[lI](\d{2})[.,](\d{3})\b'),
      (m) => '1${m[1]}.${m[2]}',
    );

    // 4. Standardize lowercase/uppercase 'd' or 'D' as currency marker after digits
    // e.g. "89.000 d", "89.000D", "89000d" -> "89.000 đ"
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\d+[\.,]?\d*)\s*[dD]\b'),
      (m) => '${m[1]} đ',
    );

    // 5. Standardize multiple consecutive spaces
    normalized = normalized.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return normalized;
  }

  /// Determines whether a line indicates a final total payment line,
  /// matching both accented and unaccented Vietnamese phrases.
  static bool isFinalTotalLabel(String text) {
    final clean = removeDiacritics(text).toLowerCase();
    return clean.contains('tong cong') ||
        clean.contains('tong tien thanh toan') ||
        clean.contains('tong thanh toan') ||
        clean.contains('thanh tien') ||
        clean.contains('grand total') ||
        RegExp(r'\btotal\b').hasMatch(clean);
  }

  /// Determines whether a line indicates a subtotal, discount, or tax line
  /// which should NOT be confused with the final payable total.
  static bool isSubtotalOrDiscount(String text) {
    final clean = removeDiacritics(text).toLowerCase();
    return clean.contains('tien hang') ||
        clean.contains('tong tien hang') ||
        clean.contains('subtotal') ||
        clean.contains('giam gia') ||
        clean.contains('chiet khau') ||
        clean.contains('discount') ||
        clean.contains('khuyen mai') ||
        clean.contains('thue vat') ||
        clean.contains('vat');
  }

  /// Determines whether a line indicates cash handed by customer or change returned.
  static bool isCashOrChange(String text) {
    final clean = removeDiacritics(text).toLowerCase();
    return clean.contains('tien khach dua') ||
        clean.contains('khach dua') ||
        clean.contains('cash tendered') ||
        clean.contains('tien thoi lai') ||
        clean.contains('tien thoi') ||
        clean.contains('tien tra lai') ||
        clean.contains('tien thua') ||
        clean.contains('change');
  }
}
